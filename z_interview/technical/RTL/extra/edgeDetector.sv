//==============================================================================
// Edge Detector  —  level signal -> one-cycle pulse
//------------------------------------------------------------------------------
// Converts a LEVEL signal into a one-cycle PULSE whenever a rising, falling,
// or either-direction transition is detected. Used everywhere:
//   - converting a button press (held for many cycles) into a single event
//   - detecting handshake req/ack transitions
//   - detecting end-of-burst signals
//
// THE IDIOM (memorize this exactly — it appears constantly in real RTL):
//
//     always_ff @(posedge clk) prev <= sig;
//     wire rise = sig & ~prev;       // sig is high NOW, was low LAST cycle
//     wire fall = ~sig & prev;       // sig is low  NOW, was high LAST cycle
//     wire any  = sig ^  prev;       // either kind of transition
//
// All edges are detected by comparing the CURRENT input to a ONE-CYCLE-DELAYED
// copy. The single flop stores "what `sig` was last cycle". XOR catches any
// change; AND with the polarity catches the specific direction.
//
// INTERVIEW TALKING POINTS
//  - The output pulse is ONE CYCLE wide because `prev` updates on the next
//    edge, immediately killing the (sig & ~prev) term.
//  - The input `sig` MUST be synchronous to `clk` already. If it crosses
//    clock domains, put a 2-FF synchronizer in front, OTHERWISE you can
//    detect false edges from metastability glitches.
//  - "What if I want a 2-cycle pulse?" — extend the shift register, or
//    use a counter to stretch the pulse. Don't confuse "pulse width" with
//    "edge detection" — they are separate concerns.
//==============================================================================

module edge_detector #(
    parameter int WIDTH = 1                 // detect edges on a vector? Per-bit.
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic [WIDTH-1:0]  sig_in,       // synchronous input
    output logic [WIDTH-1:0]  rising,       // 1-cycle pulse on 0->1 transition
    output logic [WIDTH-1:0]  falling,      // 1-cycle pulse on 1->0 transition
    output logic [WIDTH-1:0]  either        // 1-cycle pulse on ANY transition
);

    // The one and only flop: a delayed copy of the input.
    logic [WIDTH-1:0] sig_dly;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) sig_dly <= '0;
        else        sig_dly <= sig_in;
    end

    // All three detectors are PURE COMBINATIONAL — they're just bit-level
    // logic on (sig_in, sig_dly). No extra flops needed.
    assign rising  =  sig_in & ~sig_dly;        // current=1, previous=0
    assign falling = ~sig_in &  sig_dly;        // current=0, previous=1
    assign either  =  sig_in ^  sig_dly;        // any difference

    // -----------------------------------------------------------------------
    // ALTERNATIVE CODING STYLES (worth knowing for the whiteboard):
    //
    //   // Equivalent compact form using a single 2-bit shift register:
    //   logic [1:0] hist;
    //   always_ff @(posedge clk) hist <= {hist[0], sig_in};
    //   assign rising = (hist == 2'b01);   // last->now
    //   assign falling= (hist == 2'b10);
    //
    //   // Or directly from a posedge sample:
    //   //   "rising edge in cycle N" == (sig_in[N]=1 && sig_in[N-1]=0)
    //   // which is what the formula above computes.
    // -----------------------------------------------------------------------

endmodule
