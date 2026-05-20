//==============================================================================
// D Flip-Flop (DFF)
//------------------------------------------------------------------------------
// The DFF is the fundamental sequential element. On each rising edge of clk,
// it captures input `d` and presents it on output `q`. Everything synchronous
// in a digital design (registers, pipelines, FSM state) is built from DFFs.
//
// INTERVIEW TALKING POINTS
//  - Setup/hold time: `d` must be stable for t_su BEFORE posedge clk and
//    for t_h AFTER posedge clk. Violating either causes metastability.
//  - Clock-to-Q (t_cq): propagation delay from the clock edge to `q` valid.
//  - Async vs sync reset:
//      * Async reset: takes effect immediately; needed at power-up before clk
//        is stable. Must be de-asserted SYNCHRONOUSLY to avoid recovery/
//        removal-time violations (this is why we use a reset synchronizer).
//      * Sync reset: simpler timing analysis, but requires a running clock
//        to take effect. Common inside SoCs after the reset synchronizer.
//  - Non-blocking (<=) is REQUIRED in sequential always blocks so that all
//    flops sample their "old" values on the same edge (race-free semantics).
//  - `always_ff` is a SystemVerilog construct that tells the tool "this is
//    a flop". The tool will ERROR if you write code that doesn't infer one
//    (e.g., a missing edge). This catches bugs that plain `always` won't.
//  - `logic` replaces both `wire` and `reg` in SV. The synthesis tool decides
//    whether it becomes a net or a flop based on how it's driven.
//==============================================================================

// ----- Variant 1: Async-reset DFF with clock enable (most common in CPUs) ----
module dff #(
    parameter int WIDTH       = 1,      // parameterize width -> reusable as a register file slice
    parameter logic [WIDTH-1:0] RESET_VAL = '0  // '0 fills with zeros at any width
)(
    input  logic              clk,    // clock; active rising edge
    input  logic              rst_n,  // ACTIVE-LOW async reset (industry convention: `_n` suffix)
    input  logic              en,     // clock enable; gates the data, NOT the clock
    input  logic [WIDTH-1:0]  d,
    output logic [WIDTH-1:0]  q
);

    // Sensitivity list includes posedge clk AND negedge rst_n because rst_n is
    // ASYNCHRONOUS — the flop must respond to its falling edge even with no clk.
    // For active-HIGH reset you would write `posedge rst` instead.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= RESET_VAL;          // async clear path
        end else if (en) begin
            q <= d;                  // capture only when enabled
        end
        // else: hold previous value (implicit; do NOT write `else q <= q;` —
        // that's harmless but visually noisy. The flop holds by default.)
    end

    // WHY enable instead of gating the clock?
    //   Gating `clk` with `en` (clk_gated = clk & en) creates glitches and
    //   skew problems. Real clock gating uses a special integrated cell
    //   (ICG / latch-AND) inserted by the synthesis tool. For RTL you write
    //   an `if (en)` and let the tool infer the ICG if power matters.

endmodule


// ----- Variant 2: Synchronous-reset DFF (no enable) ---------------------------
// Use this when you're past the reset synchronizer and want easier STA.
module dff_sync_rst #(
    parameter int WIDTH = 1
)(
    input  logic              clk,
    input  logic              rst,   // ACTIVE-HIGH synchronous reset
    input  logic [WIDTH-1:0]  d,
    output logic [WIDTH-1:0]  q
);

    // Notice rst is NOT in the sensitivity list — it's sampled like any
    // ordinary input on the rising clock edge.
    always_ff @(posedge clk) begin
        if (rst) q <= '0;
        else     q <= d;
    end

endmodule
