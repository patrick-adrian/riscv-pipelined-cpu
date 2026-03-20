`timescale 1ns / 1ps
//==============================================================//
//  Module:       fetch_assertions
//  File:         fetch_assertions.sv
//  Description:  Reusable SystemVerilog assertions for the fetch stage.
//                Binds to fetch_stage via fetch_bind.sv.
//                Define XSIM_SVA_OFF when using Vivado/xsim (limited SVA
//                support); procedural equivalents are used in that case.
//==============================================================//

`include "control_macros.sv"

module fetch_assertions (
    input logic        clk,
    input logic        reset,
    input logic        stall,
    input logic [31:0] pc,
    input logic [1:0]  pc_src
);

`ifndef XSIM_SVA_OFF
    // -------------------------------------------------------------------------
    // A) PC must always be word aligned: pc[1:0] == 2'b00
    // -------------------------------------------------------------------------
    property p_pc_word_aligned;
        @(posedge clk)
        (pc[1:0] == 2'b00);
    endproperty
    assert property (p_pc_word_aligned)
        else $error("[fetch_assertions] PC must be word aligned; pc[1:0]=%b, expected 2'b00", pc[1:0]);

    // -------------------------------------------------------------------------
    // B) When stall was asserted in the previous cycle, the PC must not change
    // -------------------------------------------------------------------------
    property p_pc_stable_while_stalled;
        @(posedge clk)
        disable iff (reset)
        ($past(stall, 1, @(posedge clk)) |-> (pc == $past(pc, 1, @(posedge clk))));
    endproperty
    assert property (p_pc_stable_while_stalled)
        else $error("[fetch_assertions] PC must not change while stall is asserted (from previous cycle); pc=%0h", pc);

    // -------------------------------------------------------------------------
    // C) When the previous cycle was sequential fetch (pc_src == PC_SRC_SEQ_F)
    //    and not stalled, the PC must increment by 4 relative to the previous
    //    cycle. This explicitly ignores branch/jump/redirect cycles.
    // -------------------------------------------------------------------------
    property p_pc_increments_by_4_when_not_stalled;
        @(posedge clk)
        disable iff (reset)
        ($past(pc_src, 1, @(posedge clk)) == `PC_SRC_SEQ_F &&
         !$past(stall, 1, @(posedge clk))
         |-> (pc == $past(pc, 1, @(posedge clk)) + 32'd4));
    endproperty
    assert property (p_pc_increments_by_4_when_not_stalled)
        else $error("[fetch_assertions] PC must increment by 4 on sequential, non-stalled fetch; pc=%0h", pc);

    // -------------------------------------------------------------------------
    // D) During reset, the PC should be 0
    // -------------------------------------------------------------------------
    property p_pc_zero_during_reset;
        @(posedge clk)
        // Note: `pc` is driven by a synchronous reset flop, so sampling on the
        // same edge can observe the pre-update value. Require `pc` to be 0
        // one cycle after reset is asserted.
        ($past(reset, 1) |-> (pc == 32'b0));
    endproperty
    assert property (p_pc_zero_during_reset)
        else $error("[fetch_assertions] PC must be 0 one cycle after reset; reset=%b, pc=%0h", reset, pc);

`else
    // Procedural equivalents for simulators with limited SVA support (e.g. xsim)
    logic [31:0] pc_prev;
    logic [1:0]  pc_src_prev;
    logic        stall_prev;
    logic        reset_prev;

    always_ff @(posedge clk) begin
        pc_prev     <= pc;
        pc_src_prev <= pc_src;
        stall_prev  <= stall;
        reset_prev  <= reset;
    end

    always_ff @(posedge clk) begin
        // A) PC must always be word aligned
        if (pc[1:0] != 2'b00)
            $error("[fetch_assertions] PC must be word aligned; pc[1:0]=%b, expected 2'b00", pc[1:0]);

        // B) When stall was asserted in the previous cycle, the PC must not change
        if (!reset && stall_prev && (pc != pc_prev))
            $error("[fetch_assertions] PC must not change while stall is asserted (from previous cycle); pc=%0h", pc);

        // C) When previous cycle was sequential fetch and not stalled, PC must increment by 4
        if (!reset && !stall_prev && pc_src_prev == `PC_SRC_SEQ_F && (pc != pc_prev + 32'd4))
            $error("[fetch_assertions] PC must increment by 4 on sequential, non-stalled fetch; pc=%0h", pc);

        // D) During reset, the PC should be 0
        if (reset_prev && (pc != 32'b0))
            $error("[fetch_assertions] PC must be 0 one cycle after reset; reset=%b, pc=%0h", reset, pc);
    end
`endif

endmodule
