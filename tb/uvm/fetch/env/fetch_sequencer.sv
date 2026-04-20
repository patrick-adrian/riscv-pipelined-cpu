class fetch_sequencer extends uvm_sequencer #(fetch_txn);

    virtual fetch_if vif;
    protected bit    reset_asserted;

    `uvm_component_utils(fetch_sequencer)

    function new(string name = "fetch_sequencer", uvm_component parent = null);
        super.new(name, parent);
        reset_asserted = 1'b0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fetch_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("FETCH/SEQ/VIF", "virtual interface must be set for fetch_sequencer")
        end
    endfunction

    task assert_reset();
        reset_asserted = 1'b1;
    endtask

    task deassert_reset();
        reset_asserted = 1'b0;
    endtask

    function bit get_reset_asserted();
        return reset_asserted;
    endfunction

endclass
