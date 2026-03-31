class ds_obs;

    int          txn_id;
    int          cycle;
    logic        reset;
    logic        stall;
    logic        flush;
    logic        valid;

    logic [31:0] instr_de;
    logic [6:0]  op_de;
    logic [2:0]  imm_src;
    logic [31:0] imm_ext_de;

    logic [4:0]  rd_de;
    logic [4:0]  rs1_de;
    logic [4:0]  rs2_de;
    logic [2:0]  funct3_de;

    function void display(string prefix = "MON");
        $display("[CYCLE %0d] %s: txn_id=%0d valid=%0b instr=%h op=%07b imm_src=%03b imm=%h",
                 cycle, prefix, txn_id, valid, instr_de, op_de, imm_src, imm_ext_de);
    endfunction

endclass


class ds_monitor;

    virtual ds_if vif;
    mailbox #(ds_obs) mbx;
    int num_sampled = 0;

    function new(virtual ds_if vif, mailbox #(ds_obs) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            ds_obs obs = new();

            @(vif.cb);
            #1ps;

            obs.txn_id    = vif.txn_id;
            obs.cycle     = vif.cycle;
            obs.reset     = vif.reset;
            obs.stall     = vif.stall;
            obs.flush     = vif.flush;
            obs.valid     = vif.valid_de;
            obs.instr_de  = vif.instr_de;
            obs.op_de     = vif.op_de;
            obs.imm_src   = vif.imm_src;
            obs.imm_ext_de = vif.imm_ext_de;
            obs.rd_de     = vif.rd_de;
            obs.rs1_de    = vif.rs1_de;
            obs.rs2_de    = vif.rs2_de;
            obs.funct3_de = vif.funct3_de;

            mbx.put(obs);
            num_sampled++;
        end
    endtask

endclass
