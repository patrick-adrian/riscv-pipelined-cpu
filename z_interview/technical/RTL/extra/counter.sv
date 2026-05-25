//==============================================================================
// Counter  —  parameterized up/down counter with enable, load, and modulo-N
//------------------------------------------------------------------------------
// A counter is the most-asked sequential block after the flip-flop. Real
// systems use counters everywhere: program counters, timers, FIFO pointers,
// arbiter pointers, refresh counters, watchdogs, baud-rate dividers.
//
// FEATURES of this block:
//   - direction selectable (up = 1, down = 0)
//   - clock enable (`en`)
//   - synchronous load of an arbitrary value (`load` + `load_val`)
//   - wraps at MODULO   (counts 0..MODULO-1 then back to 0 in up-mode)
//   - `tc` (terminal count) flags the LAST cycle BEFORE wrap, NOT after.
//     This is the classic interview trick: detect "about to wrap" in the
//     same cycle the wrap value is on `count`, so downstream consumers
//     get one cycle of warning with no extra latency.
//
// INTERVIEW TALKING POINTS
//  - "Why a synchronous load instead of an async one?" — same answer as
//    sync reset: cleaner STA, no recovery/removal violations.
//  - "How wide is the counter?" — `$clog2(MODULO)` bits. For MODULO=10
//    you need 4 bits (counts 0..9; can hold 0..15 but only 0..9 used).
//  - "What if MODULO isn't a power of two?" — you can't just rely on
//    natural wraparound of the bit width; you must explicitly compare
//    to MODULO-1 and reset to 0. We do that here.
//  - Common bug: writing `if (count == MODULO)` instead of `MODULO-1`.
//    Off-by-one. Walk through cycle by cycle on the whiteboard.
//==============================================================================

module counter #(
    parameter int MODULO = 10                   // counts 0..MODULO-1
)(
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic                          en,        // clock enable (gated load too)
    input  logic                          up_down,   // 1 = count up, 0 = count down
    input  logic                          load,      // sync load takes priority over count
    input  logic [$clog2(MODULO)-1:0]     load_val,
    output logic [$clog2(MODULO)-1:0]     count,
    output logic                          tc         // terminal count flag
);

    // Width derived from MODULO. `$clog2(N)` returns ceiling-log2(N), which
    // is the minimum number of bits to represent values 0..N-1.
    localparam int W = $clog2(MODULO);

    // ----- Sequential update -----------------------------------------------
    // Priority inside the always_ff (highest first):
    //     async reset  >  sync load  >  enabled count  >  hold
    // The `else if` chain encodes that priority into a small mux tree.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else if (en) begin
            if (load) begin
                count <= load_val;                       // sync load wins over count
            end else if (up_down) begin
                // UP: wrap from MODULO-1 back to 0
                count <= (count == W'(MODULO-1)) ? '0
                                                 : count + 1'b1;
            end else begin
                // DOWN: wrap from 0 back to MODULO-1
                count <= (count == '0)            ? W'(MODULO-1)
                                                 : count - 1'b1;
            end
        end
        // else: hold (en == 0)
    end

    // ----- Terminal-count flag ---------------------------------------------
    // Combinational so it asserts in the SAME cycle the "about to wrap" value
    // is on `count`. Some designs register `tc` if its consumer can't accept
    // a comb signal; that's a one-cycle latency trade-off worth knowing.
    assign tc = en && ( up_down ? (count == W'(MODULO-1))
                                 : (count == '0) );

endmodule
