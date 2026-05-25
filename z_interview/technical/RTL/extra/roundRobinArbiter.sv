//==============================================================================
// Round-Robin Arbiter
//------------------------------------------------------------------------------
// N requestors compete for ONE shared resource (memory port, bus, etc.).
// The arbiter outputs a one-hot `grant` vector saying who gets it this cycle.
//
// FAIRNESS: a strict priority encoder would let `req[N-1]` starve all other
// requestors. Round-robin fixes that by ROTATING priority. After granting
// requestor `k`, on the NEXT cycle the highest priority goes to `k+1`, then
// `k+2`, and so on (wrapping around). Every requestor is guaranteed service
// within at most N cycles — that's the definition of "fair".
//
// THE MASK TRICK (most-asked arbiter algorithm)
// ----------------------------------------------------------------------------
// We keep a state register `mask` whose bits are 1 for "this requestor and
// everyone AFTER the last granted one". Then:
//
//     masked_req = req & mask          // requests of higher-or-equal priority
//     grant_hi   = lowest set bit of masked_req      (if any)
//     grant_lo   = lowest set bit of req             (fallback: wrap around)
//     grant      = grant_hi ? grant_hi : grant_lo
//
// "Lowest set bit of x" is computed combinationally by `x & -x` (two's-comp
// negation). That one-line idiom is the priority encoder in disguise.
//
// After granting bit `k`, we update the mask so future cycles consider only
// bits > k first:   mask_next = ~((grant - 1) | grant) = ~(2*grant - 1).
// On wrap-around (no masked req fired), we reset the mask to all-ones.
//
// INTERVIEW TALKING POINTS
//  - "What's the latency?" — the grant is COMBINATIONAL on the current
//    requests; latency = 0 cycles (the mask updates next cycle for fairness).
//  - "Is grant guaranteed one-hot?" — yes, because `x & -x` isolates a
//    single bit. SVA assertion at the bottom enforces this.
//  - "What if no one requests?" — grant is all zeros, mask is unchanged.
//    No starvation issue because there's no one to starve.
//  - Alternative implementations: priority + rotating pointer; pipelined
//    arbiter for very high frequency. Mention these to show breadth.
//==============================================================================

module round_robin_arbiter #(
    parameter int N = 4
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic [N-1:0]      req,        // request vector (any bits set)
    output logic [N-1:0]      grant       // one-hot grant (or all-zero)
);

    // ----- State: which requestors are "in this round" --------------------
    // mask[i] = 1 means "requestor i is eligible at full priority this cycle".
    // After granting bit k, we clear mask[0..k] so they have to wait until
    // the next round (when mask wraps back to all-ones).
    logic [N-1:0] mask;

    // ----- Combinational arbitration -------------------------------------
    logic [N-1:0] masked_req;
    logic [N-1:0] grant_hi;     // winner from the masked (higher-priority) set
    logic [N-1:0] grant_lo;     // winner if we have to wrap (fallback)

    assign masked_req = req & mask;

    // "Lowest set bit" trick:  x & (-x)  isolates the LSB-most '1' of x.
    // E.g., x = 8'b0010_1100  ->  -x = 8'b1101_0100  ->  x & -x = 8'b0000_0100.
    // SystemVerilog allows unary minus on unsigned logic; the bit pattern is
    // the two's-complement negation, which is exactly what we want here.
    assign grant_hi = masked_req & (~masked_req + 1'b1);
    assign grant_lo = req        & (~req        + 1'b1);

    // Use the higher-priority winner if any, otherwise wrap to the lowest.
    assign grant = (|masked_req) ? grant_hi : grant_lo;

    // ----- Mask update (the only flop in this design) --------------------
    // Goal: after granting bit k, mask_next has bits (k+1)..N-1 set, and
    // bits 0..k cleared. We get that by computing the "thermometer" of
    // grant + everything below it:
    //
    //     below_or_eq = (grant - 1) | grant    // all bits 0..k set
    //     mask_next   = ~below_or_eq           // bits k+1..N-1 set
    //
    // If no one was granted (grant == 0), keep the mask as-is so we don't
    // accidentally lose state.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mask <= '1;                                 // start: everyone eligible
        end else if (|grant) begin
            mask <= ~((grant - 1'b1) | grant);
            // Special case: if we just granted bit N-1, ~(...) becomes 0,
            // which would starve everyone. Treat all-zero mask as a wrap
            // signal — next cycle the `|masked_req` will be 0 and we'll
            // fall back to `grant_lo`, then this same line will reset the
            // mask correctly. (Equivalent fix: explicitly OR-in '1 here.)
        end
    end

    // ----- Assertions -----------------------------------------------------
    // synthesis translate_off
    onehot0_grant: assert property (@(posedge clk) disable iff (!rst_n)
                                     $onehot0(grant))
        else $error("arbiter grant must be one-hot-or-zero, got %b", grant);

    no_phantom_grant: assert property (@(posedge clk) disable iff (!rst_n)
                                        (grant & ~req) == '0)
        else $error("arbiter granted a non-requesting requestor");
    // synthesis translate_on

endmodule
