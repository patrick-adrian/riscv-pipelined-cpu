class fetch_monitor;

    virtual fetch_if vif;
    mailbox #(logic [31:0]) mbx;
    mailbox #(int)          drv_done_mbx;

    function new(virtual fetch_if vif,
                 mailbox #(logic [31:0]) mbx,
                 mailbox #(int)          drv_done_mbx);
        this.vif = vif;
        this.mbx = mbx;
        this.drv_done_mbx = drv_done_mbx;
    endfunction

    task run();
        forever begin
            int dummy;
            // Wait for the driver to apply the next transaction's inputs.
            drv_done_mbx.get(dummy);

            // Sample the DUT PC on the next fetch posedge.
            @(vif.cb);
            #1ps;
            mbx.put(vif.pc);
        end
    endtask

endclass

