class fetch_branch_test extends fetch_base_test;

    `uvm_component_utils(fetch_branch_test)

    function new(string name = "fetch_branch_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function fetch_base_seq create_sequence();
        return fetch_branch_seq::type_id::create("seq");
    endfunction

endclass
