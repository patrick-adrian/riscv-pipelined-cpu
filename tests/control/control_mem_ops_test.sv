`include "instr_macros.sv"

class control_mem_ops_test extends control_base_test;

    function new(virtual control_if vif, control_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset(2);

        // I-type load: LW
        send_txn("LW",
                 `I_TYPE_LOAD_OP,
                 `F3_WORD,
                 7'b0000000,
                 1'b0);

        // S-type store: SW
        send_txn("SW",
                 `S_TYPE_OP,
                 `F3_WORD,
                 7'b0000000,
                 1'b0);

        report_and_finish();
    endtask

endclass
