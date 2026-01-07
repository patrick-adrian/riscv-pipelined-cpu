`timescale 1ns / 1ps
`include "control_macros.sv"  // Make sure your ALU macros are defined here

module alu_tb;

    // ---------------------------
    // Parameters
    // ---------------------------
    parameter WIDTH = 32;

    // ---------------------------
    // Testbench signals
    // ---------------------------
    logic [3:0]         alu_control_i;
    logic [WIDTH-1:0]   A;
    logic [WIDTH-1:0]   B;
    logic [WIDTH-1:0]   alu_result_o;
    logic               neg_flag_o;
    logic               zero_flag_o;
    logic               carry_flag_o;
    logic               v_flag_o;

    // ---------------------------
    // Instantiate the ALU
    // ---------------------------
    alu #(.WIDTH(WIDTH)) DUT (
        .alu_control_i(alu_control_i),
        .A(A),
        .B(B),
        .alu_result_o(alu_result_o),
        .neg_flag_o(neg_flag_o),
        .zero_flag_o(zero_flag_o),
        .carry_flag_o(carry_flag_o),
        .v_flag_o(v_flag_o)
    );

    // ---------------------------
    // Simple Test Procedure
    // ---------------------------
    initial begin
        // Header
        $display("Time | A         B         OP   RESULT      N Z C V");

        // ---------------------------
        // Test ADD
        // ---------------------------
        A = 32'h0000_0005;
        B = 32'h0000_0003;
        alu_control_i = `ALU_ADD;
        #5; // wait for combinational logic
        $display("%0t | %h %h ADD  %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // ---------------------------
        // Test SUB (no borrow)
        // ---------------------------
        A = 32'h0000_000A;
        B = 32'h0000_0003;
        alu_control_i = `ALU_SUB;
        #5;
        $display("%0t | %h %h SUB  %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // ---------------------------
        // Test SUB (borrow)
        // ---------------------------
        A = 32'h0000_0003;
        B = 32'h0000_000A;
        alu_control_i = `ALU_SUB;
        #5;
        $display("%0t | %h %h SUB  %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // ---------------------------
        // Test AND
        // ---------------------------
        A = 32'hF0F0_F0F0;
        B = 32'h0F0F_0F0F;
        alu_control_i = `ALU_AND;
        #5;
        $display("%0t | %h %h AND  %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // ---------------------------
        // Test OR
        // ---------------------------
        A = 32'hF0F0_F0F0;
        B = 32'h0F0F_0F0F;
        alu_control_i = `ALU_OR;
        #5;
        $display("%0t | %h %h OR   %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // ---------------------------
        // Test XOR
        // ---------------------------
        A = 32'hAAAA_AAAA;
        B = 32'h5555_5555;
        alu_control_i = `ALU_XOR;
        #5;
        $display("%0t | %h %h XOR  %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // ---------------------------
        // Test SLT (signed)
        // ---------------------------
        A = 32'hFFFF_FFFF; // -1 signed
        B = 32'h0000_0001; // 1 signed
        alu_control_i = `ALU_SLT;
        #5;
        $display("%0t | %h %h SLT  %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // ---------------------------
        // Test SLTU (unsigned)
        // ---------------------------
        A = 32'hFFFF_FFFF; // 4294967295
        B = 32'h0000_0001; // 1
        alu_control_i = `ALU_SLTU;
        #5;
        $display("%0t | %h %h SLTU %h %b %b %b %b", 
                 $time, A, B, alu_result_o, neg_flag_o, zero_flag_o, carry_flag_o, v_flag_o);

        // Finish simulation
        $finish;
    end

endmodule
