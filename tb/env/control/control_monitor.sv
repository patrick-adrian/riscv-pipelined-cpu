class control_obs;

    int          txn_id;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic [2:0]  imm_src;
    logic [2:0]  result_src;
    logic [1:0]  branch_op;
    logic        alu_src;
    logic        pc_base_src;
    logic        reg_write;
    logic        mem_write;
    logic        csr_we;
    logic [3:0]  alu_control;
    logic [2:0]  width_src;
    logic [1:0]  csr_control;
    logic        csr_src;

endclass


// Fully passive: samples the bus when driver asserts vif.valid (no mailbox handshake).
class control_monitor;

    virtual control_if vif;
    mailbox #(control_obs) mon_mbx;

    int num_sampled = 0;

    function new(virtual control_if vif, mailbox #(control_obs) mon_mbx);
        this.vif     = vif;
        this.mon_mbx = mon_mbx;
    endfunction

    task run();
        forever begin
            wait (vif.valid === 1'b1);
            #0;

            begin
                control_obs obs = new();
                obs.txn_id      = vif.txn_id;
                obs.opcode      = vif.opcode;
                obs.funct3      = vif.funct3;
                obs.funct7      = vif.funct7;
                obs.imm_src     = vif.imm_src;
                obs.result_src  = vif.result_src;
                obs.branch_op   = vif.branch_op;
                obs.alu_src     = vif.alu_src;
                obs.pc_base_src = vif.pc_base_src;
                obs.reg_write   = vif.reg_write;
                obs.mem_write   = vif.mem_write;
                obs.csr_we      = vif.csr_we;
                obs.alu_control = vif.alu_control;
                obs.width_src   = vif.width_src;
                obs.csr_control = vif.csr_control;
                obs.csr_src     = vif.csr_src;

                mon_mbx.put(obs);
                num_sampled++;
            end
        end
    endtask

endclass
