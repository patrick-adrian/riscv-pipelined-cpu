//==============================================================================
// Traffic Light Controller FSM
//------------------------------------------------------------------------------
// Two-road intersection (North-South, East-West). Each road has its own
// {Red, Yellow, Green} lamp. Only one road is green at a time; the other is
// red. We use a YELLOW transition state between green and red, just like
// real traffic lights, so cars in the intersection have time to clear.
//
// SEQUENCE (one full cycle):
//      NS_GREEN  --(T_GREEN  ticks)-->  NS_YELLOW
//      NS_YELLOW --(T_YELLOW ticks)-->  EW_GREEN
//      EW_GREEN  --(T_GREEN  ticks)-->  EW_YELLOW
//      EW_YELLOW --(T_YELLOW ticks)-->  NS_GREEN   (and the cycle repeats)
//
// INTERVIEW TALKING POINTS
//  - This is a CLASSIC "FSM + counter" question. The FSM owns the high-level
//    sequence (4 states), and a DOWN-COUNTER owns the dwell time in each
//    state. Combining them lets you express long durations (hundreds of
//    cycles) without needing dozens of states.
//  - Counter style: load on state entry, count down each cycle, transition
//    when it reaches zero. This is exactly how programmable timers work in
//    real SoCs (e.g., a watchdog or pulse generator).
//  - The dwell times are PARAMETERIZED. For a real chip you'd drive these
//    from CSRs (configuration registers) so software can tune them at
//    runtime without an RTL change.
//  - Output encoding: we pack {R,Y,G} as a 3-bit one-hot so a waveform
//    viewer (or an LED) shows the active lamp directly.
//  - Safety: at reset, BOTH roads MUST be red briefly. Some real designs
//    add an explicit ALL_RED transient state for safety; here we start in
//    NS_GREEN/EW_RED for simplicity but mention this in the interview.
//==============================================================================

module traffic_light_fsm #(
    // Dwell times measured in clock cycles. For simulation we use small
    // values; for a 50 MHz clock and a real 30s green, you'd set T_GREEN
    // to 1_500_000_000 — and then size the counter accordingly.
    parameter int T_GREEN  = 20,
    parameter int T_YELLOW = 5
)(
    input  logic       clk,
    input  logic       rst_n,
    // Outputs packed as {Red, Yellow, Green} for each road (one-hot)
    output logic [2:0] ns_light,    // North-South lamp
    output logic [2:0] ew_light     // East-West   lamp
);

    // --------------- State definition ---------------
    typedef enum logic [1:0] {
        NS_GREEN  = 2'd0,
        NS_YELLOW = 2'd1,
        EW_GREEN  = 2'd2,
        EW_YELLOW = 2'd3
    } state_e;
    state_e state, next_state;

    // --------------- Dwell timer ---------------
    // $clog2(max+1) gives the minimum bits needed to count up to max.
    // Using a function of the parameters keeps the counter width correct
    // even if someone overrides T_GREEN/T_YELLOW from above.
    localparam int T_MAX     = (T_GREEN > T_YELLOW) ? T_GREEN : T_YELLOW;
    localparam int CNT_WIDTH = $clog2(T_MAX + 1);

    logic [CNT_WIDTH-1:0] cnt;
    logic                 cnt_done;
    assign cnt_done = (cnt == '0);

    // --------------- (1) State + counter register ---------------
    // We combine the state and counter flops into a single always_ff for
    // clarity: they share reset and they're tightly coupled (counter loads
    // on each state transition).
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= NS_GREEN;
            cnt   <= CNT_WIDTH'(T_GREEN - 1);   // start the green timer
        end else begin
            if (cnt_done) begin
                state <= next_state;
                // Load the dwell time appropriate for the NEW state we are
                // about to enter. -1 because the count INCLUDES the cycle
                // we transition on (an off-by-one classic).
                unique case (next_state)
                    NS_GREEN, EW_GREEN  : cnt <= CNT_WIDTH'(T_GREEN  - 1);
                    NS_YELLOW, EW_YELLOW: cnt <= CNT_WIDTH'(T_YELLOW - 1);
                    default             : cnt <= CNT_WIDTH'(T_GREEN  - 1);
                endcase
            end else begin
                cnt <= cnt - 1'b1;             // tick down toward zero
            end
        end
    end

    // --------------- (2) Next-state logic ---------------
    // Trivial round-robin sequence: G -> Y -> (swap roads) -> G -> Y -> ...
    // Triggered only when the timer expires (cnt_done) — but encoding the
    // transition table here keeps it pure-combinational and easy to read.
    always_comb begin
        unique case (state)
            NS_GREEN  : next_state = NS_YELLOW;
            NS_YELLOW : next_state = EW_GREEN;
            EW_GREEN  : next_state = EW_YELLOW;
            EW_YELLOW : next_state = NS_GREEN;
            default   : next_state = NS_GREEN;
        endcase
    end

    // --------------- (3) Output logic (Moore) ---------------
    // Lamp bit positions: [2]=Red, [1]=Yellow, [0]=Green.
    // Exactly one bit hot per road per state -> one-hot property.
    always_comb begin
        // Safety defaults — both red. If we forget a case below, the
        // intersection FAILS SAFE (no green for anyone) instead of failing
        // dangerous. This pattern matters in real safety-critical RTL.
        ns_light = 3'b100;
        ew_light = 3'b100;

        unique case (state)
            NS_GREEN : begin ns_light = 3'b001; ew_light = 3'b100; end
            NS_YELLOW: begin ns_light = 3'b010; ew_light = 3'b100; end
            EW_GREEN : begin ns_light = 3'b100; ew_light = 3'b001; end
            EW_YELLOW: begin ns_light = 3'b100; ew_light = 3'b010; end
            default  : begin ns_light = 3'b100; ew_light = 3'b100; end
        endcase
    end

    // --------------- Safety assertion ---------------
    // It must NEVER be the case that both roads are green simultaneously.
    // SVA gives us a one-line formal statement of that invariant.
    // synthesis translate_off
    no_both_green: assert property (
        @(posedge clk) disable iff (!rst_n)
        !(ns_light[0] && ew_light[0])
    ) else $fatal(1, "SAFETY VIOLATION: both roads green at once!");
    // synthesis translate_on

endmodule
