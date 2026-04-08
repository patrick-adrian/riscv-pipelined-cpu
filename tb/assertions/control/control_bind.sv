`timescale 1ns / 1ps
//==============================================================//
//  File:         control_bind.sv
//  Description:  Binds control_assertions to the control_unit DUT.
//==============================================================//

bind control_unit control_assertions u_control_assertions (
    .op_de           (op_de_i),
    .funct3_de       (funct3_de_i),
    .funct7_de       (funct7_de_i),
    .imm_src_de      (imm_src_de_o),
    .result_src_de   (result_src_de_o),
    .branch_op_de    (branch_op_de_o),
    .alu_src_de      (alu_src_de_o),
    .pc_base_src_de  (pc_base_src_de_o),
    .reg_write_de    (reg_write_de_o),
    .mem_write_de    (mem_write_de_o),
    .csr_we_de       (csr_we_de_o),
    .alu_control_de  (alu_control_de_o),
    .width_src_de    (width_src_de_o),
    .csr_control_de  (csr_control_de_o),
    .csr_src_de      (csr_src_de_o)
);
