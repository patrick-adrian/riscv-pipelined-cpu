class control_txn;

    int          id;
    string       instr_name;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    function void display();
        $display("[TIME %0t] DRV TXN[%0d]: name=%0s op=%07b f3=%03b f7=%07b",
                 $time, id, instr_name, opcode, funct3, funct7);
    endfunction

endclass


class control_driver;

    virtual control_if vif;
    mailbox #(control_txn) mbx;
    mailbox #(int)         mon_trig;
    int num_sent = 0;

    localparam time INPUT_SETTLE = 1ps;
    localparam time INTER_TXN_GAP = 1ns;

    function new(virtual control_if vif,
                 mailbox #(control_txn) mbx,
                 mailbox #(int) mon_trig);
        this.vif      = vif;
        this.mbx      = mbx;
        this.mon_trig = mon_trig;
    endfunction

    task run();
        control_txn txn;

        forever begin
            mbx.get(txn);

            vif.opcode = txn.opcode;
            vif.funct3 = txn.funct3;
            vif.funct7 = txn.funct7;
            vif.txn_id = txn.id;

            txn.display();
            num_sent++;

            // Let combinational logic settle before the monitor samples.
            #(INPUT_SETTLE);
            mon_trig.put(txn.id);

            // Small gap before the next transaction.
            #(INTER_TXN_GAP);
        end
    endtask

endclass
