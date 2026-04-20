class fetch_reset_test extends fetch_base_test;

    `uvm_component_utils(fetch_reset_test)

    function new(string name = "fetch_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function fetch_base_seq create_sequence();
        return fetch_reset_seq::type_id::create("seq");
    endfunction

endclass
