class fetch_base_seq extends uvm_sequence #(fetch_seq_item);

    `uvm_object_utils(fetch_base_seq)

    function new(string name = "fetch_base_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_fatal("FETCH/SEQ", "fetch_base_seq::body() must be overridden")
    endtask

endclass
