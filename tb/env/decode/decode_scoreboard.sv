`include "control_macros.sv"

class decode_scoreboard;

    virtual decode_if vif;
    mailbox #(decode_txn) drv_mbx;
    mailbox #(decode_obs) mon_mbx;

    // Expected contents of decode_stage's internal pipeline register.
    logic [31:0] exp_instr;
    logic [31:0] exp_pc;
    logic [31:0] exp_pc_plus4;
    logic [31:0] exp_pred_pc_target;
    logic        exp_pc_src_pred;
    logic        exp_valid;

    int num_checked = 0;
    int mismatch_count = 0;

    function new(virtual decode_if vif,
                 mailbox #(decode_txn) drv_mbx,
                 mailbox #(decode_obs) mon_mbx);
        this.vif     = vif;
        this.drv_mbx = drv_mbx;
        this.mon_mbx = mon_mbx;

        exp_instr         = '0;
        exp_pc             = '0;
        exp_pc_plus4      = '0;
        exp_pred_pc_target= '0;
        exp_pc_src_pred   = '0;
        exp_valid         = 1'b0;
    endfunction

    function automatic logic [31:0] imm_extend_model(
        input logic [31:7] instr_i,
        input logic [2:0]  imm_src_i
    );
        begin
            case (imm_src_i)
                `I_EXT:     imm_extend_model = {{20{instr_i[31]}}, instr_i[31:20]};
                `S_EXT:     imm_extend_model = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
                `B_EXT:     imm_extend_model = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
                `J_EXT:     imm_extend_model = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
                `U_EXT:     imm_extend_model = {instr_i[31:12], 12'b0};
                `CSR_EXT:   imm_extend_model = {27'b0, instr_i[19:15]};
                default:    imm_extend_model = 32'b0;
            endcase
        end
    endfunction

    task run();
        decode_txn txn;
        decode_obs obs;

        logic [31:0] exp_imm_ext;
        logic         pc_src_pred_mismatch;
        logic         valid_mismatch;
        logic         instr_mismatch;
        logic         imm_mismatch;
        logic         pc_mismatch;
        logic         pc_plus4_mismatch;
        logic         pred_target_mismatch;
        logic         derived_fields_mismatch;
        logic         funct7_bit5_mismatch;

        forever begin
            drv_mbx.get(txn);

            // Monitor runs continuously, so match using the injected TB tag.
            do begin
                mon_mbx.get(obs);
            end while (obs.txn_tag != txn.id);

            // Update expected registered state exactly as decode_stage's flop does.
            if (txn.reset || txn.flush) begin
                exp_instr          = '0;
                exp_pc              = '0;
                exp_pc_plus4       = '0;
                exp_pred_pc_target = '0;
                exp_pc_src_pred    = 1'b0;
                exp_valid          = 1'b0;
            end else if (!txn.stall) begin
                exp_instr          = txn.instr_fi_i;
                exp_pc             = txn.pc_fi_i;
                exp_pc_plus4      = txn.pc_plus4_fi_i;
                exp_pred_pc_target = txn.pred_pc_target_fi;
                exp_pc_src_pred    = txn.pc_src_pred_fi;
                exp_valid          = 1'b1;
            end
            // else: stall => hold previous exp_* values

            derived_fields_mismatch = 1'b0;

            pc_src_pred_mismatch = (exp_pc_src_pred !== obs.pc_src_pred_de_o);
            valid_mismatch       = (exp_valid !== obs.valid_de_o);
            instr_mismatch       = (exp_instr !== obs.instr_de_o);
            pc_mismatch          = (exp_pc !== obs.pc_de_o);
            pc_plus4_mismatch   = (exp_pc_plus4 !== obs.pc_plus4_de_o);
            pred_target_mismatch= (exp_pred_pc_target !== obs.pred_pc_target_de_o);

            // Immediate is combinational w.r.t. current imm_src_de_i input.
            exp_imm_ext = imm_extend_model(exp_instr[31:7], txn.imm_src_de_i);
            imm_mismatch = (exp_imm_ext !== obs.imm_ext_de_o);

            derived_fields_mismatch |= (obs.csr_addr_de_o !== exp_instr[31:20]);
            derived_fields_mismatch |= (obs.rd_de_o       !== exp_instr[11:7]);
            derived_fields_mismatch |= (obs.rs1_de_o      !== exp_instr[19:15]);
            derived_fields_mismatch |= (obs.rs2_de_o      !== exp_instr[24:20]);
            derived_fields_mismatch |= (obs.op_de_o       !== exp_instr[6:0]);
            derived_fields_mismatch |= (obs.funct3_de_o   !== exp_instr[14:12]);

            // RTL only assigns funct7_de_o[5]; ignore other bits.
            funct7_bit5_mismatch = (obs.funct7_de_o[5] !== exp_instr[30]);

            if (pc_src_pred_mismatch || valid_mismatch || instr_mismatch || imm_mismatch ||
                pc_mismatch || pc_plus4_mismatch || pred_target_mismatch ||
                derived_fields_mismatch || funct7_bit5_mismatch) begin
                mismatch_count++;
                $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: MISMATCH",
                         $time, obs.cycle, txn.id);
                $display("  obs:   valid=%0b instr=%h imm=%h pc=%h pc+4=%h pred=%h pc_src_pred=%0b",
                         obs.valid_de_o, obs.instr_de_o, obs.imm_ext_de_o, obs.pc_de_o,
                         obs.pc_plus4_de_o, obs.pred_pc_target_de_o, obs.pc_src_pred_de_o);
                $display("  exp:   valid=%0b instr=%h imm=%h pc=%h pc+4=%h pred=%h pc_src_pred=%0b\n",
                         exp_valid, exp_instr, exp_imm_ext, exp_pc, exp_pc_plus4,
                         exp_pred_pc_target, exp_pc_src_pred);
            end else begin
                $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: PASS\n",
                         $time, obs.cycle, txn.id);
            end

            num_checked++;
        end
    endtask

endclass

