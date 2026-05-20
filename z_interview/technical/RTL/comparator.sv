//==============================================================================
// N-bit Magnitude Comparator
//------------------------------------------------------------------------------
// Compares two N-bit operands and produces equality / greater-than / less-than
// flags. The flag form (eq, gt, lt) is more useful in a datapath than a
// 2-bit "result code" because each flag can drive its own consumer (branch
// unit, FSM, etc.) without extra decode logic.
//
// INTERVIEW TALKING POINTS
//  - Signed vs unsigned matters! In two's-complement, the MSB has weight
//    -2^(N-1), so the comparison flips for half the value space. We expose
//    a SIGNED parameter so the same module serves both worlds.
//  - SystemVerilog `signed` cast forces the comparison operator to do an
//    arithmetic (signed) compare. By default, `logic [N-1:0]` is UNSIGNED.
//  - Synthesis maps `<`, `>`, `==` to ripple-borrow subtractors or
//    carry-look-ahead comparator trees. Equality (`==`) is much cheaper
//    than magnitude (`<`/`>`) because it only needs XOR-reduce, not carry.
//  - For very wide comparators (e.g., 64-bit), a hierarchical / CLA-style
//    comparator beats the simple ripple form for timing. Tools usually
//    do this for you — but it's worth knowing.
//  - The output flags are mutually exclusive AND one-hot: exactly one of
//    {eq, gt, lt} is high every cycle. An assertion can enforce that.
//==============================================================================

module comparator #(
    parameter int  WIDTH  = 8,
    parameter bit  SIGNED = 1'b0   // 0 = unsigned compare, 1 = signed (two's comp)
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic             eq,   // a == b
    output logic             gt,   // a >  b
    output logic             lt    // a <  b
);

    // Equality is sign-agnostic: identical bit patterns are equal whether
    // we interpret them as signed or unsigned. So we can compute it once
    // outside the signed/unsigned branch.
    assign eq = (a == b);

    // --------------------------------------------------------------------
    // Magnitude flags
    //
    // The `$signed()` system function REINTERPRETS the bit vector as a
    // two's-complement value for the purpose of the surrounding expression.
    // It does NOT change the bits — just how the operator treats them.
    //
    // We pick the interpretation at ELABORATION time (parameter), so the
    // synthesizer produces only the comparator we actually need, not both.
    // --------------------------------------------------------------------
    generate
        if (SIGNED) begin : g_signed
            assign gt = ($signed(a) >  $signed(b));
            assign lt = ($signed(a) <  $signed(b));
        end else begin : g_unsigned
            assign gt = (a >  b);
            assign lt = (a <  b);
        end
    endgenerate

    // --------------------------------------------------------------------
    // SVA (SystemVerilog Assertion): one-hot output invariant.
    // Synthesis tools ignore assertions; they only fire in simulation.
    // Good habit: lock down your design's invariants right in the RTL.
    // --------------------------------------------------------------------
    // synthesis translate_off
    one_hot_outputs: assert property (@* $onehot({eq, gt, lt}))
        else $error("comparator flags not one-hot: eq=%b gt=%b lt=%b", eq, gt, lt);
    // synthesis translate_on

endmodule
