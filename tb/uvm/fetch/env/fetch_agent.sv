class fetch_agent extends uvm_agent;

    fetch_sequencer sequencer;
    fetch_driver    driver;
    fetch_monitor   monitor;

    `uvm_component_utils(fetch_agent)

    function new(string name = "fetch_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Always build monitor
        monitor = fetch_monitor::type_id::create("monitor", this);

        // Only build driver + sequencer if active
        if (is_active == UVM_ACTIVE) begin
            sequencer = fetch_sequencer::type_id::create("sequencer", this);
            driver    = fetch_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass