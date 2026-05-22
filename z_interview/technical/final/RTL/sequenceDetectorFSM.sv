//==============================================================================
// Sequence Detector FSM  —  Moore-style, detects pattern "1101" WITH overlap
//------------------------------------------------------------------------------
// Asserts `detected` for ONE cycle after the FSM has observed the bit
// sequence 1-1-0-1 on `din` over the last four clock cycles. "Overlap" means
// the last bit of one match can also be the first bit of the next match:
//
//   cycle :  0 1 2 3 4 5 6
//   din   :  1 1 0 1 1 0 1
//   det   :  0 0 0 1 0 0 1   <-- two detections from overlapping 1101s
//
// INTERVIEW TALKING POINTS
//  - MOORE vs MEALY:
//      * Moore  : output depends ONLY on current state.
//                 -> output is glitch-free and synchronous with clock.
//                 -> needs one extra state to "remember" the full match.
//      * Mealy  : output depends on state AND current input.
//                 -> can react one cycle EARLIER (fewer states).
//                 -> output can glitch with the input.
//    This file implements MOORE. See sequenceFSM.sv for the MEALY contrast.
//
//  - THREE-PROCESS FSM CODING STYLE (industry standard):
//      1) `always_ff` : state register only           (sequential)
//      2) `always_comb`: next-state logic             (combinational)
//      3) `always_comb`: output logic                 (combinational)
//    Separating these three concerns:
//        * makes reset behavior obvious,
//        * prevents accidental latches in next-state or output,
//        * lets the synthesis tool optimize each piece independently.
//
//  - STATE ENCODING: `typedef enum` named states. The tool picks the
//    binary/one-hot encoding (often via a synthesis attribute). One-hot is
//    fast and FPGA-friendly; binary is area-efficient on ASIC.
//
//  - OVERLAP HANDLING: from the DETECTED state, on seeing another '1' we
//    go to state S11 (NOT back to IDLE). That's what enables overlap.
//==============================================================================

module sequence_detector_fsm (
    input  logic clk,
    input  logic rst_n,
    input  logic din,         // serial input bit, sampled on posedge clk
    output logic detected     // pulses high for one cycle on a match
);

    // ---------------- State definition ----------------
    // Each state name encodes "the longest suffix of 1101 we've seen so far".
    //   S0      : nothing useful yet (or last bit broke the pattern)
    //   S1      : seen "1"
    //   S11     : seen "11"
    //   S110    : seen "110"
    //   S1101   : seen "1101"  -> detection state (Moore output is here)
    typedef enum logic [2:0] {
        S0    = 3'd0,
        S1    = 3'd1,
        S11   = 3'd2,
        S110  = 3'd3,
        S1101 = 3'd4
    } state_e;

    state_e state, next_state;

    // ---------------- (1) State register (sequential) ----------------
    // The ONLY flop in this design. Async reset to S0 on power-up.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S0;
        else        state <= next_state;
    end

    // ---------------- (2) Next-state logic (combinational) ----------------
    // Read carefully: each case asks "given where we are and what bit just
    // arrived, what's the LONGEST suffix of 1101 we've now seen?"
    //
    // A useful trick: when the pattern breaks, don't always fall to S0 —
    // check if the new bit could be the START of a new match. E.g., from
    // S110 with din=0 we go to S0 (because '0' starts nothing), but from
    // S11 with din=1 we STAY in S11 (the new '1' extends the run of ones).
    always_comb begin
        next_state = state;  // DEFAULT prevents latches even if a case is forgotten

        unique case (state)
            S0    : next_state = din ? S1    : S0;
            S1    : next_state = din ? S11   : S0;
            S11   : next_state = din ? S11   : S110;   // extra '1' stays in S11
            S110  : next_state = din ? S1101 : S0;     // got the trailing '1' -> match!
            S1101 : next_state = din ? S11   : S0;     // <-- OVERLAP: '1' restarts at S11
            default: next_state = S0;
        endcase
    end

    // ---------------- (3) Output logic (combinational, Moore) ----------------
    // Pure function of `state`. No `din` here — that's what makes it Moore.
    // The output is delayed by one clock relative to seeing the final '1',
    // but it is GUARANTEED to be glitch-free and clock-aligned.
    always_comb begin
        detected = (state == S1101);
    end

endmodule
