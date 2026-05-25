//==============================================================================
// Adders  —  half adder, full adder, ripple-carry, carry-lookahead
//------------------------------------------------------------------------------
// Adder design is THE classic digital-logic question. You should be able to:
//   1. Derive a half adder from its truth table.
//   2. Build a full adder from two half adders + OR.
//   3. Chain N full adders into a ripple-carry adder (RCA).
//   4. Explain why RCA is slow (carry path length = N gate delays).
//   5. Derive Generate/Propagate and use them to build a CLA adder.
//
// This file contains all four levels so you can read them top-down.
//
// COMMON INTERVIEW QUESTIONS
//   "What's the critical path of an N-bit ripple adder?"
//      -> The carry chain. Roughly 2N gate delays (2 per FA stage).
//
//   "How does CLA improve on that?"
//      -> Carry at each bit can be computed in parallel from the inputs
//         using the G/P equations. A 4-bit CLA block has constant carry
//         delay (~3 gates). Group 4-bit blocks for 16-bit, then again for
//         64-bit — logarithmic depth.
//
//   "What's the area/speed trade-off?"
//      -> RCA: smallest area, slowest. CLA: ~2x area, ~log2(N) delay.
//         Modern tools usually pick a Kogge-Stone or Brent-Kung tree
//         automatically; you just write `a + b` and they decide.
//
//   "What about signed numbers?"
//      -> Two's-complement addition is BIT-IDENTICAL to unsigned. Same
//         adder hardware. The flags (overflow/carry) just get reinterpreted.
//==============================================================================


//------------------------------------------------------------------------------
// Half Adder — adds two 1-bit inputs, produces sum + carry.
//   Truth table:    a b | s c
//                   0 0 | 0 0
//                   0 1 | 1 0
//                   1 0 | 1 0
//                   1 1 | 0 1
//   => s = a XOR b,  c = a AND b
//------------------------------------------------------------------------------
module half_adder (
    input  logic a, b,
    output logic sum,
    output logic cout
);
    assign sum  = a ^ b;
    assign cout = a & b;
endmodule


//------------------------------------------------------------------------------
// Full Adder — adds two bits + carry-in.
//   sum  = a XOR b XOR cin
//   cout = (a AND b) OR (cin AND (a XOR b))
//
// Built either directly (one assign each) or from two half adders. Both
// shown below; the synthesizer produces the same gates.
//------------------------------------------------------------------------------
module full_adder (
    input  logic a, b, cin,
    output logic sum,
    output logic cout
);
    // -- direct form (easiest to remember on a whiteboard) ----------------
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));

    // -- equivalent: built from two half adders + OR -----------------------
    //   wire s1, c1, c2;
    //   half_adder h0 (.a(a),  .b(b),   .sum(s1),  .cout(c1));
    //   half_adder h1 (.a(s1), .b(cin), .sum(sum), .cout(c2));
    //   assign cout = c1 | c2;
endmodule


//------------------------------------------------------------------------------
// Ripple-Carry Adder (RCA) — N full adders chained
//   carry[0]   = cin
//   carry[i+1] = cout of FA at bit i
//
// `generate for` instantiates a hardware copy per bit. This is THE
// canonical use of `generate` and a great thing to demonstrate.
//------------------------------------------------------------------------------
module ripple_carry_adder #(
    parameter int N = 8
)(
    input  logic [N-1:0] a, b,
    input  logic         cin,
    output logic [N-1:0] sum,
    output logic         cout
);
    // Internal carry chain: carry[0] = cin, carry[N] = cout
    logic [N:0] carry;
    assign carry[0] = cin;
    assign cout     = carry[N];

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : g_fa
            full_adder fa_i (
                .a   (a[i]),
                .b   (b[i]),
                .cin (carry[i]),
                .sum (sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    // -- The OBVIOUS one-line alternative --------------------------------
    //   assign {cout, sum} = a + b + cin;
    // Synthesis tools will internally produce a CLA or parallel-prefix
    // adder from this. Hand-coding RCA is rare in production; here we do
    // it to make the carry chain explicit for learning/whiteboard purposes.
endmodule


//------------------------------------------------------------------------------
// Carry-Lookahead Adder (CLA) — 4 bits, the textbook block
//
// GENERATE / PROPAGATE per bit (memorize these — they show up EVERY time):
//     g_i = a_i AND b_i      // "this bit GENERATES a carry on its own"
//     p_i = a_i XOR b_i      // "this bit PROPAGATES an incoming carry"
//                            //  (some books use OR; XOR is the modern form)
//
// CARRY equation (unrolled, for bit i):
//     c_{i+1} = g_i OR (p_i AND c_i)
//     c_1 = g0 + p0.c0
//     c_2 = g1 + p1.g0 + p1.p0.c0
//     c_3 = g2 + p2.g1 + p2.p1.g0 + p2.p1.p0.c0
//     c_4 = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0 + p3.p2.p1.p0.c0
//
// All four carries can be computed IN PARALLEL — that's the point. The
// critical path is no longer N FA delays; it's the depth of one G/P AND-OR
// tree (≈3 gate levels for a 4-bit block).
//------------------------------------------------------------------------------
module cla_adder_4bit (
    input  logic [3:0] a, b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);
    logic [3:0] g, p;     // generate and propagate
    logic [4:1] c;        // c[1]..c[4] = carries out of bits 0..3

    // Per-bit generate / propagate
    assign g = a & b;
    assign p = a ^ b;

    // Parallel carry equations (the heart of CLA)
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0])
                | (p[2] & p[1] & p[0] & cin);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                | (p[3] & p[2] & p[1] & g[0])
                | (p[3] & p[2] & p[1] & p[0] & cin);

    // Sum bits: each is just p_i XOR incoming carry.
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign cout   = c[4];

    // For wider adders (16/32/64-bit), build a 2nd-level lookahead from
    // BLOCK-level G and P:
    //   G_block = g3 | (p3.g2) | (p3.p2.g1) | (p3.p2.p1.g0)
    //   P_block = p3 & p2 & p1 & p0
    // Then repeat the same equations one level up. This is "hierarchical
    // CLA" and is the textbook path to log-depth adders.
endmodule
