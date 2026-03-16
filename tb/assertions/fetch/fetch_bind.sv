`timescale 1ns / 1ps
//==============================================================//
//  File:         fetch_bind.sv
//  Description:  Binds fetch_assertions to the fetch_stage DUT.
//                Include this file in the testbench compile.
//==============================================================//

bind fetch_stage fetch_assertions u_fetch_assertions (
    .clk    (clk_i),
    .reset  (reset_i),
    .stall  (stall_fi_i),
    .pc     (pc_fi_o),
    .pc_src (pc_src_i)
);
