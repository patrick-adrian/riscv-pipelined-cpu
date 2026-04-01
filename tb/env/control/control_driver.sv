class control_txn;

    int          id;
    string       instr_name;
    logic        reset;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    function void display(int cycle);
        $display("[TIME %0t][CYCLE %0d] DRV TXN[%0d]: name=%0s reset=%0b op=%07b f3=%03b f7=%07b",
                 $time, cycle, id, instr_name, reset, opcode, funct3, funct7);
    endfunction

endclass


class control_driver;

    virtual control_if vif;
    mailbox #(control_txn) mbx;
    int num_sent = 0;

    function new(virtual control_if vif, mailbox #(control_txn) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        control_txn txn;

        forever begin
            mbx.get(txn);
            @(negedge vif.clk);

            vif.reset  <= txn.reset;
            vif.opcode <= txn.opcode;
            vif.funct3 <= txn.funct3;
            vif.funct7 <= txn.funct7;
            vif.txn_id <= txn.id;

            txn.display(vif.cycle);
            num_sent++;
        end
    endtask

endclass
