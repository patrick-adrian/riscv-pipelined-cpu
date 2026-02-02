`timescale 1ns / 1ps
//==============================================================//
//  Module:       writeback_stage
//  File:         writeback_stage.sv
//  Description:  All logic contained within the memory pipeline stage and it's pipeline register
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  Parameters:   N/A
//
//  Notes:        WB module does not compute anything new, resolve hazards, or touch memory
//                It simply latches MEM-stage results, selects final WB value, and signals instruction retirement
//                If this stage breaks, CPU still runs but silently corrupts state
//==============================================================//
`include "control_macros.sv"

module writeback_stage (
    // Clock & reset_i
    input  logic        clk_i,
    input  logic        reset_i,

    // data inputs
    input  logic [31:0] instr_mem_i,        //from MEM stage, passed to WB for debug, tracing, waveform inspection
    input  logic [31:0] alu_result_mem_i,   //ALU computation from EX/MEM, used when result_src == RESULT_ALU
    input  logic [31:0] reduced_data_mem_i, //load data after memory access and size/sign reduction, used for load instructions (RESULT_MEM_DATA)
    input  logic [31:0] pc_target_mem_i,    //target PC value (jump or branch), used when result_src == RESULT_PCTARGET
    input  logic [31:0] pc_plus4_mem_i,     //PC + 4, used for JAL (RESULT_PCPLUS4)
    input  logic [31:0] imm_ext_mem_i,      //sign/zero-extended immediate value, used for imm-based writebacks (RESULT_IMM_EXT)
    input  logic [31:0] csr_result_mem_i,   //result of CSR ALU operation (read/modify/write), passed through for updates
    input  logic [31:0] csr_data_mem_i,     //CSR read data or final CSR value, used as wB value when RESULT_CSR
    input  logic [11:0] csr_addr_mem_i,     //CSR addr for CSR write ops, forwarded to WB unchanged
    input  logic [4:0]  rd_mem_i,           //dest reg index, used to write result into reg file during WB

    // Control inputs
    input  logic        valid_mem_i,        //indicates valid instruction, to mark WB validity and control instruction retirement
    input  logic [2:0]  result_src_mem_i,   //select which data source becomes final WB value (RESULT_ALU, RESULT_PCTARGET, RESULT_PCPLUS4, RESULT_IMM_EXT, RESULT_MEM_DATA, RESULT_CSR)
    input  logic        reg_write_mem_i,    //enables reg file write in WB, passed to output after being latched
    input  logic        csr_we_mem_i,       //enables CSR write in WB, passed after latch   
    input  logic        stall_wb_i,         //freezes WB register, used for structural hazards/backpressure

    // data outputs
    output logic [31:0] instr_wb_o,         //mainly for debug, tracing, retirement bookkeeping
    output logic [31:0] result_wb_o,        //final WB value selected by result mux, written to reg file when reg_write_wb_o
    output logic [31:0] csr_result_wb_o,    //CSR ALU result
    output logic [11:0] csr_addr_wb_o,      //CSR addr for write ops
    output logic [4:0]  rd_wb_o,            //dest reg index

    // Control outputs
    output logic        valid_wb_o,         //indicates WB stage holds valid instr, directly derived from valid_mem_i
    output logic        retire_wb_o,        //indicates an instruction commits/retires cycle, asserted when valid_wb_o and !stall_wb_i
    output logic        reg_write_wb_o,     //enables reg file write, used alongside rd_wb_o and result_wb_o
    output logic        csr_we_wb_o         //enables CSR write, used with csr_addr_wb_o and csr_result_wb_o
);
    // ----- Pipeline data type -----
    typedef struct packed {
        logic [31:0] instr;
        logic        valid;
    } wb_meta_t;

    typedef struct packed {
        logic [2:0]  result_src;
        logic        reg_write;
        logic        csr_we;
    } wb_control_t;

    typedef struct packed {
        logic [4:0]  rd;
        logic [31:0] alu_result;
        logic [31:0] reduced_data;
        logic [31:0] pc_target;
        logic [31:0] pc_plus4;
        logic [31:0] imm_ext;
        logic [31:0] csr_result;
        logic [11:0] csr_addr;
        logic [31:0] csr_data;
    } wb_data_t;

    typedef struct packed {
        wb_meta_t    meta;
        wb_control_t control;
        wb_data_t    data;
    } wb_bundle_t;

    // ----- Parameters -----
    localparam REG_WIDTH = $bits(wb_bundle_t);

    // ----- Writeback pipeline register -----
    wb_bundle_t inputs_wb;
    wb_bundle_t outputs_wb;

    // ----- Writeback stage outputs -----
    logic [31:0] imm_ext_wb;
    logic [31:0] pc_plus4_wb;
    logic [31:0] pc_target_wb;
    logic [31:0] reduced_data_wb;
    logic [31:0] alu_result_wb;
    logic [31:0] csr_data_wb;
    logic [2:0]  result_src_wb;

    assign inputs_wb = {
        // Meta Signals
        instr_mem_i,
        valid_mem_i,

        // Control Signals
        result_src_mem_i,
        reg_write_mem_i,
        csr_we_mem_i,

        // Data Signals
        rd_mem_i,
        alu_result_mem_i,
        reduced_data_mem_i,
        pc_target_mem_i,
        pc_plus4_mem_i,
        imm_ext_mem_i,
        csr_result_mem_i,
        csr_addr_mem_i,
        csr_data_mem_i
    };

    flop #(
        .WIDTH                          (REG_WIDTH)
    ) u_flop_writeback_reg (
        // Clock & reset_i
        .clk_i                          (clk_i),
        .reset                          (reset_i),
        .en                             (~stall_wb_i),

        // data input
        .D                              (inputs_wb),

        // data output
        .Q                              (outputs_wb)
    );

    assign {
        // Meta Signals
        instr_wb_o,
        valid_wb_o,

        // Control Signals
        result_src_wb,
        reg_write_wb_o,
        csr_we_wb_o,

        // Data Signals
        rd_wb_o,
        alu_result_wb,
        reduced_data_wb,
        pc_target_wb,
        pc_plus4_wb,
        imm_ext_wb,
        csr_result_wb_o,
        csr_addr_wb_o,
        csr_data_wb
    } = outputs_wb;

    // result mux
    always_comb begin
        case (result_src_wb)
            `RESULT_ALU:      result_wb_o = alu_result_wb;
            `RESULT_PCTARGET: result_wb_o = pc_target_wb;
            `RESULT_PCPLUS4:  result_wb_o = pc_plus4_wb;
            `RESULT_IMM_EXT:  result_wb_o = imm_ext_wb;
            `RESULT_MEM_DATA: result_wb_o = reduced_data_wb;
            `RESULT_CSR:      result_wb_o = csr_data_wb;
            default:          result_wb_o = '0;
        endcase
    end

    assign retire_wb_o = valid_wb_o & ~stall_wb_i;

endmodule