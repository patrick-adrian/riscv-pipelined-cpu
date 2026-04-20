class fetch_sequencer extends uvm_sequencer #(fetch_txn);

    virtual fetch_if vif;

    `uvm_component_utils(fetch_sequencer)

    function new(string name = "fetch_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fetch_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("FETCH/SEQ/VIF", "virtual interface must be set for fetch_sequencer")
        end
    endfunction

    task assert_reset();
        if (vif == null) begin
            `uvm_fatal("FETCH/SEQ/VIF", "cannot assert reset without a valid virtual interface")
        end
        vif.reset <= 1'b1;
        `uvm_info("FETCH/RST", "assert reset", UVM_MEDIUM)
    endtask

    task deassert_reset();
        if (vif == null) begin
            `uvm_fatal("FETCH/SEQ/VIF", "cannot deassert reset without a valid virtual interface")
        end
        vif.reset <= 1'b0;
        `uvm_info("FETCH/RST", "deassert reset", UVM_MEDIUM)
    endtask

    function bit get_reset_asserted();
        if (vif == null) begin
            `uvm_fatal("FETCH/SEQ/VIF", "cannot read reset state without a valid virtual interface")
        end
        return vif.reset;
    endfunction

endclass
