`timescale 1ns / 1ps
//==============================================================//
//  Module:       imm_extend
//  File:         imm_extend.sv
//  Description:  Extension unit used to extend immediates
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  Parameters:   N/A
//
//  Notes:        N/A
//==============================================================//
`include "control_macros.sv"

module imm_extend (
    // Instruction input
    input  logic [31:7] instr_i,        //instr[6:0] is opcode, not needed

    // Control input
    input  logic [2:0]  imm_src_i,      //control sig (short for signal) from decoder

    // data_o output
    output logic [31:0] imm_ext_o       //final shifted/sign-extended value
);

    always_comb begin                   //pure combinational
        case(imm_src_i)
            `I_EXT:     imm_ext_o = {{20{instr_i[31]}}, instr_i[31:20]};                                    //sign bit replicated 20 times, then 12-bit immediate
            `S_EXT:     imm_ext_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            `B_EXT:     imm_ext_o = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
            `J_EXT:     imm_ext_o = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
            `U_EXT:     imm_ext_o = {instr_i[31:12], 12'b0};
            `CSR_EXT:   imm_ext_o = {27'b0, instr_i[19:15]};
            default:    imm_ext_o = 0;
        endcase
    end

endmodule