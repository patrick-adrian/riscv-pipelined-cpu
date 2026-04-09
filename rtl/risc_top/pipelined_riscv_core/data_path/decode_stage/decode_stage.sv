`timescale 1ns / 1ps
//==============================================================//
//  Module:       decode_stage
//  File:         decode_stage.sv
//  Description:  All logic contained within the decode stage, along with its pipeline register
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  DEPENDENCIES: imm_extend.sv, flop.sv
//
//  Parameters:   N/A
//
//  Notes:        Generates signals required for execute stage
//==============================================================//

module decode_stage (
    // Clock & reset_i
    input  logic        clk_i,
    input  logic        reset_i,

    // Data inputs
    input  logic [31:0] instr_fi_i,             // fetched instruction from memory
    input  logic [31:0] pc_fi_i,                // program counter for this instruction, for branch/jump calculations and for storing in the pipeline register
    input  logic [31:0] pc_plus4_fi_i,          // pc + 4, for computing address for next stage
    input  logic [31:0] pred_pc_target_fi_i,    // branch target from branch predictor
    input  logic        pc_src_pred_fi_i,       // control signal: whether branch is taken

    // Control inputs
    input  logic [2:0]  imm_src_de_i,           // how immediate value should be extracted
    input  logic        stall_de_i,             // when 1, decode stagee holds outputs
    input  logic        flush_de_i,             // when 1, sets outputs to 0 or invalid

    // Data outputs
    output logic [31:0] instr_de_o,             // instruction forwarded from fetch
    output logic [31:0] imm_ext_de_o,           // immediate value extracted and extended by imm_extend
    output logic [31:0] pc_de_o,                // PC of instruction (from pc_fi_i)
    output logic [31:0] pc_plus4_de_o,          // PC + 4 for branch/jump calcs (short for calculations)
    output logic [31:0] pred_pc_target_de_o,    // predicted branch target forwarded downstream
    output logic [11:0] csr_addr_de_o,          // address for control/status register ops, extracted from instr bits
    output logic [4:0]  rd_de_o,                // dest register rd extracted from instr bits
    output logic [4:0]  rs1_de_o,               // rs1
    output logic [4:0]  rs2_de_o,               // rs2
    output logic [6:0]  op_de_o,                // opcode of instr
    output logic [2:0]  funct3_de_o,            // funct3 field (selects ALU op or branch type)
    output logic [6:0]  funct7_de_o,            // funct7 field (selects alu variant or instr sub-type)
    output logic        pc_src_pred_de_o,       // predicted branch-taken signal forwarded downstream

    // Control outputs
    output logic        valid_de_o              // when 1, decode stage contains valid instr
);

    // ----- Pipeline data types -----
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic        valid;
    } de_meta_t;

    typedef struct packed {
        logic        pc_src_pred;
    } de_control_t;

    typedef struct packed {
        logic [31:0] pc_plus4;
        logic [31:0] pred_pc_target;
    } de_data_t;

    typedef struct packed {
        de_meta_t    meta;
        de_control_t control;
        de_data_t    data;
    } de_bundle_t;


    // ----- Parameters -----
    localparam REG_WIDTH = $bits(de_bundle_t);

    // ----- Decode pipeline register -----
    de_bundle_t  inputs_de;
    de_bundle_t  outputs_de;

    assign inputs_de = {
        // Meta Signals
        pc_fi_i,
        instr_fi_i,
        1'b1,

        // Control Signals
        pc_src_pred_fi_i,

        // Data Signals
        pc_plus4_fi_i,
        pred_pc_target_fi_i
    };

    flop #(
        .WIDTH                          (REG_WIDTH)
    ) u_flop_decode_reg (
        // Clock & reset_i
        .clk_i                          (clk_i),
        .reset                          (reset_i | flush_de_i),
        .en                             (~stall_de_i),

        // data input
        .D                              (inputs_de),

        // data output
        .Q                              (outputs_de)
    );

    assign {
        // Meta Signals
        pc_de_o,
        instr_de_o,
        valid_de_o,

        // Control Signals
        pc_src_pred_de_o,

        // Data Signals
        pc_plus4_de_o,
        pred_pc_target_de_o
    } = outputs_de;

    // decode instruction fields
    assign rd_de_o = instr_de_o[11:7];
    assign rs1_de_o = instr_de_o[19:15];
    assign rs2_de_o = instr_de_o[24:20];
    assign csr_addr_de_o = instr_de_o[31:20];

    assign op_de_o = instr_de_o[6:0];
    assign funct3_de_o = instr_de_o[14:12];
    assign funct7_de_o[5] = instr_de_o[30];

    imm_extend u_imm_extend (
        // Instruction input
        .instr_i                        (instr_de_o[31:7]),

        // Control input
        .imm_src_i                      (imm_src_de_i),

        // data output
        .imm_ext_o                      (imm_ext_de_o)
    );

endmodule