class decode_base_test;

    protected virtual decode_if vif;
    protected decode_env       env;

    function new(virtual decode_if vif, decode_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    virtual task run();
        $fatal(1, "decode_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.wait_for_completion();
        env.report_results();
    endtask

endclass

