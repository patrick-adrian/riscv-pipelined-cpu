class fetch_sample extends uvm_sequence_item;

    logic [31:0] pc;
    logic [31:0] pc_plus4;

    logic [1:0]  pc_src;
    logic        stall;

    logic [31:0] pc_target_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] pred_pc_target;

    logic        reset;

    `uvm_object_utils(fetch_sample)

    function new(string name = "fetch_sample");
        super.new(name);
    endfunction

endclass