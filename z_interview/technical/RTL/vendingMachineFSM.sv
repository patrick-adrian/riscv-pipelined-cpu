//==============================================================================
// Vending Machine FSM  —  Moore, 3-process style
//------------------------------------------------------------------------------
// Classic FSM interview problem. A vending machine accepts coins until the
// inserted total reaches 25 cents, then dispenses one item and returns the
// correct change. We accept 5c, 10c, and 25c coins.
//
// SPEC
//   inputs : `coin` = 2'b01 (5c), 2'b10 (10c), 2'b11 (25c), 2'b00 (no coin)
//   states track the running total: 0c, 5c, 10c, 15c, 20c   (no 25c state —
//     reaching 25c triggers DISPENSE in the SAME cycle the coin arrives)
//   outputs:
//      `dispense` pulses HIGH for one cycle when total >= 25c
//      `change`   pulses HIGH for one cycle when total > 25c (return 5c)
//
// INTERVIEW TALKING POINTS
//  - This problem looks "complicated" but reduces to: state = running total,
//    transitions = total + coin_value, with overflow-to-dispense.
//  - Moore output here is cleanest because the dispense/change pulses align
//    perfectly to the cycle that consumes the coin and returns to IDLE.
//  - "Why not have a 25c state?" Because we always immediately leave it —
//    so it's a transient. Combining the dispense action with the transition
//    BACK to IDLE saves one state and one cycle of latency.
//  - In real hardware you'd parameterize coin values and the price. For
//    interview clarity we hardcode them.
//  - Notice how the 3-process style isolates concerns:
//      * sequential block: state register + reset only
//      * next-state block: pure transitions (no outputs)
//      * output block    : pure outputs    (no transitions)
//    A bug in one block can't corrupt another. This is why the industry
//    converged on this pattern.
//==============================================================================

module vending_machine_fsm (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  coin,        // 00=none, 01=5c, 10=10c, 11=25c
    output logic        dispense,    // 1-cycle pulse: item out
    output logic        change       // 1-cycle pulse: 5c change returned
);

    // States named by current accumulated total (cents)
    typedef enum logic [2:0] {
        S0  = 3'd0,
        S5  = 3'd1,
        S10 = 3'd2,
        S15 = 3'd3,
        S20 = 3'd4
    } state_e;

    state_e state, next_state;

    // Symbolic coin codes — using a typedef makes the case readable AND
    // catches typos at elaboration time (you can't accidentally write 2'b04).
    typedef enum logic [1:0] {
        COIN_NONE = 2'b00,
        COIN_5    = 2'b01,
        COIN_10   = 2'b10,
        COIN_25   = 2'b11
    } coin_e;

    // ---------------- (1) State register ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S0;
        else        state <= next_state;
    end

    // ---------------- (2) Next-state logic ----------------
    // For each (state, coin) pair, compute new_total = old_total + coin.
    // If new_total >= 25c, go back to S0 (item dispensed this cycle).
    always_comb begin
        next_state = state;  // default = hold (e.g., COIN_NONE)

        unique case (state)
            S0: unique case (coin_e'(coin))
                COIN_5  : next_state = S5;
                COIN_10 : next_state = S10;
                COIN_25 : next_state = S0;   // exact price -> dispense, back to idle
                default : next_state = S0;
            endcase

            S5: unique case (coin_e'(coin))
                COIN_5  : next_state = S10;
                COIN_10 : next_state = S15;
                COIN_25 : next_state = S0;   // 30c total -> dispense + 5c change
                default : next_state = S5;
            endcase

            S10: unique case (coin_e'(coin))
                COIN_5  : next_state = S15;
                COIN_10 : next_state = S20;
                COIN_25 : next_state = S0;   // 35c -> dispense + 5c change (we only refund 5c max)
                default : next_state = S10;
            endcase

            S15: unique case (coin_e'(coin))
                COIN_5  : next_state = S20;
                COIN_10 : next_state = S0;   // 25c reached
                COIN_25 : next_state = S0;   // 40c -> dispense + 5c change (still 5c refund cap)
                default : next_state = S15;
            endcase

            S20: unique case (coin_e'(coin))
                COIN_5  : next_state = S0;   // 25c reached
                COIN_10 : next_state = S0;   // 30c -> dispense + 5c change
                COIN_25 : next_state = S0;   // 45c -> dispense + 5c change (still 5c refund cap)
                default : next_state = S20;
            endcase

            default: next_state = S0;
        endcase
    end

    // ---------------- (3) Output logic (Moore, but parameterized by coin
    //                                    because dispense depends on the
    //                                    coin EVENT, which is fine as long
    //                                    as the FSM is consumed by a clocked
    //                                    consumer — pragmatic interview style)
    // Strict-Moore note: a purist would register `dispense`/`change` so they
    // depend on `state` only. Here we compute them combinationally from
    // (state, coin) the SAME way the next_state block does, so the pulse
    // aligns with the spending cycle. Mention this trade-off in interview.
    always_comb begin
        dispense = 1'b0;
        change   = 1'b0;

        unique case (state)
            S0 : if (coin == COIN_25) dispense = 1'b1;                       // 25
            S5 : if (coin == COIN_25) {dispense, change} = 2'b11;            // 30 -> +5 back
            S10: case (coin)
                    COIN_25: {dispense, change} = 2'b11;                     // 35 -> +5 back (overpay capped)
                    default: ;
                 endcase
            S15: case (coin)
                    COIN_10: dispense = 1'b1;                                // 25
                    COIN_25: {dispense, change} = 2'b11;                     // 40
                    default: ;
                 endcase
            S20: case (coin)
                    COIN_5 : dispense = 1'b1;                                // 25
                    COIN_10: {dispense, change} = 2'b11;                     // 30
                    COIN_25: {dispense, change} = 2'b11;                     // 45
                    default: ;
                 endcase
            default: ;
        endcase
    end

endmodule
