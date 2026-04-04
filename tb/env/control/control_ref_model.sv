`include "control_macros.sv"
`include "instr_macros.sv"

class control_ref_model;

    typedef struct packed {
        logic [2:0] imm_src;
        logic [2:0] result_src;
        logic [1:0] branch_op;
        logic       alu_src;
        logic       pc_base_src;
        logic       reg_write;
        logic       mem_write;
        logic       csr_we;
        logic [3:0] alu_control;
        logic [2:0] width_src;
        logic [1:0] csr_control;
        logic       csr_src;
    } control_exp_t;

    static function automatic control_signals_t to_control_signals(
        input control_exp_t exp
    );
        control_signals_t ctrl;

        ctrl.imm_src     = exp.imm_src;
        ctrl.result_src  = exp.result_src;
        ctrl.branch_op   = exp.branch_op;
        ctrl.alu_src     = exp.alu_src;
        ctrl.pc_base_src = exp.pc_base_src;
        ctrl.reg_write   = exp.reg_write;
        ctrl.mem_write   = exp.mem_write;
        ctrl.csr_we      = exp.csr_we;
        ctrl.alu_control = exp.alu_control;
        ctrl.width_src   = exp.width_src;
        ctrl.csr_control = exp.csr_control;
        ctrl.csr_src     = exp.csr_src;

        return ctrl;
    endfunction

    static function automatic logic [2:0] expected_width(input logic [2:0] funct3);
        case (funct3)
            `F3_WORD:   return `WIDTH_32;
            `F3_HALF:   return `WIDTH_16S;
            `F3_BYTE:   return `WIDTH_8S;
            `F3_HALF_U: return `WIDTH_16U;
            `F3_BYTE_U: return `WIDTH_8U;
            default:    return `WIDTH_32;
        endcase
    endfunction

    static function automatic logic [3:0] expected_alu_process(
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        case (funct3)
            `F3_SLT:      return `ALU_SLT;
            `F3_SLTU:     return `ALU_SLTU;
            `F3_OR:       return `ALU_OR;
            `F3_XOR:      return `ALU_XOR;
            `F3_AND:      return `ALU_AND;
            `F3_SLL:      return `ALU_SLL;
            `F3_ADD_SUB:  return (opcode[5] && funct7[5]) ? `ALU_SUB : `ALU_ADD;
            `F3_SRL_SRA:  return funct7[5] ? `ALU_SRA : `ALU_SRL;
            default:      return 4'b0;
        endcase
    endfunction

    static function automatic void decode_csr(
        input  logic [2:0] funct3,
        output logic [1:0] csr_control,
        output logic       csr_src
    );
        casez (funct3)
            3'b?01: csr_control = `CSR_PASS;
            3'b?10: csr_control = `CSR_SET;
            3'b?11: csr_control = `CSR_CLEAR;
            default: csr_control = `CSR_NA;
        endcase

        casez (funct3)
            3'b0??: csr_src = `CSR_SRC_REG;
            3'b1??: csr_src = `CSR_SRC_IMM;
            default: csr_src = `CSR_SRC_NA;
        endcase
    endfunction

    static function automatic control_exp_t decode_expected(
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        control_exp_t exp;

        // Defaults represent an unsupported opcode.
        exp.imm_src     = `NA_EXT;
        exp.result_src  = `RESULT_ALU;
        exp.branch_op   = `NON_BRANCH;
        exp.alu_src     = `ALU_SRC_WD;
        exp.pc_base_src = `PC_BASE_NA;
        exp.reg_write   = `NO_WRITE_REG;
        exp.mem_write   = `NO_WRITE_MEM;
        exp.csr_we      = `NO_WRITE_CSR;
        exp.alu_control = `ALU_ADD;
        exp.width_src   = `WIDTH_32;
        decode_csr(funct3, exp.csr_control, exp.csr_src);

        unique case (opcode)
            `R_TYPE_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `NA_EXT;
                exp.alu_src     = `ALU_SRC_WD;
                exp.result_src  = `RESULT_ALU;
                exp.alu_control = expected_alu_process(opcode, funct3, funct7);
            end

            `I_TYPE_ALU_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `I_EXT;
                exp.alu_src     = `ALU_SRC_IMM;
                exp.result_src  = `RESULT_ALU;
                exp.alu_control = expected_alu_process(opcode, funct3, funct7);
            end

            `I_TYPE_LOAD_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `I_EXT;
                exp.alu_src     = `ALU_SRC_IMM;
                exp.result_src  = `RESULT_MEM_DATA;
                exp.alu_control = `ALU_ADD;
                exp.width_src   = expected_width(funct3);
            end

            `S_TYPE_OP: begin
                exp.imm_src     = `S_EXT;
                exp.alu_src     = `ALU_SRC_IMM;
                exp.mem_write   = `WRITE_MEM;
                exp.result_src  = `RESULT_ALU;
                exp.alu_control = `ALU_ADD;
                exp.width_src   = expected_width(funct3);
            end

            `B_TYPE_OP: begin
                exp.imm_src     = `B_EXT;
                exp.branch_op   = `BRANCH;
                exp.pc_base_src = `PC_BASE_PC;
                exp.alu_control = `ALU_SUB;
            end

            `JAL_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `J_EXT;
                exp.branch_op   = `JUMP;
                exp.pc_base_src = `PC_BASE_PC;
                exp.result_src  = `RESULT_PCPLUS4;
                exp.alu_control = `ALU_ADD;
            end

            `JALR_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `I_EXT;
                exp.branch_op   = `JUMP;
                exp.pc_base_src = `PC_BASE_SRCA;
                exp.result_src  = `RESULT_PCPLUS4;
                exp.alu_control = `ALU_ADD;
            end

            `LUI_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `U_EXT;
                exp.result_src  = `RESULT_IMM_EXT;
                exp.alu_control = `ALU_ADD;
            end

            `AUIPC_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `U_EXT;
                exp.result_src  = `RESULT_PCTARGET;
                exp.pc_base_src = `PC_BASE_PC;
                exp.alu_control = `ALU_ADD;
            end

            `CSR_OP: begin
                exp.reg_write   = `WRITE_REG;
                exp.imm_src     = `CSR_EXT;
                exp.result_src  = `RESULT_CSR;
                exp.csr_we      = `WRITE_CSR;
                exp.alu_control = `ALU_ADD;
            end

            default: begin
            end
        endcase

        return exp;
    endfunction

    static function automatic control_exp_t decode_expected_instr(
        input logic [31:0] instr
    );
        return decode_expected(instr[6:0], instr[14:12], instr[31:25]);
    endfunction

    static function automatic control_signals_t invalid_cycle_expected();
        return to_control_signals(decode_expected(7'b0, 3'b000, 7'b0000000));
    endfunction

    static function automatic string instruction_type(
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        if (opcode == `R_TYPE_OP && funct3 == `F3_ADD_SUB && funct7 == `FUNCT7_ADD_SRL) return "ADD";
        if (opcode == `R_TYPE_OP && funct3 == `F3_ADD_SUB && funct7 == `FUNCT7_SUB_SRA) return "SUB";
        if (opcode == `I_TYPE_ALU_OP && funct3 == `F3_ADD_SUB) return "ADDI";
        if (opcode == `I_TYPE_LOAD_OP && funct3 == `F3_WORD) return "LW";
        if (opcode == `S_TYPE_OP && funct3 == `F3_WORD) return "SW";
        if (opcode == `B_TYPE_OP && funct3 == `F3_BEQ) return "BEQ";
        if (opcode == `LUI_OP) return "LUI";
        if (opcode == `JAL_OP) return "JAL";
        if (opcode == `JALR_OP) return "JALR";
        if (opcode == `AUIPC_OP) return "AUIPC";
        if (opcode == `CSR_OP) return "CSR";
        return "UNKNOWN";
    endfunction

endclass
