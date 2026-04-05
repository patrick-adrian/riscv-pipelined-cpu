class ds_obs;

    int          cycle;
    logic        tb_valid;
    logic        reset;
    logic        stall;
    logic        flush;
    logic [31:0] instr_fi;
    logic [31:0] pc_fi;
    logic [31:0] pc_plus4_fi;
    logic [31:0] pred_pc_target_fi;
    logic        pc_src_pred_fi;
    logic        valid;

    logic [31:0] instr_de;
    logic [6:0]  op_de;
    logic [2:0]  imm_src;
    logic [31:0] imm_ext_de;

    logic [4:0]  rd_de;
    logic [4:0]  rs1_de;
    logic [4:0]  rs2_de;
    logic [2:0]  funct3_de;
    logic [6:0]  funct7_de;

    logic [31:0] pc_de;
    logic [31:0] pc_plus4_de;
    logic [31:0] pred_pc_target_de;
    logic        pc_src_pred_de;
    logic [11:0] csr_addr_de;

    function void display(string prefix = "MON");
        $display("[CYCLE %0d] %s: tb_valid=%0b valid=%0b instr=%h op=%07b imm_src=%03b imm=%h",
                 cycle, prefix, tb_valid, valid, instr_de, op_de, imm_src, imm_ext_de);
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
        bit         have_prev = 1'b0;
        int         cycle_count = 0;
        logic       prev_tb_valid;
        logic       prev_reset;
        logic       prev_stall;
        logic       prev_flush;
        logic [31:0] prev_instr_fi;
        logic [31:0] prev_pc_fi;
        logic [31:0] prev_pc_plus4_fi;
        logic [31:0] prev_pred_pc_target_fi;
        logic       prev_pc_src_pred_fi;

        forever begin
            @(posedge vif.clk);
            #1ps;

            if (have_prev) begin
                ds_obs obs = new();

                obs.cycle             = cycle_count;
                obs.tb_valid          = prev_tb_valid;
                obs.reset             = prev_reset;
                obs.stall             = prev_stall;
                obs.flush             = prev_flush;
                obs.instr_fi          = prev_instr_fi;
                obs.pc_fi             = prev_pc_fi;
                obs.pc_plus4_fi       = prev_pc_plus4_fi;
                obs.pred_pc_target_fi = prev_pred_pc_target_fi;
                obs.pc_src_pred_fi    = prev_pc_src_pred_fi;
                obs.valid             = vif.valid_de;
                obs.instr_de          = vif.instr_de;
                obs.op_de             = vif.op_de;
                obs.imm_src           = vif.imm_src;
                obs.imm_ext_de        = vif.imm_ext_de;
                obs.rd_de             = vif.rd_de;
                obs.rs1_de            = vif.rs1_de;
                obs.rs2_de            = vif.rs2_de;
                obs.funct3_de         = vif.funct3_de;
                obs.funct7_de         = vif.funct7_de;
                obs.pc_de             = vif.pc_de;
                obs.pc_plus4_de       = vif.pc_plus4_de;
                obs.pred_pc_target_de = vif.pred_pc_target_de;
                obs.pc_src_pred_de    = vif.pc_src_pred_de;
                obs.csr_addr_de       = vif.csr_addr_de;

                mbx.put(obs);
                num_sampled++;
                cycle_count++;
            end

            prev_tb_valid          = vif.tb_valid;
            prev_reset             = vif.reset;
            prev_stall             = vif.stall;
            prev_flush             = vif.flush;
            prev_instr_fi          = vif.instr_fi;
            prev_pc_fi             = vif.pc_fi;
            prev_pc_plus4_fi       = vif.pc_plus4_fi;
            prev_pred_pc_target_fi = vif.pred_pc_target_fi;
            prev_pc_src_pred_fi    = vif.pc_src_pred_fi;
            have_prev              = 1'b1;
        end
    endtask

endclass
