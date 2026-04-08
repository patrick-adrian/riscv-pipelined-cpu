`timescale 1ns / 1ps
//==============================================================//
//  Module:       control_assertions
//  File:         control_assertions.sv
//  Description:  Bound combinational assertions for control_unit.
//                Checks:
//                - opcode-to-main-control mapping
//                - ALU, width, and CSR decode outputs
//                - X/Z protection for known inputs
//                - a few high-value cross-signal invariants
//==============================================================//

`include "instr_macros.sv"
`include "control_macros.sv"

module control_assertions (
    input logic [6:0] op_de,
    input logic [2:0] funct3_de,
    input logic [6:0] funct7_de,

    input logic [2:0] imm_src_de,
    input logic [2:0] result_src_de,
    input logic [1:0] branch_op_de,
    input logic       alu_src_de,
    input logic       pc_base_src_de,
    input logic       reg_write_de,
    input logic       mem_write_de,
    input logic       csr_we_de,
    input logic [3:0] alu_control_de,
    input logic [2:0] width_src_de,
    input logic [1:0] csr_control_de,
    input logic       csr_src_de
);

    typedef struct packed {
        logic [2:0] imm_src;
        logic [2:0] result_src;
        logic [1:0] branch_op;
        logic       alu_src;
        logic       pc_base_src;
        logic       reg_write;
        logic       mem_write;
        logic       csr_we;
    } main_decode_t;

    main_decode_t main_exp;

    function automatic main_decode_t expected_main_decode(input logic [6:0] opcode);
        main_decode_t exp;

        exp.imm_src     = `NA_EXT;
        exp.result_src  = `RESULT_ALU;
        exp.branch_op   = `NON_BRANCH;
        exp.alu_src     = `ALU_SRC_WD;
        exp.pc_base_src = `PC_BASE_NA;
        exp.reg_write   = `NO_WRITE_REG;
        exp.mem_write   = `NO_WRITE_MEM;
        exp.csr_we      = `NO_WRITE_CSR;

        unique case (opcode)
            `R_TYPE_OP: begin
                exp.reg_write  = `WRITE_REG;
                exp.imm_src    = `NA_EXT;
                exp.alu_src    = `ALU_SRC_WD;
                exp.result_src = `RESULT_ALU;
            end

            `I_TYPE_ALU_OP: begin
                exp.reg_write  = `WRITE_REG;
                exp.imm_src    = `I_EXT;
                exp.alu_src    = `ALU_SRC_IMM;
                exp.result_src = `RESULT_ALU;
            end

            `I_TYPE_LOAD_OP: begin
                exp.reg_write  = `WRITE_REG;
                exp.imm_src    = `I_EXT;
                exp.alu_src    = `ALU_SRC_IMM;
                exp.result_src = `RESULT_MEM_DATA;
            end

            `S_TYPE_OP: begin
                exp.imm_src    = `S_EXT;
                exp.alu_src    = `ALU_SRC_IMM;
                exp.mem_write  = `WRITE_MEM;
                exp.result_src = `RESULT_ALU;
            end

            `B_TYPE_OP: begin
                exp.imm_src     = `B_EXT;
                exp.branch_op   = `BRANCH;
                exp.pc_base_src = `PC_BASE_PC;
            end

            `JAL_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `J_EXT;
                exp.branch_op   = `JUMP;
                exp.pc_base_src = `PC_BASE_PC;
                exp.result_src  = `RESULT_PCPLUS4;
            end

            `JALR_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `I_EXT;
                exp.branch_op   = `JUMP;
                exp.pc_base_src = `PC_BASE_SRCA;
                exp.result_src  = `RESULT_PCPLUS4;
            end

            `LUI_OP: begin
                exp.reg_write  = `WRITE_REG;
                exp.imm_src    = `U_EXT;
                exp.result_src = `RESULT_IMM_EXT;
            end

            `AUIPC_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `U_EXT;
                exp.result_src  = `RESULT_PCTARGET;
                exp.pc_base_src = `PC_BASE_PC;
            end

            `CSR_OP: begin
                exp.reg_write  = `WRITE_REG;
                exp.imm_src    = `CSR_EXT;
                exp.result_src = `RESULT_CSR;
                exp.csr_we     = `WRITE_CSR;
            end

            default: begin
            end
        endcase

        return exp;
    endfunction

    function automatic logic [3:0] expected_alu_process(
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        case (funct3)
            `F3_SLT:     expected_alu_process = `ALU_SLT;
            `F3_SLTU:    expected_alu_process = `ALU_SLTU;
            `F3_OR:      expected_alu_process = `ALU_OR;
            `F3_XOR:     expected_alu_process = `ALU_XOR;
            `F3_AND:     expected_alu_process = `ALU_AND;
            `F3_SLL:     expected_alu_process = `ALU_SLL;
            `F3_ADD_SUB: expected_alu_process = (opcode[5] && funct7[5]) ? `ALU_SUB : `ALU_ADD;
            `F3_SRL_SRA: expected_alu_process = funct7[5] ? `ALU_SRA : `ALU_SRL;
            default:     expected_alu_process = 4'b0000;
        endcase
    endfunction

    function automatic logic [3:0] expected_alu_control(
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        unique case (opcode)
            `R_TYPE_OP,
            `I_TYPE_ALU_OP: expected_alu_control = expected_alu_process(opcode, funct3, funct7);

            `B_TYPE_OP: expected_alu_control = `ALU_SUB;

            default: expected_alu_control = `ALU_ADD;
        endcase
    endfunction

    function automatic logic [2:0] expected_width_src(
        input logic [6:0] opcode,
        input logic [2:0] funct3
    );
        if ((opcode != `I_TYPE_LOAD_OP) && (opcode != `S_TYPE_OP)) begin
            expected_width_src = `WIDTH_32;
        end else begin
            case (funct3)
                `F3_WORD:   expected_width_src = `WIDTH_32;
                `F3_HALF:   expected_width_src = `WIDTH_16S;
                `F3_BYTE:   expected_width_src = `WIDTH_8S;
                `F3_HALF_U: expected_width_src = `WIDTH_16U;
                `F3_BYTE_U: expected_width_src = `WIDTH_8U;
                default:    expected_width_src = `WIDTH_32;
            endcase
        end
    endfunction

    function automatic logic [1:0] expected_csr_control(input logic [2:0] funct3);
        casez (funct3)
            3'b?01:  expected_csr_control = `CSR_PASS;
            3'b?10:  expected_csr_control = `CSR_SET;
            3'b?11:  expected_csr_control = `CSR_CLEAR;
            default: expected_csr_control = `CSR_NA;
        endcase
    endfunction

    function automatic logic expected_csr_src(input logic [2:0] funct3);
        casez (funct3)
            3'b0??:  expected_csr_src = `CSR_SRC_REG;
            3'b1??:  expected_csr_src = `CSR_SRC_IMM;
            default: expected_csr_src = `CSR_SRC_NA;
        endcase
    endfunction

    // Use a zero-delay procedural check so the combinational DUT has settled
    // before assertions fire. This avoids false mismatches and stays xsim-safe.
    always @* begin
        #0;
        main_exp = expected_main_decode(op_de);

        if (!$isunknown({op_de, funct3_de, funct7_de})) begin
            assert (
                !$isunknown({
                    imm_src_de, result_src_de, branch_op_de, alu_src_de,
                    pc_base_src_de, reg_write_de, mem_write_de, csr_we_de,
                    alu_control_de, width_src_de, csr_control_de, csr_src_de
                })
            ) else $error("[control_assertions] X/Z detected on control outputs for known decode inputs");

            assert (
                {imm_src_de, result_src_de, branch_op_de, alu_src_de,
                 pc_base_src_de, reg_write_de, mem_write_de, csr_we_de}
                ===
                {main_exp.imm_src, main_exp.result_src, main_exp.branch_op, main_exp.alu_src,
                 main_exp.pc_base_src, main_exp.reg_write, main_exp.mem_write, main_exp.csr_we}
            ) else $error(
                "[control_assertions] main decode mismatch: op=%b got={imm=%b result=%b branch=%b alu_src=%b pc_base=%b reg_w=%b mem_w=%b csr_we=%b}",
                op_de, imm_src_de, result_src_de, branch_op_de, alu_src_de,
                pc_base_src_de, reg_write_de, mem_write_de, csr_we_de
            );

            assert (alu_control_de === expected_alu_control(op_de, funct3_de, funct7_de))
                else $error(
                    "[control_assertions] ALU control mismatch: op=%b funct3=%b funct7=%b got=%b exp=%b",
                    op_de, funct3_de, funct7_de, alu_control_de,
                    expected_alu_control(op_de, funct3_de, funct7_de)
                );

            assert (width_src_de === expected_width_src(op_de, funct3_de))
                else $error(
                    "[control_assertions] width decode mismatch: op=%b funct3=%b got=%b exp=%b",
                    op_de, funct3_de, width_src_de, expected_width_src(op_de, funct3_de)
                );

            assert (csr_control_de === expected_csr_control(funct3_de))
                else $error(
                    "[control_assertions] CSR control mismatch: funct3=%b got=%b exp=%b",
                    funct3_de, csr_control_de, expected_csr_control(funct3_de)
                );

            assert (csr_src_de === expected_csr_src(funct3_de))
                else $error(
                    "[control_assertions] CSR source mismatch: funct3=%b got=%b exp=%b",
                    funct3_de, csr_src_de, expected_csr_src(funct3_de)
                );

            if (mem_write_de) begin
                assert (
                    (reg_write_de == `NO_WRITE_REG) &&
                    (csr_we_de    == `NO_WRITE_CSR) &&
                    (branch_op_de == `NON_BRANCH)  &&
                    (result_src_de == `RESULT_ALU)
                ) else $error("[control_assertions] store-side control invariant violated");
            end

            if (branch_op_de == `BRANCH) begin
                assert (
                    (pc_base_src_de == `PC_BASE_PC) &&
                    (reg_write_de   == `NO_WRITE_REG) &&
                    (mem_write_de   == `NO_WRITE_MEM) &&
                    (alu_control_de == `ALU_SUB)
                ) else $error("[control_assertions] branch control invariant violated");
            end

            if (branch_op_de == `JUMP) begin
                assert (
                    (reg_write_de  == `WRITE_REG) &&
                    (result_src_de == `RESULT_PCPLUS4)
                ) else $error("[control_assertions] jump control invariant violated");
            end

            if (csr_we_de) begin
                assert (
                    (reg_write_de  == `WRITE_REG) &&
                    (mem_write_de  == `NO_WRITE_MEM) &&
                    (result_src_de == `RESULT_CSR)
                ) else $error("[control_assertions] CSR write control invariant violated");
            end
        end
    end

endmodule
