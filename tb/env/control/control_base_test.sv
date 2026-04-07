class control_base_test;

    protected virtual control_if vif;
    protected control_env        env;

    function new(virtual control_if vif, control_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    // Canonical reset contract for this clocked TB wrapper:
    // - Drive reset on negedge so it is stable before the next posedge.
    // - Do not constrain the other interface fields while reset is high.
    // - Hold reset high across the requested number of posedges.
    // - Deassert on negedge; tests that want a quiet recovery bubble must drive
    //   those controls explicitly.
    task assert_reset();
        @(negedge vif.clk);
        vif.reset = 1'b1;
        $display("[TIME %0t] RESET ASSERTED", $time);
    endtask

    task deassert_reset();
        @(negedge vif.clk);
        vif.reset = 1'b0;
        $display("[TIME %0t] RESET DEASSERTED", $time);
    endtask

    task pulse_reset(int cycles = 1);
        assert_reset();
        repeat (cycles) @(posedge vif.clk);
        deassert_reset();
    endtask

    task apply_reset(int cycles = 1);
        pulse_reset(cycles);
    endtask

    task send_txn(
        input string name,
        input logic [6:0] op_de,
        input logic [2:0] funct3_de,
        input logic [6:0] funct7_de
    );
        control_txn t = new();
        t.cycle_name = name;
        t.tb_valid   = 1'b1;
        t.instr_de   = control_txn::encode_instr(op_de, funct3_de, funct7_de);
        env.put_txn(t);
    endtask

    virtual task run();
        $fatal(1, "control_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.wait_for_completion();
        env.report_results();
    endtask

endclass
