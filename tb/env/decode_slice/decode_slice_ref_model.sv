`include "instr_macros.sv"
`include "control_macros.sv"

class decode_slice_ref_model;

    // Mirrors main_decoder: opcode -> imm_src encoding.
    static function logic [2:0] expected_imm_src(input logic [6:0] opcode);
        case (opcode)
            `R_TYPE_OP:      return `NA_EXT;
            `I_TYPE_ALU_OP:  return `I_EXT;
            `I_TYPE_LOAD_OP: return `I_EXT;
            `JALR_OP:        return `I_EXT;
            `S_TYPE_OP:      return `S_EXT;
            `B_TYPE_OP:      return `B_EXT;
            `JAL_OP:         return `J_EXT;
            `LUI_OP:         return `U_EXT;
            `AUIPC_OP:       return `U_EXT;
            `CSR_OP:         return `CSR_EXT;
            default:         return `NA_EXT;
        endcase
    endfunction

    // Mirrors imm_extend: instruction bits + imm_src -> sign-extended immediate.
    static function logic [31:0] expected_imm_ext(
        input logic [31:7] instr_bits,
        input logic [2:0]  imm_src
    );
        case (imm_src)
            `I_EXT:   return {{20{instr_bits[31]}}, instr_bits[31:20]};
            `S_EXT:   return {{20{instr_bits[31]}}, instr_bits[31:25], instr_bits[11:7]};
            `B_EXT:   return {{20{instr_bits[31]}}, instr_bits[7], instr_bits[30:25], instr_bits[11:8], 1'b0};
            `J_EXT:   return {{12{instr_bits[31]}}, instr_bits[19:12], instr_bits[20], instr_bits[30:21], 1'b0};
            `U_EXT:   return {instr_bits[31:12], 12'b0};
            `CSR_EXT: return {27'b0, instr_bits[19:15]};
            default:  return 32'b0;
        endcase
    endfunction

endclass
