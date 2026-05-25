//==============================================================================
// Gray Code Counter
//------------------------------------------------------------------------------
// A Gray code is a binary numbering system where SUCCESSIVE VALUES DIFFER
// IN EXACTLY ONE BIT. This is the defining property and it's why Gray
// codes are essential for CDC (clock-domain crossing) and for any place a
// counter is sampled by something not synchronous to its clock.
//
//   binary    | gray
//   ----------+------
//   000   = 0 | 000
//   001   = 1 | 001
//   010   = 2 | 011        <- only bit 1 changed compared to 001
//   011   = 3 | 010        <- only bit 0 changed compared to 011
//   100   = 4 | 110
//   101   = 5 | 111
//   110   = 6 | 101
//   111   = 7 | 100
//
// WHY ONE-BIT-PER-STEP MATTERS
// ----------------------------------------------------------------------------
// In a regular binary counter, transitioning from 011 -> 100 toggles THREE
// bits SIMULTANEOUSLY. If another clock domain samples that value mid-
// transition (different bits arriving at slightly different times due to
// routing skew), it can see ANY of {011, 010, 000, 100, 110, 111, ...} —
// completely wrong intermediate values. With Gray code, the worst case is
// that the sampler sees either the OLD or the NEW value — never garbage.
//
// This is exactly why ASYNCHRONOUS FIFOs use Gray-coded pointers, and
// why position encoders (rotary encoders) output in Gray code.
//
// CONVERSION FORMULAS (memorize both)
//   binary -> gray :  gray = bin ^ (bin >> 1)
//   gray   -> binary: bin[N-1] = gray[N-1];
//                     for i from N-2 down to 0:  bin[i] = bin[i+1] ^ gray[i]
//                  (equivalent: XOR-scan from the MSB downward)
//
// INTERVIEW TALKING POINTS
//  - "Why store the count in BINARY and convert to Gray on the output?"
//    Two reasons:
//      (1) incrementing a binary counter is a single +1 (cheap); incrementing
//          a Gray counter requires custom logic per stage (expensive).
//      (2) keeping the binary copy means you can do arithmetic / comparisons
//          on it normally, and convert to Gray only for the boundary signal
//          that crosses domains.
//  - "Is `bin ^ (bin >> 1)` really one-bit-different per step?" — Yes. Prove
//    it on a whiteboard for 3 bits; the XOR-with-shifted-self has the
//    property that incrementing the binary value changes exactly one bit
//    of the result.
//==============================================================================

module gray_counter #(
    parameter int WIDTH = 4
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              en,
    output logic [WIDTH-1:0]  bin_count,    // exposed for arithmetic uses
    output logic [WIDTH-1:0]  gray_count    // safe to cross clock domains
);

    // ----- Binary counter (the engine) -----------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)      bin_count <= '0;
        else if (en)     bin_count <= bin_count + 1'b1;
    end

    // ----- Binary -> Gray conversion (combinational, one line) -----------
    // Walk through the formula:
    //     bin     = b3 b2 b1 b0
    //     bin>>1  =  0 b3 b2 b1
    //     XOR     = b3 (b3^b2) (b2^b1) (b1^b0)
    // The MSB is unchanged; every lower bit is the XOR of consecutive
    // binary bits. That's the Gray code.
    assign gray_count = bin_count ^ (bin_count >> 1);

endmodule


//==============================================================================
// Gray -> Binary converter  —  handy companion module
//------------------------------------------------------------------------------
// For each output bit, XOR all the gray bits from MSB down to this position.
// We do that with a `for` loop inside `always_comb`. The loop fully unrolls
// at elaboration into a tree of XORs.
//==============================================================================
module gray_to_binary #(
    parameter int WIDTH = 4
)(
    input  logic [WIDTH-1:0] gray,
    output logic [WIDTH-1:0] bin
);
    always_comb begin
        bin[WIDTH-1] = gray[WIDTH-1];                       // MSB passes straight through
        for (int i = WIDTH-2; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];                    // XOR-scan downward
        end
    end
endmodule
