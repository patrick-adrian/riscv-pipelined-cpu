`include "instr_macros.sv"

class control_basic_instr_test extends control_base_test;

    function new(virtual control_if vif, control_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        // R-type: ADD
        send_txn("ADD",
                 `R_TYPE_OP,
                 `F3_ADD_SUB,
                 `FUNCT7_ADD_SRL);

        // R-type: SUB
        send_txn("SUB",
                 `R_TYPE_OP,
                 `F3_ADD_SUB,
                 `FUNCT7_SUB_SRA);

        // I-type: ADDI
        send_txn("ADDI",
                 `I_TYPE_ALU_OP,
                 `F3_ADD_SUB,
                 `FUNCT7_ADD_SRL);

        // U-type: LUI
        send_txn("LUI",
                 `LUI_OP,
                 3'b000,
                 7'b0000000);

        report_and_finish();
    endtask

endclass
