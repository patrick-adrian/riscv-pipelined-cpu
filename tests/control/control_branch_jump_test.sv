`include "instr_macros.sv"

class control_branch_jump_test extends control_base_test;

    function new(virtual control_if vif, control_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset(2);

        // B-type: BEQ
        send_txn("BEQ",
                 `B_TYPE_OP,
                 `F3_BEQ,
                 7'b0000000);

        // J-type: JAL
        send_txn("JAL",
                 `JAL_OP,
                 3'b000,
                 7'b0000000);

        report_and_finish();
    endtask

endclass
