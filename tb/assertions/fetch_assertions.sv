`timescale 1ns / 1ps
//==============================================================//
//  Module:       fetch_assertions
//  File:         fetch_assertions.sv
//  Description:  Reusable SystemVerilog assertions for the fetch stage.
//                Binds to fetch_stage via fetch_bind.sv.
//                Define XSIM_SVA_OFF when using Vivado/xsim (limited SVA
//                support); procedural equivalents are used in that case.
//==============================================================//

module fetch_assertions (
    input logic        clk,
    input logic        reset,
    input logic        stall,
    input logic [31:0] pc
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
    // B) When stall is asserted, the PC must not change
    // -------------------------------------------------------------------------
    property p_pc_stable_while_stalled;
        @(posedge clk)
        disable iff (reset)
        (stall |-> (pc == $past(pc, 1, @(posedge clk))));
    endproperty
    assert property (p_pc_stable_while_stalled)
        else $error("[fetch_assertions] PC must not change while stall is asserted; pc=%0h", pc);

    // -------------------------------------------------------------------------
    // C) When stall is not asserted, the PC must increment by 4 relative to
    //    the previous cycle
    // -------------------------------------------------------------------------
    property p_pc_increments_by_4_when_not_stalled;
        @(posedge clk)
        disable iff (reset)
        (!stall |-> (pc == $past(pc, 1, @(posedge clk)) + 32'd4));
    endproperty
    assert property (p_pc_increments_by_4_when_not_stalled)
        else $error("[fetch_assertions] PC must increment by 4 when not stalled; pc=%0h", pc);

    // -------------------------------------------------------------------------
    // D) During reset, the PC should be 0
    // -------------------------------------------------------------------------
    property p_pc_zero_during_reset;
        @(posedge clk)
        (reset |-> (pc == 32'b0));
    endproperty
    assert property (p_pc_zero_during_reset)
        else $error("[fetch_assertions] PC must be 0 during reset; reset=%b, pc=%0h", reset, pc);

`else
    // Procedural equivalents for simulators with limited SVA support (e.g. xsim)
    logic [31:0] pc_prev;

    always_ff @(posedge clk) begin
        pc_prev <= pc;
    end

    always_ff @(posedge clk) begin
        // A) PC must always be word aligned
        if (pc[1:0] != 2'b00)
            $error("[fetch_assertions] PC must be word aligned; pc[1:0]=%b, expected 2'b00", pc[1:0]);

        // B) When stall is asserted, the PC must not change
        if (!reset && stall && (pc != pc_prev))
            $error("[fetch_assertions] PC must not change while stall is asserted; pc=%0h", pc);

        // C) When stall is not asserted, the PC must increment by 4
        if (!reset && !stall && (pc != pc_prev + 32'd4))
            $error("[fetch_assertions] PC must increment by 4 when not stalled; pc=%0h", pc);

        // D) During reset, the PC should be 0
        if (reset && (pc != 32'b0))
            $error("[fetch_assertions] PC must be 0 during reset; reset=%b, pc=%0h", reset, pc);
    end
`endif

endmodule
