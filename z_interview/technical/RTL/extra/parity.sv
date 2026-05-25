//==============================================================================
// Parity Generator and Checker
//------------------------------------------------------------------------------
// Parity is the simplest form of error detection. You add ONE extra bit to
// a data word so that the total number of 1s is either EVEN (even parity)
// or ODD (odd parity), depending on convention. On the receiving side, you
// recompute parity and compare — if it doesn't match, AT LEAST one bit
// flipped in flight.
//
//   even parity bit:  p_e = XOR-reduction of data    (count of 1s incl. p_e is even)
//   odd  parity bit:  p_o = ~(XOR-reduction of data) (count of 1s incl. p_o is odd)
//
// LIMITATIONS (always mention this in an interview):
//   - Detects ANY odd number of bit flips.
//   - MISSES any even number of bit flips (2, 4, 6, ...).
//   - Cannot LOCATE the error. To correct, you need ECC (e.g., Hamming).
//
// USE CASES
//   - UART parity bit, low-end memory bus, simple SPI / I2C extensions.
//   - DDR memory uses ECC instead. Caches often use parity per byte for
//     speed, and ECC for L2/L3 where correction matters.
//
// THE ONE-LINE IMPLEMENTATION
//   `^bus` is the SystemVerilog "XOR reduction" operator. It XORs every
//   bit of `bus` together. That's exactly the parity computation, done
//   in O(log N) gate depth as a balanced XOR tree.
//==============================================================================

module parity_generator #(
    parameter int  WIDTH = 8,
    parameter bit  ODD   = 1'b0           // 0 = even parity, 1 = odd parity
)(
    input  logic [WIDTH-1:0] data,
    output logic             parity_bit
);
    // XOR-reduction in one operator. The tool builds a balanced XOR tree
    // of depth ceil(log2(WIDTH)) gates. For WIDTH=64 that's only 6 levels —
    // very fast.
    //
    // For even parity: we want total #1s in {data, parity_bit} to be even,
    //   so parity_bit equals the XOR of data. (Adding it gives the second
    //   appearance of every 1, making the count even.)
    // For odd parity: invert that.
    assign parity_bit = ODD ? ~(^data) : (^data);
endmodule


module parity_checker #(
    parameter int  WIDTH = 8,
    parameter bit  ODD   = 1'b0
)(
    input  logic [WIDTH-1:0] data,
    input  logic             parity_bit,    // received parity bit
    output logic             error          // 1 if parity mismatch detected
);
    // Recompute what the parity bit SHOULD be, compare to what we got.
    logic expected;
    assign expected = ODD ? ~(^data) : (^data);
    assign error    = (expected != parity_bit);

    // Equivalent compact form (gold-star in an interview):
    //     assign error = ^{data, parity_bit} ^ ODD;
    // because XORing the parity bit back into the data word should give 0
    // for even parity (and 1 for odd parity).
endmodule


//==============================================================================
// Bonus: byte-wise parity for a wide bus  —  common in cache designs
//------------------------------------------------------------------------------
// Real chips often store ONE parity bit per BYTE rather than per word, so
// that any single-bit failure within one byte is detected without needing
// full ECC. Shown here as a `generate` example.
//==============================================================================
module bytewise_parity #(
    parameter int BYTES = 8                   // 8 bytes = 64 data bits + 8 parity
)(
    input  logic [BYTES*8 - 1 : 0] data,
    output logic [BYTES   - 1 : 0] parity     // one bit per byte
);
    genvar b;
    generate
        for (b = 0; b < BYTES; b++) begin : g_byte
            assign parity[b] = ^data[b*8 +: 8];   // ^reduction of one byte
        end
    endgenerate

    // The `[b*8 +: 8]` notation is the SystemVerilog INDEXED PART-SELECT:
    // "starting at bit b*8, select 8 bits going UP". It's the cleanest way
    // to slice a packed array by stride. The reverse direction is `-:`.
endmodule
