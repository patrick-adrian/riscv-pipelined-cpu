class fetch_seq_item extends uvm_sequence_item;

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

    constraint pc_src_dist {
        pc_src dist {
            0 := 40,   // PC+4 normal flow
            1 := 30,   // branch
            2 := 20,   // jump / target
            3 := 10    // reserved / edge
        };
    }

    constraint stall_behavior {
        stall dist {0 := 80, 1 := 20};
    }

    constraint pc_target_ex_valid_when_branch {
        (pc_src == 1) -> (pc_target_ex != 32'h0);
    }

    constraint pc_plus4_ex_valid_when_jump {
        (pc_src == 2) -> (pc_plus4_ex != 32'h0);
    }

    constraint pred_pc_target_valid_when_jump {
        (pc_src == 3) -> (pred_pc_target != 32'h0);
    }

    `uvm_object_utils_begin(fetch_seq_item)
        `uvm_field_int(pc_src, UVM_DEFAULT)
        `uvm_field_int(stall, UVM_DEFAULT)
        `uvm_field_int(pc_target_ex, UVM_DEFAULT)
        `uvm_field_int(pc_plus4_ex, UVM_DEFAULT)
        `uvm_field_int(pred_pc_target, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "fetch_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("pc_src=%0d stall=%0b pc_target_ex=%08h pc_plus4_ex=%08h pred_pc_target=%08h",
                         pc_src, stall, pc_target_ex, pc_plus4_ex, pred_pc_target);
    endfunction

endclass
