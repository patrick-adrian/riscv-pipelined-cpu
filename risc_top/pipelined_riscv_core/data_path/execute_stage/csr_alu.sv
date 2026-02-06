`timescale 1ns / 1ps
//==============================================================//
//  Module:       csr_alu
//  File:         csr_alu.sv
//  Description:  performs csr related arithmetic operations
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  Parameters:  WIDTH: The width of the operands
//
//  Notes:        Control and status registers hold things like:
//                privilege state, interrupt enables, exception causes,
//                performance counters, status bits.
//                CSRRW, CSRRS, CSRRC and immediate variants
//                do not use normal arithmetic: 
//                bitwise read-modify-write semantics
//                CSRRS: set bits in CSR where rs1 has 1s (csr_data | rs1)
//                CSRRC: clear bits in CSR where rs1 has 1s (csr_data & ~rs1)
//                CSRRW: replace CSR entirely with rs1 (rs1)
//                NEEDS to be separate from ALU because CSR instrs
//                are architecturally different from normal ALU instrs
//==============================================================//
`include "control_macros.sv"

module csr_alu #(
    parameter int WIDTH = 32
) (
    // Control inputs
    input  logic [1:0] csr_control_i,    //encode which CSR instruction is executing

    // Data inputs
    input  logic [WIDTH-1:0] csr_op_a_i, //rs1 or immediate data
    input  logic [WIDTH-1:0] csr_data_i, //csr data

    // Data output
    output logic [WIDTH-1:0] csr_result_o
);

    always_comb begin
        case(csr_control_i)
             `CSR_SET:      csr_result_o = csr_op_a_i | csr_data_i;
             `CSR_CLEAR:    csr_result_o = ~(csr_op_a_i) & csr_data_i;
             `CSR_PASS:     csr_result_o = csr_op_a_i;
             default:       csr_result_o = 0;
        endcase
    end

endmodule