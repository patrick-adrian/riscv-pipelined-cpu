class fetch_monitor;

    virtual fetch_if vif;
    mailbox #(logic [31:0]) mbx;

    function new(virtual fetch_if vif,
                 mailbox #(logic [31:0]) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
            mbx.put(vif.pc);
        end
    endtask

endclass