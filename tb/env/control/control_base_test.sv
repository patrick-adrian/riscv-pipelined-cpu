class control_base_test;

    protected virtual control_if vif;
    protected control_env env;

    function new(virtual control_if vif, control_env env);
        this.vif = vif;
        this.env = env;
    endfunction

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

    task apply_reset(int cycles = 3);
        assert_reset();
        repeat (cycles) @(posedge vif.clk);
        deassert_reset();
    endtask

    task send_txn(
        input string name,
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        control_txn t = new();
        t.cycle_name = name;
        t.valid      = 1'b1;
        t.instr      = control_txn::encode_instr(opcode, funct3, funct7);
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
