class fetch_txn extends uvm_sequence_item;

    rand logic [1:0]  pc_src;
    rand logic        stall;
    rand logic [31:0] pc_target_ex;
    rand logic [31:0] pc_plus4_ex;
    rand logic [31:0] pred_pc_target;

    constraint pc_align {
        pc_target_ex[1:0]   == 2'b00;
        pc_plus4_ex[1:0]    == 2'b00;
        pred_pc_target[1:0] == 2'b00;
    }

    `uvm_object_utils_begin(fetch_txn)
        `uvm_field_int(pc_src, UVM_DEFAULT)
        `uvm_field_int(stall, UVM_DEFAULT)
        `uvm_field_int(pc_target_ex, UVM_DEFAULT)
        `uvm_field_int(pc_plus4_ex, UVM_DEFAULT)
        `uvm_field_int(pred_pc_target, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "fetch_txn");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("pc_src=%0d stall=%0b pc_target_ex=%08h pc_plus4_ex=%08h pred_pc_target=%08h",
                         pc_src, stall, pc_target_ex, pc_plus4_ex, pred_pc_target);
    endfunction

endclass
