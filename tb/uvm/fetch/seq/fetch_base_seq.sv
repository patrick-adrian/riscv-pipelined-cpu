class fetch_base_seq extends uvm_sequence #(fetch_txn);

    `uvm_object_utils(fetch_base_seq)
    `uvm_declare_p_sequencer(fetch_sequencer)

    function new(string name = "fetch_base_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_fatal("FETCH/SEQ", "fetch_base_seq::body() must be overridden")
    endtask

    protected task assert_reset();
        p_sequencer.assert_reset();
    endtask

    protected task deassert_reset();
        p_sequencer.deassert_reset();
    endtask

    protected function bit reset_is_asserted();
        return p_sequencer.get_reset_asserted();
    endfunction

    protected task wait_cycles(int cycles);
        if (p_sequencer == null || p_sequencer.vif == null) begin
            `uvm_fatal("FETCH/SEQ/VIF", "fetch sequence requires a sequencer with a valid virtual interface")
        end

        repeat (cycles) @(posedge p_sequencer.vif.clk);
    endtask

    protected task apply_reset(int cycles = 1);
        assert_reset();
        wait_cycles(cycles);
        deassert_reset();
    endtask

endclass
