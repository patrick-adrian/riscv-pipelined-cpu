`include "instr_macros.sv"

module instr_mem_model #(
    parameter int DEPTH = 64
) (
    input  logic [31:0]            pc_i,
    output logic [31:0]            instr_o,
    fetch_decode_control_if        prog_if
);

    always_comb begin
        if (pc_i[31:2] >= DEPTH)
            instr_o = `NOP_INSTR;
        else
            instr_o = prog_if.program_mem[pc_i[31:2]];
    end

endmodule
