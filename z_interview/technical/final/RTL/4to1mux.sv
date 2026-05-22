//==============================================================================
// 4-to-1 Multiplexer
//------------------------------------------------------------------------------
// A mux picks one of N data inputs based on a select signal. It is the most
// common combinational primitive — every conditional assignment ultimately
// synthesizes to a mux tree.
//
// INTERVIEW TALKING POINTS
//  - Pure combinational logic: no clock, no state. Output must be a function
//    of ONLY the current inputs (no latches, no flops).
//  - To guarantee no latch in `always_comb`:
//        (1) drive `y` on EVERY path through the block, or
//        (2) assign a default at the top of the block.
//    Forgetting either is the #1 cause of "inferred latch" warnings.
//  - `unique case` tells the tool the cases are mutually exclusive AND fully
//    covered. The simulator throws a runtime error if neither holds — great
//    for catching bugs early. Synthesis treats it as a parallel mux.
//  - `priority case` would imply order matters (like an if/else-if chain) and
//    can build a priority encoder. For a mux we want `unique` instead.
//  - Parameterized WIDTH so the same module works for 1-bit control muxes
//    or 32-bit datapath muxes.
//==============================================================================

module mux4to1 #(
    parameter int WIDTH = 1
)(
    input  logic [WIDTH-1:0] d0, d1, d2, d3,  // four data inputs
    input  logic [1:0]       sel,             // 2-bit select
    output logic [WIDTH-1:0] y
);

    // ------------------------------------------------------------------
    // STYLE A: `always_comb` + `unique case` (RECOMMENDED for muxes)
    //   - Most readable for >2 inputs.
    //   - `always_comb` is SV-only: the tool ERRORS if the block could
    //     infer a latch (i.e., if `y` is not assigned on every path).
    //     That safety is why we prefer it over plain `always @(*)`.
    // ------------------------------------------------------------------
    always_comb begin
        unique case (sel)
            2'b00:   y = d0;
            2'b01:   y = d1;
            2'b10:   y = d2;
            2'b11:   y = d3;
            default: y = '0;   // unreachable for a 2-bit sel, but defensive
                               // against X-propagation in simulation.
        endcase
    end

    // ------------------------------------------------------------------
    // STYLE B (equivalent, shown for discussion):
    //
    //   assign y = (sel == 2'b00) ? d0 :
    //              (sel == 2'b01) ? d1 :
    //              (sel == 2'b10) ? d2 : d3;
    //
    //   This is a ternary CHAIN. It synthesizes to the same mux, but the
    //   ladder shape can mislead a junior reader into thinking it's a
    //   priority encoder. Prefer the case form for >2 inputs.
    // ------------------------------------------------------------------

    // ------------------------------------------------------------------
    // STYLE C (also equivalent):
    //
    //   logic [WIDTH-1:0] inputs [4];
    //   assign inputs[0] = d0; assign inputs[1] = d1;
    //   assign inputs[2] = d2; assign inputs[3] = d3;
    //   assign y = inputs[sel];
    //
    //   Indexing an array by `sel` is a clean idiom — the synthesis tool
    //   recognizes it as a mux. Very common in real datapaths.
    // ------------------------------------------------------------------

endmodule
