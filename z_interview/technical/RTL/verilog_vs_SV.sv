//==============================================================================
// Verilog vs SystemVerilog — side-by-side reference for the interview
//------------------------------------------------------------------------------
// This file is NOT meant to elaborate as a single design — it is a tour of
// the differences you should be able to name. Each section shows the
// "old Verilog" way (Verilog-2001), then the SV upgrade, then a one-line
// reason for the change.
//
// QUICK SUMMARY  (good thing to memorize)
//   "Verilog is the language; SystemVerilog is a superset that adds modern
//    types (logic, enum, struct), safer always blocks (always_ff /
//    always_comb / always_latch), assertions (SVA), interfaces, packages,
//    and a full OOP-style verification layer (classes, randomization,
//    constraints, mailboxes, semaphores) which together became UVM."
//
// HISTORY: Verilog (1984) -> Verilog-95 / 2001 / 2005 -> SystemVerilog
//   (2005, 2009, 2012, 2017) -> all merged into IEEE 1800-2017. Most
//   modern shops write SV-2012 with synthesizable subset for RTL.
//==============================================================================


//------------------------------------------------------------------------------
// 1. DATA TYPES — `wire`/`reg` -> `logic`
//------------------------------------------------------------------------------
// Verilog:
//   wire a;       // continuous net (driven by `assign` or module output)
//   reg  b;       // variable (assigned inside an `always` block)
// SystemVerilog:
//   logic a, b;   // ONE type; the tool decides "net or variable" from use
//
// WHY: Beginners constantly confused "reg" with "register". `reg` is just
//      "a variable you write in procedural code" — it might synthesize to
//      a wire, a flop, or a latch. `logic` removes that confusion. A
//      `logic` driven by `assign` becomes a wire; driven by `always_ff`
//      becomes a flop; driven by `always_comb` without full assignment
//      becomes a latch (and the tool will warn).
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 2. ALWAYS BLOCKS — `always @(*)` -> `always_comb` / `always_ff` / `always_latch`
//------------------------------------------------------------------------------
// Verilog:
//   always @(posedge clk or negedge rst_n) ...       // could be flop OR latch
//   always @(*)                            ...       // combinational... maybe
//
// SystemVerilog:
//   always_ff    @(posedge clk or negedge rst_n) ... // tool ERRORS if not a flop
//   always_comb                                  ... // tool ERRORS if a latch infers
//   always_latch                                 ... // explicit latch intent
//
// WHY: Intent becomes part of the code. The synth tool can catch the bug
//      class "I meant combinational but accidentally got a latch" before
//      you even reach simulation. Free safety, no cost.
//------------------------------------------------------------------------------
module sv_alwaysblock_demo (
    input  logic clk, rst_n, a, b,
    output logic y, q
);
    always_comb begin                  // ERRORS if any path leaves y unassigned
        y = a ^ b;
    end
    always_ff @(posedge clk or negedge rst_n) begin   // ERRORS if no posedge
        if (!rst_n) q <= 1'b0;
        else        q <= y;
    end
endmodule


//------------------------------------------------------------------------------
// 3. ENUMERATED STATES — `parameter` constants -> `typedef enum`
//------------------------------------------------------------------------------
// Verilog:
//   parameter IDLE = 2'b00, LOAD = 2'b01, RUN = 2'b10;
//   reg [1:0] state;
//
// SystemVerilog:
//   typedef enum logic [1:0] { IDLE, LOAD, RUN } state_e;
//   state_e state;
//
// WHY: (a) Waveforms display "IDLE" / "RUN" instead of "00".
//      (b) Tool catches typos ("RNU" is undefined) at compile time.
//      (c) `case (state)` is now self-documenting.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 4. CASE STATEMENTS — `case` -> `unique case` / `priority case`
//------------------------------------------------------------------------------
// Verilog:  `case`  -- no guarantees about coverage or overlap.
//
// SystemVerilog:
//   unique   case (x)  -- cases must be MUTUALLY EXCLUSIVE and FULLY COVERED.
//                         Simulator errors if more than one matches or none do.
//   priority case (x)  -- cases evaluated TOP-DOWN like if/else-if; at least
//                         one MUST match. Used for explicit priority logic.
//
// WHY: Encodes intent. Synthesis can build a parallel mux for `unique`
//      vs a priority encoder for `priority`. Simulation catches bugs.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 5. STRUCTS & PACKED ARRAYS — group related signals into one bundle
//------------------------------------------------------------------------------
// Verilog (manual concatenation, error-prone):
//   wire [31:0] instr;
//   wire [6:0]  opcode = instr[6:0];
//   wire [4:0]  rs1    = instr[19:15];
//
// SystemVerilog:
typedef struct packed {
    logic [6:0]  funct7;
    logic [4:0]  rs2;
    logic [4:0]  rs1;
    logic [2:0]  funct3;
    logic [4:0]  rd;
    logic [6:0]  opcode;
} riscv_r_instr_t;     // 32 bits total, named fields, still synthesizable

// WHY: `packed` keeps the struct contiguous in bits (synthesizable). You
//      can pass it across modules in a single port and access named
//      fields without bit-slicing every consumer.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 6. PARAMETERS & TYPE PARAMETERS
//------------------------------------------------------------------------------
// Verilog only had value parameters (`parameter WIDTH = 8`).
// SV adds TYPE parameters:
//
//   module fifo #(parameter type T = logic [7:0], parameter int DEPTH = 16) (...);
//
// WHY: Reusable IP. A FIFO can store any type the user instantiates with.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 7. PACKAGES & IMPORT — sharing definitions across files
//------------------------------------------------------------------------------
// Verilog: copy the same `parameter` block into every file (typo magnet).
// SystemVerilog:
//
//   package cpu_pkg;
//       typedef enum logic [3:0] { ALU_ADD, ALU_SUB, ... } alu_op_e;
//       parameter int XLEN = 32;
//   endpackage
//
//   module foo import cpu_pkg::*; (...);   // now `alu_op_e`, `XLEN` visible
//
// WHY: Single source of truth for shared types/constants. This is how the
//      ALU file in this folder exposes its `alu_op_e`.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 8. INTERFACES — bundle a bus + its modports in one declaration
//------------------------------------------------------------------------------
// Verilog: every AXI module repeats ~30 individual port declarations.
// SystemVerilog:
//
//   interface axi_if;
//       logic        valid, ready;
//       logic [31:0] data;
//       modport master (output valid, data, input  ready);
//       modport slave  (input  valid, data, output ready);
//   endinterface
//
// WHY: Replaces a wall of ports with a single connection. Slightly
//      controversial in pure RTL (some shops avoid them for synthesis
//      portability), but ubiquitous in testbenches.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 9. ASSERTIONS (SVA) — formal statement of design intent
//------------------------------------------------------------------------------
// Verilog has nothing comparable. SystemVerilog adds:
//
//   // immediate assertion (procedural)
//   assert (a != b) else $error("a and b must differ");
//
//   // concurrent assertion (temporal, sampled by a clock)
//   no_double_grant: assert property (
//       @(posedge clk) disable iff (!rst_n)
//       $onehot0({gnt0, gnt1, gnt2})       // at most one grant high
//   ) else $fatal(1, "multiple grants!");
//
// WHY: Encodes invariants right next to the RTL. Tools simulate them as
//      monitors and formal tools can prove them mathematically.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 10. SIZING & BIT-WIDTH UTILITIES
//------------------------------------------------------------------------------
// Verilog: hand-compute log2 with #defines.
// SystemVerilog adds:
//   $clog2(N)    -- ceiling log2, used to size counter widths (synthesizable)
//   $bits(x)     -- number of bits in any expression / typedef
//   $countones(v)-- popcount (synthesizable on modern tools)
//   $onehot(v)   -- exactly one bit set        (typically assertion-only)
//   $onehot0(v)  -- at most one bit set        (typically assertion-only)
//   $isunknown(v)-- any X/Z bits present       (assertion-only)
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 11. PROCEDURAL CONSTRUCTS
//------------------------------------------------------------------------------
// SV adds `for (int i = 0; ...)` with a LOCAL loop variable inside
// always_comb blocks. Verilog required you to declare `integer i;` at
// module scope, which was ugly and bug-prone.
//
// SV also adds `break`, `continue`, `return` inside loops/tasks.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 12. VERIFICATION LAYER (TB-only, NOT synthesizable, but worth naming)
//------------------------------------------------------------------------------
// `class`         object-oriented transactions / drivers / monitors
// `randomize()`   constrained-random stimulus
// `covergroup`    functional coverage collection
// `mailbox`,      message-passing / synchronization
// `semaphore`
// dynamic arrays  `int q[];`            -- resizable at runtime
// queues          `int q[$];`           -- push/pop_back/pop_front
// associative     `int q[string];`      -- like a hash map
// arrays
//
// These are the building blocks of UVM. They will NOT appear in your
// RTL files, but you should be able to name them if asked "what does
// SV give you for verification that Verilog doesn't?".
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// 13. ONE-LINER YOU CAN USE IN INTERVIEW
//------------------------------------------------------------------------------
//   "SystemVerilog is a strict superset of Verilog. For RTL it gives me
//    `logic`, the `always_ff`/`always_comb`/`always_latch` family, enums,
//    packed structs, packages, and assertions — all of which make intent
//    explicit and let the tool catch bugs the older language would let
//    through. For verification it adds OOP, randomization, and coverage,
//    which is what UVM is built on."
//------------------------------------------------------------------------------
