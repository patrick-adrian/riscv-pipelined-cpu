`timescale 1ns / 1ps
//==============================================================//
//  Module:       alu
//  File:         alu.sv
//  Description:  Paramaterized ALU
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  DEPENDENCIES: control_macros.sv
//
//  Parameters:   WIDTH  - data width
//
//==============================================================//
`include "control_macros.sv"

module alu #(
    parameter int WIDTH = 32
) (
    // Control inputs
    input  logic [3:0]         alu_control_i,

    // data inputs
    input  logic [WIDTH-1:0]   A,
    input  logic [WIDTH-1:0]   B,

    // data outputs
    output logic [WIDTH-1:0]   alu_result_o,

    // Status flag outputs
    output logic        neg_flag_o,
    output logic        zero_flag_o,
    output logic        carry_flag_o,
    output logic        v_flag_o
);

    // ----- Intermediate signals -----
    logic carry_out;     // Carry-out from addition/subtraction
    logic v_control;     // Internal overflow computation (used for SLT)

    always_comb begin

        // set default value for carry_out
        carry_out = 1'b0;

        // Operation Logic
        case(alu_control_i)
            // Arithmetic ops
            `ALU_ADD: {carry_out, alu_result_o} = A + B; // 33 bit -> carry_out
            `ALU_SUB: {carry_out, alu_result_o} = A - B; 

            // Logical ops
            `ALU_AND: alu_result_o = A & B;
            `ALU_OR:  alu_result_o = A | B;
            `ALU_XOR: alu_result_o = A ^ B;
            `ALU_SLL: alu_result_o = A << B;
            `ALU_SRL: alu_result_o = A >> B;
            `ALU_SRA: alu_result_o = $signed(A) >>> B;

            `ALU_SLT: begin
                alu_result_o = A - B;
                v_control = ~(alu_control_i[0] ^ A[WIDTH-1] ^ B[WIDTH-1]) & (A[WIDTH-1] ^ alu_result_o[WIDTH-1]);

                //LT comparison for sgined numbers determined by V and N flags (V ^ N)
                if (v_control ^ alu_result_o[WIDTH-1]) alu_result_o = 1'b1;
                else                                   alu_result_o = 1'b0;
            end

            `ALU_SLTU: begin
                if (A < B) alu_result_o = 1;
                else       alu_result_o = 0;
            end

            default: alu_result_o = {(WIDTH + 1){1'bx}}; //Undefined case
        endcase

        //Overflow and Carry Flag logic
        //only require flags for arithmetic operations
        if (alu_control_i[3] == 1'b1) begin

            //Carry flag is inverse of carry_out if Subtracting
            carry_flag_o = alu_control_i[0] ? ~carry_out : carry_out;

            v_flag_o = ~(alu_control_i[0] ^ A[WIDTH-1] ^ B[WIDTH-1]) & (A[WIDTH-1] ^ alu_result_o[WIDTH-1]);

        end else begin
            //Default values of C and V: logical ops do not require these
            carry_flag_o = 1'b0;
            v_flag_o     = 1'b0;
        end

    end

    //Flag Assignment
    assign neg_flag_o  = alu_result_o[WIDTH-1]; //neg flag = MSB of result
    assign zero_flag_o = &(~alu_result_o);      //zero flag = invert result and reduce (and all bits one by one)
                                                //only renders to 1 if result=0000...

endmodule