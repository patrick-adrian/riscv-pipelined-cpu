//==============================================================================
// 2-Flip-Flop Synchronizer  —  the canonical CDC primitive
//------------------------------------------------------------------------------
// PROBLEM: when a SINGLE-BIT signal crosses from one clock domain (`clk_src`)
// to another (`clk_dst`), the destination flop may sample it WHILE it is
// changing. That violates setup/hold and the flop output goes METASTABLE:
// its voltage hovers between 0 and 1 for an indeterminate time before
// resolving to a logic level (often randomly).
//
// SOLUTION: cascade two flops in the destination domain. The first flop may
// still go metastable, but it has one whole clock period to RESOLVE before
// the second flop samples it. The probability of metastability propagating
// beyond the second flop drops exponentially with the resolution time,
// giving a Mean-Time-Between-Failure (MTBF) of years/centuries in practice.
//
//         clk_src                  clk_dst   clk_dst
//            |                        |         |
//          +---+                    +---+     +---+
//   src -> | D | -- async net --->  | D | --> | D | --> sync_out
//          | Q |                    | Q |     | Q |
//          +---+                    +---+     +---+
//                                  (META!)   (clean)
//
// RULES (memorize these — interviewers love these):
//   1. The SOURCE must come from a FLOP, not from combinational logic.
//      Combinational outputs can glitch; flop outputs cannot.
//   2. Synchronize ONLY single-bit signals this way. For multi-bit data,
//      a 2-FF sync on each bit gives garbage (bits arrive on different
//      cycles). Use a HANDSHAKE (req/ack) or an ASYNC FIFO instead.
//   3. The signal you're crossing must be a CONTROL/STATUS signal that
//      changes infrequently relative to the destination clock, OR it must
//      be Gray-encoded (only 1 bit changes per increment — that's why
//      async-FIFO pointers are always Gray coded).
//   4. Most fabs require a synthesis attribute on the synchronizer flops
//      so the tool doesn't merge / retime them. Common ones below.
//
// INTERVIEW TALKING POINTS
//  - "Why 2 flops? Why not 1 or 3?" — Each extra flop multiplies the MTBF
//    by the metastability-recovery factor (typically 10^3 to 10^6 per
//    stage). Two is the standard cost/benefit point; safety-critical
//    designs (e.g., automotive) sometimes use 3 or 4.
//  - "What if the source domain is FASTER than the destination?" — Then
//    short pulses in the source can be MISSED entirely (the destination
//    never samples them while they're high). You need to STRETCH the
//    pulse in the source domain first, or use a toggle-synchronizer.
//==============================================================================

module synchronizer #(
    parameter int STAGES     = 2,           // 2 is standard; 3+ for safety-critical
    parameter bit RESET_VAL  = 1'b0         // value during reset / power-up
)(
    input  logic clk_dst,                   // destination-domain clock
    input  logic rst_n,                     // destination-domain async reset
    input  logic async_in,                  // signal from another clock domain
    output logic sync_out                   // safe to use in clk_dst
);

    // Pipeline of `STAGES` flops. The synthesis attribute below tells tools
    // like DC / Genus to mark these as ASYNC_REG (Xilinx) or to not optimize
    // them away / retime them. The exact pragma is vendor-specific; both
    // common forms shown so you'd recognize them in real code.
    (* ASYNC_REG = "TRUE" *)                                  // Xilinx Vivado
    (* DONT_TOUCH = "TRUE" *)                                 // Synopsys
    logic [STAGES-1:0] sync_ff;

    always_ff @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff <= {STAGES{RESET_VAL}};
        end else begin
            // Shift the async signal through the stages.
            // Stage 0 captures the async input (this is the flop most likely
            // to go metastable). Each subsequent stage gives the previous
            // one a full clock period to resolve.
            sync_ff <= {sync_ff[STAGES-2:0], async_in};
        end
    end

    // The final stage is the "clean" signal usable in clk_dst's logic.
    assign sync_out = sync_ff[STAGES-1];

endmodule


//==============================================================================
// Reset Synchronizer  —  bonus: a closely-related variant you should know
//------------------------------------------------------------------------------
// Asynchronously ASSERT the reset (so the chip resets even without a clock),
// but synchronously DE-ASSERT it (so the de-assertion edge doesn't violate
// recovery/removal time on a running clock).
//
// This is THE standard reset distribution pattern. Worth memorizing.
//==============================================================================
module reset_synchronizer (
    input  logic clk,
    input  logic async_rst_n,        // raw async reset (e.g., from a PMU pin)
    output logic sync_rst_n          // safe for the rest of the design
);
    (* ASYNC_REG = "TRUE" *)
    logic [1:0] rst_ff;

    // Sensitivity list: posedge clk AND negedge async_rst_n.
    // - On reset (async_rst_n low): both flops clear IMMEDIATELY (async path).
    // - On reset release: '1' walks through the chain on subsequent clock
    //   edges, giving a SYNCHRONOUS rising edge on `sync_rst_n`.
    always_ff @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) rst_ff <= 2'b00;
        else              rst_ff <= {rst_ff[0], 1'b1};
    end

    assign sync_rst_n = rst_ff[1];
endmodule
