//==============================================================================
// Universal Shift Register
//------------------------------------------------------------------------------
// A shift register is a chain of flip-flops where each FF feeds the next.
// "Universal" means it supports all four common operations selected by `mode`:
//
//     mode  operation       use case
//     ----  --------------- ----------------------------------------
//     00    HOLD            keep current value (clock enable disabled)
//     01    SHIFT LEFT      e.g., multiply-by-2, serializer MSB-first
//     10    SHIFT RIGHT     e.g., divide-by-2, serializer LSB-first
//     11    PARALLEL LOAD   load `d_par` in one cycle (PISO / PIPO)
//
// INTERVIEW TALKING POINTS
//  - This is the canonical "shift register" interview question. Variants
//    (SISO / SIPO / PISO / PIPO) all collapse into the universal form.
//  - WHY non-blocking (<=)? Inside a sequential always block, blocking (=)
//    would let earlier statements OVERWRITE the values the later statements
//    are supposed to read, breaking the "all flops sample old values
//    simultaneously" rule. With <=, the RHS is evaluated for ALL flops
//    before ANY LHS is updated — exactly mirroring real hardware.
//  - Concatenation `{ser_in, q[WIDTH-1:1]}` is the textbook RTL idiom for
//    "shift right by one, inject ser_in at the MSB". It compiles to a
//    simple wire rearrangement — there is NO shifter logic, just routing.
//  - Reset value is parameterized so the same module can hold non-zero
//    init data (handy for LFSRs and seed-loaded registers).
//==============================================================================

module shift_register #(
    parameter int               WIDTH     = 8,
    parameter logic [WIDTH-1:0] RESET_VAL = '0
)(
    input  logic              clk,
    input  logic              rst_n,            // async, active-low

    input  logic [1:0]        mode,             // 00=hold, 01=SL, 10=SR, 11=load
    input  logic              ser_in_left,      // serial input for shift-right (enters MSB)
    input  logic              ser_in_right,     // serial input for shift-left  (enters LSB)
    input  logic [WIDTH-1:0]  d_par,            // parallel load data

    output logic [WIDTH-1:0]  q,                // parallel output (always visible)
    output logic              ser_out_left,     // MSB tap (serial output for shift-left)
    output logic              ser_out_right     // LSB tap (serial output for shift-right)
);

    // Encode the mode bits as a `typedef enum` so cases are self-documenting
    // and waveform viewers display "SHIFT_LEFT" instead of "01".
    typedef enum logic [1:0] {
        HOLD        = 2'b00,
        SHIFT_LEFT  = 2'b01,
        SHIFT_RIGHT = 2'b10,
        LOAD_PAR    = 2'b11
    } mode_e;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= RESET_VAL;
        end else begin
            unique case (mode_e'(mode))
                HOLD       : q <= q;                              // explicit hold (synth-friendly)
                SHIFT_LEFT : q <= {q[WIDTH-2:0], ser_in_right};   // <<1, fill LSB
                SHIFT_RIGHT: q <= {ser_in_left,  q[WIDTH-1:1]};   // >>1, fill MSB
                LOAD_PAR   : q <= d_par;
                default    : q <= q;                              // defensive; unreachable
            endcase
        end
    end

    // Combinational taps. These are JUST wires picking off bits of `q` —
    // no extra logic, no extra flops. The "serial out" of a shift register
    // is whichever bit will leave the chain next.
    assign ser_out_left  = q[WIDTH-1]; // bit shifted out on a left shift
    assign ser_out_right = q[0];       // bit shifted out on a right shift

endmodule
