`timescale 1ns / 1ps
//==============================================================//
//  File:         decode_slice_bind.sv
//  Description:  Binds decode_slice_assertions onto decode_stage.
//==============================================================//

bind decode_stage decode_slice_assertions u_decode_slice_assertions (
    .clk    (clk_i),
    .reset  (reset_i),
    .valid  (valid_de_o),
    .instr  (instr_de_o),
    .imm_src(imm_src_de_i),
    .opcode (op_de_o),
    .rd     (rd_de_o),
    .funct3 (funct3_de_o),
    .rs1    (rs1_de_o),
    .rs2    (rs2_de_o),
    .funct7 (funct7_de_o),
    .imm    (imm_ext_de_o)
);
