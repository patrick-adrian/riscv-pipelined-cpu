class ds_base_test;

    protected virtual ds_if vif;
    protected ds_env       env;

    function new(virtual ds_if vif, ds_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    virtual task run();
        $fatal(1, "ds_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.wait_for_completion();
        env.report_results();
    endtask

endclass
