class control_base_test;

    protected virtual control_if vif;
    protected control_env env;

    function new(virtual control_if vif, control_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    task send_txn(
        input string name,
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        control_txn t = new();
        t.instr_name = name;
        t.opcode     = opcode;
        t.funct3     = funct3;
        t.funct7     = funct7;
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
