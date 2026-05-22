//==============================================================================
// Arithmetic Logic Unit (ALU) — RISC-V RV32I integer subset
//------------------------------------------------------------------------------
// The ALU is the combinational heart of any CPU datapath. Given two operands
// (`a`, `b`) and an operation code (`alu_op`), it produces a single result
// and a set of condition flags used by the branch unit.
//
// We model RV32I's 10 integer ALU ops because the surrounding project is a
// RISC-V pipeline. The same template scales to any ISA.
//
// INTERVIEW TALKING POINTS
//  - The ALU is PURELY COMBINATIONAL — no clock. Its result is latched by
//    the next pipeline register (EX/MEM in a classic 5-stage CPU).
//  - Critical path: typically the adder. Tools build a CLA / Kogge-Stone
//    adder for `a + b`. SUB is implemented as `a + ~b + 1` so we reuse the
//    SAME adder hardware for both — saving area and matching timing.
//  - SLT (Set Less Than) reuses the subtractor: result is just the sign of
//    `a - b`, interpreted as signed. SLTU does the same but unsigned (uses
//    the borrow-out / inverted carry-out instead).
//  - Shift amount in RV32I is the LOW 5 BITS of `b` (the `shamt` field).
//    This is an ISA detail — masking with [4:0] enforces it in hardware.
//  - SRA (arithmetic shift right) needs SIGN EXTENSION of the MSB. We use
//    SV's `>>>` operator on a `$signed()` value to get that for free.
//  - Output flags (`zero`, `negative`, ...) let the branch unit decide
//    BEQ / BNE / BLT / BGE in a single cycle without re-doing the compare.
//==============================================================================

// Encode the operation as a typedef enum. Outside this module you'd put
// this in a shared package (`alu_pkg`) and `import` it. Inlining it here
// keeps the file self-contained for study.
package alu_pkg;
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,   // a + b
        ALU_SUB  = 4'b0001,   // a - b
        ALU_AND  = 4'b0010,   // a & b
        ALU_OR   = 4'b0011,   // a | b
        ALU_XOR  = 4'b0100,   // a ^ b
        ALU_SLL  = 4'b0101,   // a << b[4:0]            (logical left)
        ALU_SRL  = 4'b0110,   // a >> b[4:0]            (logical right, fills 0)
        ALU_SRA  = 4'b0111,   // a >>> b[4:0]           (arithmetic, fills sign)
        ALU_SLT  = 4'b1000,   // signed   (a < b) ? 1 : 0
        ALU_SLTU = 4'b1001    // unsigned (a < b) ? 1 : 0
    } alu_op_e;
endpackage

module alu
    import alu_pkg::*;
#(
    parameter int WIDTH = 32
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  alu_op_e          alu_op,

    output logic [WIDTH-1:0] result,
    output logic             zero,      // result == 0     (used by BEQ/BNE)
    output logic             negative,  // result MSB == 1
    output logic             overflow,  // signed overflow on add/sub
    output logic             carry_out  // carry/borrow from add/sub
);

    // --------------------------------------------------------------------
    // SHARED ADDER / SUBTRACTOR
    //
    // We compute a +/- b ONCE and reuse the result for ADD, SUB, SLT, SLTU,
    // and the branch flags. This is the same trick real CPUs use to keep
    // the ALU compact.
    //
    // Width = WIDTH+1 so the top bit captures the carry-out.
    //   add:  {Cout, sum} = a + b      + 0
    //   sub:  {Cout, sum} = a + ~b + 1   (two's-complement negation of b)
    // --------------------------------------------------------------------
    logic                is_sub;
    logic [WIDTH-1:0]    b_xor;
    logic [WIDTH:0]      add_sub;        // one extra bit for carry-out

    assign is_sub = (alu_op == ALU_SUB) || (alu_op == ALU_SLT) || (alu_op == ALU_SLTU);

    // XOR with `is_sub`: flips every bit of b when we want subtraction.
    // Combined with the `+ is_sub` below, this gives "+1" -> two's-comp negate.
    assign b_xor   = b ^ {WIDTH{is_sub}};
    assign add_sub = {1'b0, a} + {1'b0, b_xor} + {{WIDTH{1'b0}}, is_sub};

    // --------------------------------------------------------------------
    // FLAG GENERATION (from the shared add/sub)
    //
    // Overflow rule (signed add/sub): occurs when the two operands have
    // the same effective sign but the result's sign differs. Equivalently:
    //     ovf = (a_sign == b_eff_sign) && (a_sign != sum_sign)
    // where b_eff is `b` for add and `~b` for sub.
    // --------------------------------------------------------------------
    logic a_sign, b_eff_sign, sum_sign;
    assign a_sign     = a[WIDTH-1];
    assign b_eff_sign = b_xor[WIDTH-1];
    assign sum_sign   = add_sub[WIDTH-1];
    assign overflow   = (a_sign == b_eff_sign) && (a_sign != sum_sign);
    assign carry_out  = add_sub[WIDTH];   // for unsigned: 1=no-borrow on sub

    // --------------------------------------------------------------------
    // SHIFT AMOUNT
    //
    // In RV32I, only the low 5 bits of the second operand are used as the
    // shift amount (since shifting a 32-bit value by >=32 is meaningless).
    // Masking here both implements the ISA and prevents simulator warnings.
    // --------------------------------------------------------------------
    logic [4:0] shamt;
    assign shamt = b[4:0];

    // --------------------------------------------------------------------
    // MAIN RESULT MUX
    //
    // Each case selects the precomputed result for that op. The actual
    // expensive operators (adder, barrel shifter) are built ONCE in the
    // continuous assigns above / below; the case statement is just a mux.
    // --------------------------------------------------------------------
    always_comb begin
        unique case (alu_op)
            ALU_ADD : result = add_sub[WIDTH-1:0];
            ALU_SUB : result = add_sub[WIDTH-1:0];
            ALU_AND : result = a & b;
            ALU_OR  : result = a | b;
            ALU_XOR : result = a ^ b;

            // Logical shifts: SV's `<<` and `>>` are unsigned by default,
            // so SRL correctly fills with zeros.
            ALU_SLL : result = a << shamt;
            ALU_SRL : result = a >> shamt;

            // Arithmetic right shift: `>>>` only sign-extends when the LHS
            // is `signed`. The $signed() cast is what makes the MSB replicate.
            ALU_SRA : result = $signed(a) >>> shamt;

            // SLT / SLTU: emit 1 when a<b, else 0. Reuses the subtractor:
            //   * signed:   look at sum_sign XOR overflow  (handles overflow case)
            //   * unsigned: look at !carry_out             (borrow occurred)
            ALU_SLT : result = {{(WIDTH-1){1'b0}}, (sum_sign ^ overflow)};
            ALU_SLTU: result = {{(WIDTH-1){1'b0}}, ~carry_out};

            default : result = '0;   // safety net; unique-case asserts coverage
        endcase
    end

    // --------------------------------------------------------------------
    // POST-RESULT FLAGS used by the branch unit (BEQ/BNE/BLT/BGE).
    // These look at `result` after the mux, not the raw add_sub, so a
    // logic-op result of 0 also raises `zero` (useful for BEQ x0, ...).
    // --------------------------------------------------------------------
    assign zero     = (result == '0);
    assign negative = result[WIDTH-1];

endmodule
