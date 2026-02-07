`timescale 1ns / 1ps
//==============================================================//
//  Module:       write_decoder
//  File:         write_decoder.sv
//  Description:  Generates a one-hot encoded signal based on a given address.
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  Parameters:   N/A
//
//  Notes:        5 to 32 write enable decoder
//==============================================================//


module write_decoder (
    // Address & control inputs
    input  logic [4:0]  A,      //5-bit address
    input  logic        WE,     //global write enable

    // enable outputs
    output logic [31:0] en      //32-bit one-hot enable vector
);
    
    assign en = WE ? 1'b1 << A : 0;
    //Case 1: WE==0
    //no write allowed, en = 000...
    //Case 2: WE==1
    //en = 000001..... for example

endmodule