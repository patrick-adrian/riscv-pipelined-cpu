class decode_sequencer;

    mailbox #(decode_txn) mbx_seq_to_drv;
    mailbox #(decode_txn) mbx_seq_to_scb;

    int txn_id = 0;
    int num_txns_sent = 0;

    function new(mailbox #(decode_txn) mbx_seq_to_drv,
                 mailbox #(decode_txn) mbx_seq_to_scb);
        this.mbx_seq_to_drv = mbx_seq_to_drv;
        this.mbx_seq_to_scb = mbx_seq_to_scb;
    endfunction

    task send(decode_txn txn);
        txn.id = txn_id++;
        mbx_seq_to_drv.put(txn);
        mbx_seq_to_scb.put(txn);
        num_txns_sent++;
    endtask

endclass

