class control_txn;

    string       cycle_name;
    bit          tb_valid;
    logic [31:0] instr_de;

    static function automatic logic [31:0] encode_instr(
        input logic [6:0] op_de,
        input logic [2:0] funct3_de,
        input logic [6:0] funct7_de
    );
        logic [31:0] instr_word;

        instr_word         = 32'h0;
        instr_word[6:0]    = op_de;
        instr_word[14:12]  = funct3_de;
        instr_word[31:25]  = funct7_de;
        return instr_word;
    endfunction

    function void display(int cycle, time log_time);
        $display("[TIME %0t][CYCLE %0d] DRV: name=%0s tb_valid=%0b instr=%08h op=%07b f3=%03b f7=%07b",
                 log_time, cycle, cycle_name, tb_valid, instr_de,
                 instr_de[6:0], instr_de[14:12], instr_de[31:25]);
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
        time        log_time;

        forever begin
            @(posedge vif.clk);
            cycle_count++;

            have_txn = mbx.try_get(txn);
            if (!have_txn) begin
                vif.tb_valid <= 1'b0;
                vif.instr_de <= 32'h0;
                continue;
            end

            vif.tb_valid <= txn.tb_valid;
            vif.instr_de <= txn.tb_valid ? txn.instr_de : 32'h0;

            log_time = $time;
            txn.display(cycle_count, log_time);
            num_sent++;
        end
    endtask

endclass
