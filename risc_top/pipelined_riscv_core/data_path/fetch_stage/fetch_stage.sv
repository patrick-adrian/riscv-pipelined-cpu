`timescale 1ns / 1ps
//==============================================================//
//  Module:       fetch_stage
//  File:         fetch_stage.sv
//  Description:  All logic contained within the fetch pipeline stage, along with its pipeline register
//
//  Author:                     Viggo Wozniak
//  Reviewed/annotated by:      Patrick Pineda
//  
//  DEPENDENCIES: flop.sv, adder.sv, control_macros.sv
//
//  Parameters:   Fetches next instruction
//==============================================================//
`include "control_macros.sv"

module fetch_stage (
    // Clock & reset_i
    input  logic        clk_i,
    input  logic        reset_i,

    // Control inputs
    input  logic [1:0]  pc_src_i,               //where next PC comes from
    input  logic        stall_fi_i,             //freeze fetch (hazard/backpressure)

    // pc inputs
    input  logic [31:0] pc_target_ex_i,         // branch/jump target from ex stage
    input  logic [31:0] pc_plus4_ex_i,          // sequential PC (PC + 4) from ex stage
    input  logic [31:0] pred_pc_target_fi_i,    // prediction from branch predictor

    // pc outputs
    output logic [31:0] pc_fi_o,                // output PC
    output logic [31:0] pc_plus4_fi_o           // output PC + 4 (fetch stage output)
);

    // ---- Intermediate signal ----
    logic [31:0] pc_next_fi;

    //pc Register logic
    always_comb begin
        case(pc_src_i)
            `PC_SRC_SEQ_F:    pc_next_fi = pc_plus4_fi_o;       // from the adder
            `PC_SRC_PRED_F:   pc_next_fi = pred_pc_target_fi_i; // from branch predictor
            `PC_SRC_SEQ_E:    pc_next_fi = pc_plus4_ex_i;       // from ex stage
            `PC_SRC_TARGET_E: pc_next_fi = pc_target_ex_i;      // from ex stage
            default:          pc_next_fi = '0;
        endcase
    end

    flop u_pc_reg (
        // Clock & reset_i
        .clk_i                          (clk_i),
        .reset                          (reset_i),
        .en                             (~stall_fi_i),

        // data_i input
        .D                              (pc_next_fi),

        // data_i output
        .Q                              (pc_fi_o)
    );

    adder u_adder_pc_plus4 (
        // data_i inputs
        .a                              (pc_fi_o),
        .b                              (4),

        // data_i output
        .y                              (pc_plus4_fi_o)
    );

endmodule