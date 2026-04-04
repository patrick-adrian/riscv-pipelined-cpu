class control_txn;

    string       cycle_name;
    bit          valid;
    logic [31:0] instr;

    static function automatic logic [31:0] encode_instr(
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        logic [31:0] instr_word;

        instr_word         = 32'h0;
        instr_word[6:0]    = opcode;
        instr_word[14:12]  = funct3;
        instr_word[31:25]  = funct7;
        return instr_word;
    endfunction

    function void display(int cycle);
        $display("[TIME %0t] DRV CYCLE[%0d]: name=%0s valid=%0b instr=%08h op=%07b f3=%03b f7=%07b",
                 $time, cycle, cycle_name, valid, instr, instr[6:0], instr[14:12], instr[31:25]);
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
        bit         have_txn;
        int         cycle_count = 0;

        forever begin
            @(posedge vif.clk);
            cycle_count++;

            if (vif.reset) begin
                vif.valid <= 1'b0;
                continue;
            end

            have_txn = mbx.try_get(txn);
            if (!have_txn) begin
                vif.valid <= 1'b0;
                continue;
            end

            vif.valid <= txn.valid;
            if (txn.valid)
                vif.instr <= txn.instr;

            txn.display(cycle_count);
            num_sent++;
        end
    endtask

endclass
