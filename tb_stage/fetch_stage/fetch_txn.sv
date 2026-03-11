class fetch_txn;

    int id;

    rand logic [1:0]  pc_src;
    rand logic        stall;
    rand logic [31:0] pc_target_ex;
    rand logic [31:0] pc_plus4_ex;
    rand logic [31:0] pred_pc_target;

    function void display();
        $display("DRV TXN[%0d]: src=%0d stall=%0b ex_t=%h ex_p4=%h pred=%h",
                  id, pc_src, stall, pc_target_ex,
                  pc_plus4_ex, pred_pc_target);
    endfunction

endclass