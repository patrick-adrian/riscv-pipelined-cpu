`include "instr_macros.sv"

class control_reset_test extends control_base_test;

    function new(virtual control_if vif, control_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset(3);

        // Inject reset again after issuing a valid instruction so the monitor
        // and scoreboard see reset bubbles in the middle of activity.
        send_txn("ADD_BEFORE_RESET",
                 `R_TYPE_OP,
                 `F3_ADD_SUB,
                 `FUNCT7_ADD_SRL);

        env.wait_until_checked(1);
        assert_reset();

        // Send valid instructions with back-to-back traffic during reset.
        send_txn("LW_DURING_RESET",
                 `I_TYPE_LOAD_OP,
                 `F3_WORD,
                 7'b0000000);
        send_txn("SW_DURING_RESET",
                 `S_TYPE_OP,
                 `F3_WORD,
                 7'b0000000);

        env.wait_until_checked(3);
        deassert_reset();

         // Finish with back-to-back valid traffic after reset deassertion.
        send_txn("LW_AFTER_RESET",
                 `I_TYPE_LOAD_OP,
                 `F3_WORD,
                 7'b0000000);
        send_txn("SW_AFTER_RESET",
                 `S_TYPE_OP,
                 `F3_WORD,
                 7'b0000000);

        report_and_finish();
    endtask

endclass
