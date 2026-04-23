class fetch_sequencer extends uvm_sequencer #(fetch_seq_item);

    `uvm_component_utils(fetch_sequencer)

    function new(string name = "fetch_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
