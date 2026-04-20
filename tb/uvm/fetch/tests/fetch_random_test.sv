class fetch_random_test extends fetch_base_test;

    `uvm_component_utils(fetch_random_test)

    function new(string name = "fetch_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function fetch_base_seq create_sequence();
        return fetch_random_seq::type_id::create("seq");
    endfunction

endclass
