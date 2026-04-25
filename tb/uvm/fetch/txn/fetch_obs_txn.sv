class fetch_obs_txn extends uvm_sequence_item;

    // Raw cycle snapshot captured by the passive monitor.
    int unsigned       cycle;
    logic              reset;
    logic [1:0]        pc_src;
    logic              stall;
    logic [31:0]       pc_target_ex;
    logic [31:0]       pc_plus4_ex;
    logic [31:0]       pred_pc_target;
    logic [31:0]       pc;
    logic [31:0]       pc_plus4;

    `uvm_object_utils_begin(fetch_obs_txn)
        `uvm_field_int(cycle, UVM_DEFAULT)
        `uvm_field_int(reset, UVM_DEFAULT)
        `uvm_field_int(pc_src, UVM_DEFAULT)
        `uvm_field_int(stall, UVM_DEFAULT)
        `uvm_field_int(pc_target_ex, UVM_DEFAULT)
        `uvm_field_int(pc_plus4_ex, UVM_DEFAULT)
        `uvm_field_int(pred_pc_target, UVM_DEFAULT)
        `uvm_field_int(pc, UVM_DEFAULT)
        `uvm_field_int(pc_plus4, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "fetch_obs_txn");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("cycle=%0d reset=%0b pc_src=%0d stall=%0b pc_target_ex=%08h pc_plus4_ex=%08h pred_pc_target=%08h pc=%08h pc_plus4=%08h",
                         cycle, reset, pc_src, stall, pc_target_ex,
                         pc_plus4_ex, pred_pc_target, pc, pc_plus4);
    endfunction

endclass
