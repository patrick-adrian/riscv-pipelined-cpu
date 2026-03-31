`timescale 1ns / 1ps
//==============================================================//
//  Module:       decode_slice_assertions
//  File:         decode_slice_assertions.sv
//  Description:  Lightweight structural assertions for decode slice:
//                - field extraction bit slicing
//                - immediate generation by immediate type
//                - X/Z protection on key outputs
//                - simple stability check
//==============================================================//

`include "control_macros.sv"

module decode_slice_assertions (
    input logic        clk,
    input logic        reset,
    input logic        valid,
    input logic [31:0] instr,
    input logic [2:0]  imm_src,
    input logic [6:0]  opcode,
    input logic [4:0]  rd,
    input logic [2:0]  funct3,
    input logic [4:0]  rs1,
    input logic [4:0]  rs2,
    input logic [6:0]  funct7,
    input logic [31:0] imm
);

    // Local reference for immediate extraction. This keeps immediate assertions
    // concise and avoids duplicating temporal logic.
    function automatic logic [31:0] expected_imm (
        input logic [31:0] instr_i,
        input logic [2:0]  imm_src_i
    );
        case (imm_src_i)
            `I_EXT: expected_imm = {{20{instr_i[31]}}, instr_i[31:20]};
            `S_EXT: expected_imm = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            `B_EXT: expected_imm = {{20{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
            `U_EXT: expected_imm = {instr_i[31:12], 12'b0};
            `J_EXT: expected_imm = {{12{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
            default: expected_imm = 32'b0;
        endcase
    endfunction

    //--------------------------------------------------------------------------
    // 1) Field extraction: decode outputs must match instruction bit slices.
    //--------------------------------------------------------------------------
    property p_opcode_slice;
        @(posedge clk) disable iff (reset)
        valid |-> (opcode == instr[6:0]);
    endproperty
    assert property (p_opcode_slice)
        else $error("[decode_slice_assertions] opcode mismatch: opcode=%b instr[6:0]=%b", opcode, instr[6:0]);

    property p_rd_slice;
        @(posedge clk) disable iff (reset)
        valid |-> (rd == instr[11:7]);
    endproperty
    assert property (p_rd_slice)
        else $error("[decode_slice_assertions] rd mismatch: rd=%b instr[11:7]=%b", rd, instr[11:7]);

    property p_funct3_slice;
        @(posedge clk) disable iff (reset)
        valid |-> (funct3 == instr[14:12]);
    endproperty
    assert property (p_funct3_slice)
        else $error("[decode_slice_assertions] funct3 mismatch: funct3=%b instr[14:12]=%b", funct3, instr[14:12]);

    property p_rs1_slice;
        @(posedge clk) disable iff (reset)
        valid |-> (rs1 == instr[19:15]);
    endproperty
    assert property (p_rs1_slice)
        else $error("[decode_slice_assertions] rs1 mismatch: rs1=%b instr[19:15]=%b", rs1, instr[19:15]);

    property p_rs2_slice;
        @(posedge clk) disable iff (reset)
        valid |-> (rs2 == instr[24:20]);
    endproperty
    assert property (p_rs2_slice)
        else $error("[decode_slice_assertions] rs2 mismatch: rs2=%b instr[24:20]=%b", rs2, instr[24:20]);

    property p_funct7_slice;
        @(posedge clk) disable iff (reset)
        valid |-> (funct7[5] == instr[30]);
    endproperty
    assert property (p_funct7_slice)
        else $error("[decode_slice_assertions] funct7 mismatch: funct7=%b instr[30]=%b", funct7[5], instr[30]);

    //--------------------------------------------------------------------------
    // 2) Immediate correctness: only check when the selected type is active.
    //--------------------------------------------------------------------------
    property p_imm_matches_selected_type;
        @(posedge clk) disable iff (reset)
        (valid && (imm_src inside {`I_EXT, `S_EXT, `B_EXT, `U_EXT, `J_EXT}))
        |-> (imm == expected_imm(instr, imm_src));
    endproperty
    assert property (p_imm_matches_selected_type)
        else $error("[decode_slice_assertions] imm mismatch: imm_src=%03b instr=%h imm=%h exp=%h",
                    imm_src, instr, imm, expected_imm(instr, imm_src));

    //--------------------------------------------------------------------------
    // 3) No unknowns on key outputs when the instruction is valid.
    //--------------------------------------------------------------------------
    property p_outputs_known_when_valid;
        @(posedge clk) disable iff (reset)
        valid |-> !$isunknown({opcode, rd, rs1, rs2, funct3, funct7[5], imm});
    endproperty
    assert property (p_outputs_known_when_valid)
        else $error("[decode_slice_assertions] X/Z detected on decode outputs while valid=1");

    //--------------------------------------------------------------------------
    // 4) Lightweight stability: stable instruction and imm_src implies stable
    //    extracted fields and immediate in the next sampled cycle.
    //--------------------------------------------------------------------------
    property p_outputs_stable_when_inputs_stable;
        @(posedge clk) disable iff (reset)
        (valid && $stable(instr) && $stable(imm_src))
        |-> $stable({opcode, rd, rs1, rs2, funct3, funct7, imm});
    endproperty
    assert property (p_outputs_stable_when_inputs_stable)
        else $error("[decode_slice_assertions] decode outputs changed despite stable instr/imm_src");

endmodule
