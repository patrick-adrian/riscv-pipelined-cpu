class fetch_reset_seq extends uvm_sequence;

    `uvm_object_utils(fetch_reset_seq)

    virtual fetch_if vif;

    function new(string name = "fetch_reset_seq");
        super.new(name);
    endfunction

    task body();
        if (!uvm_config_db#(virtual fetch_if)::get(null, "", "vif", vif)) begin
            `uvm_fatal("RESET_SEQ", "virtual interface not found")
        end

        vif.reset <= 1'b1;
        `uvm_info("FETCH/RST", "assert reset", UVM_MEDIUM)
        repeat (5) @(posedge vif.clk);

        vif.reset <= 1'b0;
        `uvm_info("FETCH/RST", "deassert reset", UVM_MEDIUM)
        @(posedge vif.clk);
    endtask

endclass
