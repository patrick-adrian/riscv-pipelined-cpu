`timescale 1ns / 1ps
//==============================================================//
//  Module:       reg_file
//  File:         reg_file.sv
//  Description:  Register file containing 32 registers
//                Capable of reading from two registers, and writing to one register in one cycle
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//
//  Parameters:   WIDTH  - data width
//
//  Notes:        32x32-bit reg file with 2 read ports, 1 write port, 
//                same-cycle write-forwarding, hard-wired 0x = 0
//                rs1 and rs2 read combinationally
//                rd written on clock edge
//==============================================================//

module reg_file #(
    parameter int WIDTH = 32
) (
    // Clock & reset_i
    input  logic             clk_i,
    input  logic             reset_i,

    // Register addresses
    input  logic [4:0]       a1_i,            //read address 1 (rs1)
    input  logic [4:0]       a2_i,            //read address 2 (rs2)
    input  logic [4:0]       a3_i,            //write address (rd)

    // Write port
    input  logic [WIDTH-1:0] wd3_i,           //write data
    input  logic             we3_i,           //write enable

    // Read ports
    output logic [WIDTH-1:0] reg_data_1_o,    //read data for a1_i
    output logic [WIDTH-1:0] reg_data_2_o     //read data for a2_i
);

    // ----- Register file storage -----
    logic [WIDTH-1:0] RegisterArray [31:0];   //32 individual 32-bit flip-flop banks

    // ----- Write enables -----
    logic [31:0] en;


    //zero reg ALWAYS stays zero
    flop u_zero_reg (                   
        // Clock & reset_i
        .clk_i                          (clk_i),
        .en                             (1'b0),     //never writeable
        .reset                          (reset_i),

        // data_i input
        .D                              (32'b0),    //always zero

        // data_i output
        .Q                              (RegisterArray[0])
    );

    genvar i;
    generate
        for (i = 1; i < 32; i = i+1) begin
            flop u_reg (
            // Clock & reset_i
            .clk_i                          (clk_i),
            .en                             (en[i]),     //only one register enabled at a time
            .reset                          (reset_i),

            // data_i input
            .D                              (wd3_i),

            // data_i output
            .Q                              (RegisterArray[i])  
            );
        end
    endgenerate
    //one flop per register
    //all registers have same wd3_i
    //broadcast data, one-hot enable

    //READ LOGIC
    //if reading a register, and writing to same register in same cycle, and its not x0,
    //forward wd3_i directly
    //guarantees no read-after-write hazard in same cycle
    always @(*) begin
        if (a1_i == a3_i & we3_i & a1_i != 0) reg_data_1_o = wd3_i;
        else reg_data_1_o = RegisterArray[a1_i];

        if (a2_i == a3_i & we3_i & a2_i != 0) reg_data_2_o = wd3_i;
        else reg_data_2_o = RegisterArray[a2_i];
    end

    write_decoder u_write_decoder (
        // Register address input
        .A                              (a3_i),

        // Control input
        .WE                             (we3_i),

        // Decoder output
        .en                             (en)
    );
    //If we3_i = 0, then en = 32'b0
    //If we3_i = 1, one bit in en goes high
    //ensures only one reg write per cycle, no accidental multi-writes, x0 still safe

endmodule