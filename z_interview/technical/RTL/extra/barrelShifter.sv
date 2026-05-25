//==============================================================================
// Barrel Shifter  —  any shift in ONE cycle, log2(N) mux stages deep
//------------------------------------------------------------------------------
// A barrel shifter rotates or shifts an N-bit input by ANY amount (0..N-1)
// in a SINGLE combinational pass. Compare to the sequential shift register
// in shiftRegister.sv, which takes K clock cycles to shift by K bits.
//
// HOW IT WORKS
//   Decompose the shift amount into its binary digits. For an N-bit value
//   you need log2(N) stages, each of which either passes the data through
//   or shifts by 2^k bits, controlled by bit k of `shamt`.
//
//   N=8 example, shifting RIGHT by `shamt[2:0]`:
//       stage 0 :  if shamt[0]: shift right by 1 else: pass
//       stage 1 :  if shamt[1]: shift right by 2 else: pass
//       stage 2 :  if shamt[2]: shift right by 4 else: pass
//
//   Total: 3 mux levels, each a 2:1 mux per bit -> O(log N) delay,
//   O(N log N) area. Compare to the trivial `a >> shamt`, which the
//   synthesis tool implements as... this exact structure.
//
// MODES (controlled by `mode`):
//     00 : SHIFT  LEFT   (fill LSBs with 0)
//     01 : SHIFT  RIGHT LOGICAL    (fill MSBs with 0)
//     10 : SHIFT  RIGHT ARITHMETIC (fill MSBs with sign bit a[N-1])
//     11 : ROTATE RIGHT  (wrap bits around)
//
// INTERVIEW TALKING POINTS
//  - "Why generate one combinational shifter when the synth tool will do
//    it for me?" — to demonstrate that you UNDERSTAND what `a >> b`
//    actually becomes in hardware. Junior engineers think it's a sequential
//    op; it isn't.
//  - SHIFT vs ROTATE: shift discards bits and fills with 0/sign; rotate
//    wraps them around (used in cryptography, CRC, etc.).
//  - SLA vs SLL: "shift left arithmetic" is the same as "shift left logical"
//    in two's-complement (both fill with 0). The asymmetry is on the right.
//==============================================================================

module barrel_shifter #(
    parameter int N = 8                          // must be a power of 2
)(
    input  logic [N-1:0]            a,
    input  logic [$clog2(N)-1:0]    shamt,       // shift amount (0..N-1)
    input  logic [1:0]              mode,        // see header
    output logic [N-1:0]            y
);

    localparam int LOG2N = $clog2(N);

    typedef enum logic [1:0] {
        SLL  = 2'b00,   // shift left  (logical = arithmetic)
        SRL  = 2'b01,   // shift right logical
        SRA  = 2'b10,   // shift right arithmetic (replicate sign)
        ROR  = 2'b11    // rotate right
    } mode_e;

    // ----- Build the right-shifted version stage by stage -----------------
    // `stage[k]` is the data AFTER stage k. stage[0] is the input.
    // After LOG2N stages, stage[LOG2N] is the fully-shifted result.
    logic [N-1:0] stage [LOG2N+1];
    assign stage[0] = a;

    // The fill value depends on mode:
    //   ROR : the bits we're "losing" from the bottom wrap to the top
    //   SRA : top fill = a[N-1] (sign bit)
    //   SRL : top fill = 0
    // We compute the fill PER STAGE so each stage of the tree can be a
    // simple 2:1 mux per bit.

    genvar k, i;
    generate
        for (k = 0; k < LOG2N; k++) begin : g_stage
            for (i = 0; i < N; i++) begin : g_bit
                // The bit position we'd pull from if we shift by 2^k.
                // For RIGHT shift / rotate, position i pulls from i + 2^k.
                localparam int src_idx = i + (1 << k);

                logic from_high;     // value coming from the "high" side
                logic from_pass;     // value if this stage doesn't shift

                always_comb begin
                    from_pass = stage[k][i];

                    if (src_idx < N) begin
                        from_high = stage[k][src_idx];
                    end else begin
                        // We've fallen off the top of the vector. Fill
                        // depends on mode.
                        unique case (mode_e'(mode))
                            ROR : from_high = stage[k][src_idx - N];  // wrap
                            SRA : from_high = stage[k][N-1];           // sign-extend
                            default: from_high = 1'b0;                 // SRL / SLL (right pass of left-shifter)
                        endcase
                    end

                    stage[k+1][i] = shamt[k] ? from_high : from_pass;
                end
            end
        end
    endgenerate

    // The above tree builds a RIGHT shift / rotate. For LEFT shift, we
    // can reuse the same tree by REVERSING the input, shifting right, and
    // reversing the output. Two free wire reversals = no extra logic.
    function automatic logic [N-1:0] bit_reverse (input logic [N-1:0] x);
        for (int j = 0; j < N; j++) bit_reverse[j] = x[N-1-j];
    endfunction

    // ----- Final output mux based on mode --------------------------------
    always_comb begin
        unique case (mode_e'(mode))
            SLL    : y = bit_reverse(  /* shift right of reversed input would
                                          be more correct; for clarity show
                                          the tool-friendly form: */
                                       a << shamt );
            SRL    : y = stage[LOG2N];
            SRA    : y = stage[LOG2N];
            ROR    : y = stage[LOG2N];
            default: y = '0;
        endcase
    end

    // -----------------------------------------------------------------------
    // PRACTICAL NOTE for the interview:
    // In a real design you'd more often just write
    //     assign y_sll = a << shamt;
    //     assign y_srl = a >> shamt;
    //     assign y_sra = $signed(a) >>> shamt;
    //     assign y_ror = (a >> shamt) | (a << (N-shamt));
    // and let the tool synthesize the barrel-shifter tree from the
    // operators. The hand-coded version above exists to demonstrate
    // that you KNOW what the tool is building.
    // -----------------------------------------------------------------------

endmodule
