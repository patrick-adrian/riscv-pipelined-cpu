class fetch_obs;

    int txn_tag;
    int cycle;

    logic        reset;
    logic [1:0]  pc_src;
    logic        stall;

    logic [31:0] pc_target_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] pred_pc_target;

    logic [31:0] pc;
    logic [31:0] pc_plus4;

    function void display(string prefix = "MON");
        $display("[CYCLE %0d] %0s: tag=%0d reset=%0b src=%0d stall=%0b pc=%h pc_plus4=%h ex_t=%h ex_p4=%h pred=%h",
                 cycle, prefix, txn_tag, reset, pc_src, stall, pc, pc_plus4,
                 pc_target_ex, pc_plus4_ex, pred_pc_target);
    endfunction

    function bit matches_txn(fetch_txn txn);
        return (txn_tag        ==  txn.id) &&
               (pc_src         === txn.pc_src) &&
               (stall          === txn.stall) &&
               (pc_target_ex   === txn.pc_target_ex) &&
               (pc_plus4_ex    === txn.pc_plus4_ex) &&
               (pred_pc_target === txn.pred_pc_target);
    endfunction

endclass
