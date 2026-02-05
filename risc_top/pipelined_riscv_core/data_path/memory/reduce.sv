`timescale 1ns / 1ps
//==============================================================//
//  Module:       reduce
//  File:         reduce.sv
//  Description:  Reduction unit to reduce the effective width of data retrieved from memory.
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  Parameters:   N/A
//
//  Notes:        Load data post-processing unit.
//                Deals with instructions such as:
//                LB (load byte), LH (load half-word), LW (load word)
//                This module extracts relevant portion, applies sign-extension or zero-extensions, 
//                And properly produces 32-bit value.
//==============================================================//
`include "control_macros.sv"

module reduce (
    // data inputs
    input  logic [31:0] BaseResult,     //raw data from memory

    // Control inputs
    input  logic [2:0]  width_src_i,    // control signal of how wide, signed or unsigned

    // data outputs
    output logic [31:0] result_o
);

    always_comb begin
        case(width_src_i)
            `WIDTH_32:  result_o = BaseResult;                                  //LW
            `WIDTH_16S: result_o = {{16{BaseResult[15]}}, BaseResult[15:0]};    //LH
            `WIDTH_16U: result_o = {16'b0, BaseResult[15:0]};                   //LHU
            `WIDTH_8S:  result_o = {{24{BaseResult[7]}}, BaseResult[7:0]};      //LB
            `WIDTH_8U:  result_o = {24'b0, BaseResult[7:0]};                    //LBU
            default:    result_o = 32'bx;
        endcase
    end
endmodule