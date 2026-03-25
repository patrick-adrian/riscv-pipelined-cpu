class fetch_base_test;

    protected virtual fetch_if vif;
    protected fetch_env env;

    function new(virtual fetch_if vif, fetch_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    task apply_reset(int cycles = 3);
        vif.reset = 1'b1;
        repeat (cycles) @(posedge vif.clk);
        vif.reset = 1'b0;
        repeat (1) @(posedge vif.clk);
    endtask

    virtual task run();
        $fatal(1, "fetch_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.wait_for_completion();
        env.report_results();
    endtask

endclass
