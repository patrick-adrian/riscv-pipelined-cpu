class fetch_reset_test extends fetch_base_test;

    `uvm_component_utils(fetch_reset_test)

    function new(string name = "fetch_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fetch_base_seq pre_reset_seq;
        fetch_base_seq post_reset_seq;

        pre_reset_seq  = fetch_reset_recovery_seq::type_id::create("pre_reset_seq");
        post_reset_seq = fetch_reset_recovery_seq::type_id::create("post_reset_seq");

        phase.raise_objection(this);
        run_reset_sequence();
        pre_reset_seq.start(env.agent.sequencer);
        run_reset_sequence();
        post_reset_seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass
