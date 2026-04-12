`include "instr_macros.sv"

class integrated_monitor;

    localparam int INVALID_FLOW_ID = -1;

    virtual fetch_decode_control_if vif;
    mailbox #(integrated_obs)       mbx;
    int                             num_sampled = 0;

    function new(virtual fetch_decode_control_if vif,
                 mailbox #(integrated_obs) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        integrated_obs obs;
        int            cycle_count         = 0;
        int            next_flow_id        = 1;
        int            active_fetch_flow_id= INVALID_FLOW_ID;
        int            pending_flow_id     = INVALID_FLOW_ID;
        int            held_flow_id        = INVALID_FLOW_ID;
        int            current_flow_id;

        forever begin
            @(posedge vif.clk);
            cycle_count++;
            #1ps;

            if (active_fetch_flow_id == INVALID_FLOW_ID)
                active_fetch_flow_id = next_flow_id++;

            current_flow_id = INVALID_FLOW_ID;
            if (vif.reset || vif.flush_de) begin
                current_flow_id = INVALID_FLOW_ID;
            end else if (vif.stall_de) begin
                current_flow_id = held_flow_id;
            end else begin
                current_flow_id = pending_flow_id;
            end

            obs                  = new();
            obs.cycle            = cycle_count;
            obs.reset            = vif.reset;
            obs.stall_fi         = vif.stall_fi;
            obs.stall_de         = vif.stall_de;
            obs.flush_de         = vif.flush_de;
            obs.is_new_txn       = vif.is_new_txn;
            obs.is_bubble        = (!vif.valid_d) || (vif.instr_d == `NOP_INSTR);
            obs.flow_id          = vif.valid_d ? current_flow_id : INVALID_FLOW_ID;
            obs.pc_src           = vif.pc_src;
            obs.pc_target_ex     = vif.pc_target_ex;
            obs.pc_plus4_ex      = vif.pc_plus4_ex;
            obs.pred_pc_target_fi= vif.pred_pc_target_fi;
            obs.pc_src_pred_fi   = vif.pc_src_pred_fi;
            obs.pc               = vif.pc_f;
            obs.pc_next          = vif.pc_next_f;
            obs.instr_f          = vif.instr_f;
            obs.instr_d          = vif.instr_d;
            obs.imm              = vif.imm_d;
            obs.rs1              = vif.rs1_d;
            obs.rs2              = vif.rs2_d;
            obs.rd               = vif.rd_d;
            obs.valid_d          = vif.valid_d;
            obs.opcode           = vif.opcode_d;
            obs.funct3           = vif.funct3_d;
            obs.funct7           = vif.funct7_d;
            obs.ctrl             = vif.sample_ctrl();

            $display("[CYCLE %0d] PC=%08h INSTR_F=%08h INSTR_D=%08h FLOW=%0d",
                     obs.cycle, obs.pc, obs.instr_f, obs.instr_d, obs.flow_id);

            mbx.put(obs);
            num_sampled++;

            held_flow_id    = current_flow_id;
            pending_flow_id = active_fetch_flow_id;

            if (vif.reset || vif.stall_fi)
                active_fetch_flow_id = active_fetch_flow_id;
            else
                active_fetch_flow_id = next_flow_id++;
        end
    endtask

endclass
