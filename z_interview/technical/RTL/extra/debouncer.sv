//==============================================================================
// Debouncer  —  clean up a noisy mechanical input (e.g., pushbutton)
//------------------------------------------------------------------------------
// PROBLEM: a mechanical button or switch doesn't make a clean 0->1 edge.
// When it closes, the contacts physically bounce for a few milliseconds,
// producing a burst of fast 0/1 transitions:
//
//   raw:  0 0 0 0 1 0 1 1 0 1 1 1 1 1 1 1 1 1
//                  ^^^^^^^ bounce ^^^^^^^
//                                          ^ truly stable
//
// At a 50 MHz clock that's hundreds of thousands of cycles of garbage.
// Downstream logic (e.g., a counter) would count many "presses" for one
// physical press.
//
// SOLUTION: only propagate the new value AFTER the raw input has been
// stable for some minimum time (typically 10-20 ms for human buttons).
// We implement this with:
//   1. A 2-FF SYNCHRONIZER on the input (it's almost certainly async to clk).
//   2. A COUNTER that resets every time the synchronized input changes.
//   3. When the counter reaches MAX, we know the input has been stable
//      for MAX/F_CLK seconds — adopt the new value and start watching again.
//
// INTERVIEW TALKING POINTS
//  - "Why the 2-FF synchronizer at the front?" — Because the raw button
//    signal is async to the FPGA clock; without it, the first flop can
//    go metastable. Don't skip this even if "the button is slow" — async
//    is async.
//  - "Why not just sample the input every N cycles?" — that catches the
//    bounce in the middle and gives wrong results. The COUNTER-based
//    approach requires CONTINUOUS stability, which is the actual spec.
//  - "What if I want both press and release debounced?" — the same module
//    handles both, because the counter resets on ANY change of the input.
//  - PARAMETERIZED debounce time: COUNT_MAX = F_CLK * DEBOUNCE_SEC. For
//    50 MHz and 10 ms, that's 500_000 cycles -> 20-bit counter.
//==============================================================================

module debouncer #(
    parameter int  F_CLK_HZ      = 50_000_000,
    parameter int  DEBOUNCE_US   = 10_000,                   // 10 ms default
    // Computed: number of clk cycles the input must be stable to count.
    parameter int  COUNT_MAX     = (F_CLK_HZ / 1_000_000) * DEBOUNCE_US,
    parameter int  CNT_W         = $clog2(COUNT_MAX + 1)
)(
    input  logic clk,
    input  logic rst_n,
    input  logic noisy_in,           // raw signal from a pad/button (async)
    output logic clean_out,          // debounced, synchronous to clk
    output logic rising_edge,        // 1-cycle pulse on a clean 0->1
    output logic falling_edge        // 1-cycle pulse on a clean 1->0
);

    // -----------------------------------------------------------------------
    // Stage 1: 2-FF synchronizer to bring noisy_in into clk's domain safely.
    // -----------------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *)
    logic [1:0] sync_ff;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) sync_ff <= 2'b00;
        else        sync_ff <= {sync_ff[0], noisy_in};
    end
    wire sync_in = sync_ff[1];

    // -----------------------------------------------------------------------
    // Stage 2: stability counter
    //   - reset to 0 every time `sync_in` differs from the LAST sampled
    //     stable value (`clean_out`).
    //   - otherwise increment toward COUNT_MAX.
    //   - when it reaches COUNT_MAX, we know `sync_in` has been stable
    //     long enough; latch it as the new `clean_out`.
    // -----------------------------------------------------------------------
    logic [CNT_W-1:0] cnt;
    logic             clean_q, clean_d;

    always_comb begin
        // by default, hold the clean output
        clean_d = clean_q;
        // if the counter has saturated, adopt the synchronized value
        if (cnt == CNT_W'(COUNT_MAX)) clean_d = sync_in;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= '0;
            clean_q <= 1'b0;
        end else begin
            if (sync_in != clean_q) begin
                // input differs from the currently-stable value: keep counting
                if (cnt != CNT_W'(COUNT_MAX)) cnt <= cnt + 1'b1;
            end else begin
                // input matches the current stable value: nothing to debounce
                cnt <= '0;
            end
            clean_q <= clean_d;
        end
    end

    // -----------------------------------------------------------------------
    // Outputs: the debounced level, plus convenience edge pulses.
    // -----------------------------------------------------------------------
    assign clean_out = clean_q;

    // Edge detection on the debounced output (the EdgeDetector idiom).
    logic clean_dly;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) clean_dly <= 1'b0;
        else        clean_dly <= clean_q;
    end
    assign rising_edge  =  clean_q & ~clean_dly;
    assign falling_edge = ~clean_q &  clean_dly;

endmodule
