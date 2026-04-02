class decode_txn;

    int id;

    rand logic        reset;
    rand logic        stall;
    rand logic        flush;

    rand logic        pc_src_pred_fi;
    rand logic [31:0] instr_fi_i;
    rand logic [31:0] pc_fi_i;
    rand logic [31:0] pc_plus4_fi_i;
    rand logic [31:0] pred_pc_target_fi;
    rand logic [2:0]  imm_src_de_i;

    constraint pc_align {
        pc_fi_i[1:0]         == 2'b00;
        pc_plus4_fi_i[1:0]  == 2'b00;
        pred_pc_target_fi[1:0] == 2'b00;
    }

    function void display(int cycle);
        $display("[TIME %0t][CYCLE %0d] DRV TXN[%0d]: reset=%0b stall=%0b flush=%0b imm_src=%0d",
                 $time, cycle, id, reset, stall, flush, imm_src_de_i);
        $display("  pc_src_pred=%0b instr=%h pc=%h pc_plus4=%h pred_target=%h",
                 pc_src_pred_fi, instr_fi_i, pc_fi_i, pc_plus4_fi_i, pred_pc_target_fi);
    endfunction

endclass

