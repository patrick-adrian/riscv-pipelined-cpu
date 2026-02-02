`timescale 1ns / 1ps
//==============================================================//
//  Module:       memory_stage
//  File:         memory_stage.sv
//  Description:  All logic contained within the memory pipeline stage and it's pipeline register
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//
//  Parameters:   N/A
//
//  Notes:        Memory stage latches EX results, performs memory data width handling,
//                generates forwarding data, and safely transports all control/data needed for WB updates
//==============================================================//
`include "control_macros.sv"

module memory_stage (
    // Clock & reset_i
    input  logic        clk_i,
    input  logic        reset_i,

    // data inputs
    input  logic [31:0] instr_ex_i,         //instruction from EX
    input  logic [31:0] alu_result_ex_i,    //address for loads/stores or ALU result
    input  logic [31:0] write_data_ex_i,    //data to write to memory for stores
    input  logic [31:0] pc_target_ex_i,     //branch/jump target computer in EX stage
    input  logic [31:0] pc_plus4_ex_i,      //PC+4 for JAL, JALR, or writeback
    input  logic [31:0] imm_ext_ex_i,       //extended immediate value (used as writeback source if selected)
    input  logic [31:0] read_data_mem_i,    //raw data from data memory, passed through reduce module
    input  logic [31:0] csr_result_ex_i,    //ALU computed CSR operation result
    input  logic [31:0] csr_data_ex_i,      //Data written to or read from CSR
    input  logic [11:0] csr_addr_ex_i,      //CSR reg address
    input  logic [4:0]  rd_ex_i,            //rd for writeback

    // Control inputs
    input  logic        valid_ex_i,         //indicates real instruction
    input  logic [2:0]  width_src_ex_i,     //load width selector  
    input  logic [2:0]  result_src_ex_i,    //selects what value is forwarded/written back
    input  logic        mem_write_ex_i,     //enables mem write (stores)
    input  logic        reg_write_ex_i,     //enables reg file writeback
    input  logic        csr_we_ex_i,        //enables CSR write
    input  logic        stall_mem_i,        //freeze mem stage pipeline register

    // data outputs
    output logic [31:0] instr_mem_o,        //instr now in mem stage
    output logic [31:0] reduced_data_mem_o, 
    output logic [31:0] alu_result_mem_o,
    output logic [31:0] write_data_mem_o,
    output logic [31:0] pc_target_mem_o,
    output logic [31:0] pc_plus4_mem_o,
    output logic [31:0] imm_ext_mem_o,
    output logic [31:0] forward_data_mem_o,
    output logic [31:0] csr_result_mem_o,
    output logic [31:0] csr_data_mem_o,
    output logic [11:0] csr_addr_mem_o,
    output logic [4:0]  rd_mem_o,

    // Control outputs
    output logic        valid_mem_o,        //indicates valid instruction
    output logic [2:0]  result_src_mem_o,
    output logic [2:0]  width_src_mem_o,
    output logic        mem_write_mem_o,
    output logic        reg_write_mem_o,
    output logic        csr_we_mem_o
);

    // ----- Pipeline data types -----
    typedef struct packed {
        logic [31:0] instr;
        logic        valid;
    } mem_meta_t;

    typedef struct packed {
        logic [2:0]  result_src;
        logic [2:0]  width_src;
        logic        mem_write;
        logic        reg_write;
        logic        csr_we;
    } mem_control_t;

    typedef struct packed {
        logic [4:0]  rd;
        logic [31:0] alu_result;
        logic [31:0] write_data;
        logic [31:0] pc_target;
        logic [31:0] pc_plus4;
        logic [31:0] imm_ext;
        logic [31:0] csr_result;
        logic [11:0] csr_addr;
        logic [31:0] csr_data;
    } mem_data_t;

    typedef struct packed {
        mem_meta_t    meta;
        mem_control_t control;
        mem_data_t    data;
    } mem_bundle_t;

    // ----- Parameters -----
    localparam REG_WIDTH = $bits(mem_bundle_t);

    // ----- Memory pipeline register -----
    mem_bundle_t inputs_mem;
    mem_bundle_t outputs_mem;

    assign inputs_mem = {
        // Meta Signals
        instr_ex_i,
        valid_ex_i,

        // Control Signals
        result_src_ex_i,
        width_src_ex_i,
        mem_write_ex_i,
        reg_write_ex_i,
        csr_we_ex_i,

        // Data Signals
        rd_ex_i,
        alu_result_ex_i,
        write_data_ex_i,
        pc_target_ex_i,
        pc_plus4_ex_i,
        imm_ext_ex_i,
        csr_result_ex_i,
        csr_addr_ex_i,
        csr_data_ex_i
    };

    flop #(
        .WIDTH                          (REG_WIDTH)
    ) u_flop_memory_reg (
        // Clock & reset_i
        .clk_i                          (clk_i),
        .reset                          (reset_i),
        .en                             (~stall_mem_i),

        // data input
        .D                              (inputs_mem),

        // data output
        .Q                              (outputs_mem)
    );

    assign {
        // Meta Signals
        instr_mem_o,
        valid_mem_o,

        // Control Signals
        result_src_mem_o,
        width_src_mem_o,
        mem_write_mem_o,
        reg_write_mem_o,
        csr_we_mem_o,

        // Data Signals
        rd_mem_o,
        alu_result_mem_o,
        write_data_mem_o,
        pc_target_mem_o,
        pc_plus4_mem_o,
        imm_ext_mem_o,
        csr_result_mem_o,
        csr_addr_mem_o,
        csr_data_mem_o
    } = outputs_mem;

    // Forwarding mux
    always_comb begin
        case (result_src_mem_o)
            `RESULT_ALU:      forward_data_mem_o = alu_result_mem_o;
            `RESULT_PCTARGET: forward_data_mem_o = pc_target_mem_o;
            `RESULT_PCPLUS4:  forward_data_mem_o = pc_plus4_mem_o;
            `RESULT_IMM_EXT:  forward_data_mem_o = imm_ext_mem_o;
            `RESULT_CSR:      forward_data_mem_o = csr_data_mem_o;
            default:          forward_data_mem_o = '0;
        endcase
    end

    reduce u_reduce_width_change (
        // data input
        .BaseResult                     (read_data_mem_i),

        // Control input
        .width_src_i                    (width_src_mem_o),

        // data output
        .result_o                       (reduced_data_mem_o)
    );

endmodule