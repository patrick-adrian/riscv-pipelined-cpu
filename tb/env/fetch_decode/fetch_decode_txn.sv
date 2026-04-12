class fetch_decode_txn;

    string       cycle_name;
    logic [1:0]  pc_src;
    logic        stall_fi;
    logic        stall_de;
    logic        flush_de;
    logic [31:0] pc_target_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] pred_pc_target_fi;
    logic        pc_src_pred_fi;

    function new();
        cycle_name         = "CTRL";
        pc_src             = 2'b00;
        stall_fi           = 1'b0;
        stall_de           = 1'b0;
        flush_de           = 1'b0;
        pc_target_ex       = 32'h0;
        pc_plus4_ex        = 32'h0;
        pred_pc_target_fi  = 32'h0;
        pc_src_pred_fi     = 1'b0;
    endfunction

    function void display(int cycle, time log_time);
        $display("[TIME %0t][CYCLE %0d] DRV: name=%0s pc_src=%0d stall_fi=%0b stall_de=%0b flush_de=%0b target=%08h pred=%08h",
                 log_time, cycle, cycle_name, pc_src, stall_fi, stall_de, flush_de,
                 pc_target_ex, pred_pc_target_fi);
    endfunction

endclass
