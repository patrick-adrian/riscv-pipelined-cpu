//==============================================================================
// Priority Encoder
//------------------------------------------------------------------------------
// Takes an N-bit input vector and outputs the INDEX of the highest-priority
// asserted bit, plus a `valid` flag indicating that at least one bit was set.
// Convention here: BIT [N-1] is HIGHEST priority, BIT [0] is LOWEST.
// (You can flip this with a `lsb_first` parameter if asked.)
//
// EXAMPLE (N=8):
//     in = 8'b0010_0100  -> out = 5, valid = 1   (bit 5 is highest set)
//     in = 8'b0000_0001  -> out = 0, valid = 1
//     in = 8'b0000_0000  -> out = X, valid = 0   (no request)
//
// INTERVIEW TALKING POINTS
//  - PRIORITY ENCODER vs ENCODER vs DECODER:
//      * Decoder       : 1 of N output asserted, based on log2(N)-bit code.
//      * Plain encoder : assumes exactly ONE input bit is hot; behavior is
//                        undefined if more than one is. Cheap.
//      * Priority enc. : works for ANY input — picks the highest-set bit.
//                        Costs more logic, but is what you actually need
//                        when multiple requests can arrive simultaneously
//                        (interrupt controllers, arbiters, leading-zero
//                        detectors for floating-point normalization).
//
//  - Why `valid` matters: with N inputs all zero, "the highest set index"
//    is meaningless. The valid bit prevents downstream logic from acting
//    on garbage. Many real bugs come from designs that omit this signal.
//
//  - `casez` allows '?' wildcards in case items, which makes a priority
//    encoder very readable for small N. For wide N, the for-loop style
//    scales better and is what synthesis tools optimize best.
//
//  - The for-loop idiom below is the CANONICAL "find leading 1" pattern.
//    Iterating from MSB downward and continuously overwriting `out` means
//    the LAST assignment that fires wins — but because we OR in the index
//    only when that bit is set and earlier (higher) bits were not, the
//    final output is the highest set index. Walk through it carefully —
//    this idiom appears constantly in real RTL.
//==============================================================================

module priority_encoder #(
    parameter int N = 8                                   // input width
)(
    input  logic [N-1:0]            in,
    output logic [$clog2(N)-1:0]    out,                  // index of highest-set bit
    output logic                    valid                 // 1 iff any bit set
);

    // Quick valid: OR-reduction. Returns 1 if ANY bit of `in` is set.
    // The `|` prefix is the "reduction OR" operator (also `&`, `^`, etc.).
    assign valid = |in;

    // --------------- Style A: for-loop "find highest set" ----------------
    // This is the production-quality form. Loop from LSB (i=0) up to MSB
    // (i=N-1); whenever in[i] is set, overwrite `out` with i. After the
    // loop, `out` holds the index of the LAST (== highest) set bit.
    //
    // Inside `always_comb`, the loop is fully UNROLLED at elaboration —
    // it produces a tree of comparators / muxes, not a sequential loop.
    always_comb begin
        out = '0;                                         // default avoids latch
        for (int i = 0; i < N; i++) begin
            if (in[i]) out = i[$clog2(N)-1:0];
        end
    end

    // --------------- Style B: casez with '?' wildcards (N=4 example) -----
    // Useful to mention in interview to show you know it exists. Reads
    // like a truth table but doesn't scale beyond ~8 inputs:
    //
    //     always_comb begin
    //         casez (in)                                  // N=4
    //             4'b1???: out = 2'd3;
    //             4'b01??: out = 2'd2;
    //             4'b001?: out = 2'd1;
    //             4'b0001: out = 2'd0;
    //             default: out = 2'd0;
    //         endcase
    //     end
    //
    // The `priority case` SV keyword is the modern equivalent: it tells
    // the tool the cases must be evaluated top-to-bottom (like an if/else
    // chain) and warns if none match.
    // --------------------------------------------------------------------

endmodule
