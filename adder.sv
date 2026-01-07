`timescale 1ns / 1ps
//==============================================================//
//  Module:       adder
//  File:         adder.sv
//  Description:  Generic paramaterized adder
//
//  Author:       Patrick P
//
//  Parameters:   WIDTH  - data width
//
//  Notes:        N/A
//==============================================================//

module adder #(
    parameter int WIDTH = 32
) (
    // data inputs
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,

    // data outputs
    output logic [WIDTH-1:0] y
);

    assign y = a + b;

endmodule