//==============================================================================
// Sequence Detector FSM  —  MEALY-style, detects pattern "1101" WITH overlap
//------------------------------------------------------------------------------
// SAME functional spec as sequenceDetectorFSM.sv, but coded as a MEALY
// machine so you can compare the two side-by-side. This is one of the most
// common interview questions: "implement the same detector both ways and
// explain the trade-off."
//
// MOORE vs MEALY — the side-by-side
// ----------------------------------------------------------------------------
//   property                  Moore (other file)         Mealy (this file)
//   ----------------------    -----------------------    ----------------------
//   output depends on         state only                 state AND current input
//   # of states for 1101      5 (S0..S1101)              4 (S0, S1, S11, S110)
//   detection latency         1 clock AFTER last '1'     SAME cycle as last '1'
//   output glitch risk        none (synchronous w/ clk)  follows din -> can glitch
//   timing pressure           low (output is a flop)     output is comb of input
// ----------------------------------------------------------------------------
//
// WHEN TO PICK WHICH
//   - Use MOORE when downstream logic samples on a clock edge (almost always
//     true inside a chip). The glitch-free, registered output is worth the
//     extra state.
//   - Use MEALY when latency matters and the consumer can tolerate (or is
//     designed for) an output that tracks the input within the same cycle —
//     e.g., chip-level handshakes, optimized control paths.
//
// IMPLEMENTATION NOTE
//   Because the output is combinational on `din`, we use a TWO-PROCESS style:
//     1) `always_ff`  : state register
//     2) `always_comb`: next-state AND output (computed together from
//                       state+input, since they share the same case logic)
//   Both Two-process and Three-process styles are acceptable; for Mealy the
//   two-process form keeps the case statement DRY.
//==============================================================================

module sequence_fsm (
    input  logic clk,
    input  logic rst_n,
    input  logic din,
    output logic detected     // HIGH the moment the 4th bit ('1') arrives
);

    // Mealy needs ONE FEWER STATE than Moore for the same pattern, because
    // the "match" is announced via the output edge itself rather than by
    // entering a dedicated "matched" state.
    typedef enum logic [1:0] {
        S0   = 2'd0,   // nothing useful yet
        S1   = 2'd1,   // seen "1"
        S11  = 2'd2,   // seen "11"
        S110 = 2'd3    // seen "110"   (next '1' triggers detection)
    } state_e;

    state_e state, next_state;

    // ---------------- (1) State register ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S0;
        else        state <= next_state;
    end

    // ---------------- (2) Next-state + Output (Mealy) ----------------
    // KEY INSIGHT: the only transition that completes a match is
    //     (state == S110) && (din == 1)
    // We assert `detected` on EXACTLY that condition — combinationally —
    // and simultaneously route the state to S11 (NOT S1!) to preserve
    // OVERLAP, since the final '1' that completed the match is also the
    // start of a potential next match.
    always_comb begin
        // Defaults (latch-prevention + DRY default for every signal driven here)
        next_state = state;
        detected   = 1'b0;

        unique case (state)
            S0   : next_state = din ? S1   : S0;
            S1   : next_state = din ? S11  : S0;
            S11  : next_state = din ? S11  : S110;     // extra '1' stays in S11
            S110 : begin
                if (din) begin
                    next_state = S11;                   // overlap: '1' restarts "11" prefix
                    detected   = 1'b1;                  // <-- the Mealy output spike
                end else begin
                    next_state = S0;
                end
            end
            default: next_state = S0;
        endcase
    end

endmodule
