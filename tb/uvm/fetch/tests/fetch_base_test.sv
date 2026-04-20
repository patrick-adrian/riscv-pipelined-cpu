class fetch_base_test extends uvm_test;

    fetch_env env;

    `uvm_component_utils(fetch_base_test)

    function new(string name = "fetch_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fetch_env::type_id::create("env", this);
    endfunction

    virtual function fetch_base_seq create_sequence();
        return null;
    endfunction

    protected task run_reset_sequence();
        fetch_reset_seq reset_seq;

        reset_seq = fetch_reset_seq::type_id::create("reset_seq");
        reset_seq.start(null);
    endtask

    task run_phase(uvm_phase phase);
        fetch_base_seq seq;

        seq = create_sequence();
        if (seq == null) begin
            `uvm_fatal("FETCH/TEST", "Derived test must return a concrete fetch sequence")
        end

        phase.raise_objection(this);
        run_reset_sequence();
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass
