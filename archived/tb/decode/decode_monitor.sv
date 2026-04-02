class decode_monitor;

    virtual decode_if vif;
    mailbox #(decode_obs) mbx;
    int num_sampled = 0;

    function new(virtual decode_if vif,
                 mailbox #(decode_obs) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            decode_obs obs = new();

            // Synchronize to each decode clock and then sample the raw DUT outputs.
            @(vif.cb);
            #1ps;

            obs.txn_tag            = vif.txn_tag;
            obs.cycle              = vif.cycle;
            obs.reset              = vif.reset;
            obs.stall              = vif.stall;
            obs.flush              = vif.flush;
            obs.imm_src_de_i      = vif.imm_src_de_i;

            obs.instr_de_o         = vif.instr_de_o;
            obs.imm_ext_de_o       = vif.imm_ext_de_o;
            obs.pc_de_o            = vif.pc_de_o;
            obs.pc_plus4_de_o      = vif.pc_plus4_de_o;
            obs.pred_pc_target_de_o = vif.pred_pc_target_de_o;
            obs.csr_addr_de_o      = vif.csr_addr_de_o;
            obs.rd_de_o            = vif.rd_de_o;
            obs.rs1_de_o           = vif.rs1_de_o;
            obs.rs2_de_o           = vif.rs2_de_o;
            obs.op_de_o            = vif.op_de_o;
            obs.funct3_de_o       = vif.funct3_de_o;
            obs.funct7_de_o       = vif.funct7_de_o;
            obs.pc_src_pred_de_o  = vif.pc_src_pred_de_o;
            obs.valid_de_o        = vif.valid_de_o;

            mbx.put(obs);
            num_sampled++;
        end
    endtask

endclass

