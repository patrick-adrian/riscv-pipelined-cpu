package fetch_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "txn/fetch_seq_item.sv"
    `include "txn/fetch_obs_txn.sv"
    `include "txn/fetch_sample.sv"
    `include "agent/fetch_sequencer.sv"
    `include "agent/fetch_driver.sv"
    `include "agent/fetch_monitor.sv"
    `include "scoreboard/fetch_scoreboard.sv"
    `include "agent/fetch_agent.sv"
    `include "env/fetch_env.sv"

    `include "seq/fetch_base_seq.sv"
    `include "seq/fetch_smoke_seq.sv"
    `include "seq/fetch_branch_seq.sv"
    `include "seq/fetch_pc_increment_seq.sv"
    `include "seq/fetch_stall_seq.sv"
    `include "seq/fetch_reset_seq.sv"
    `include "seq/fetch_reset_recovery_seq.sv"
    `include "seq/fetch_random_seq.sv"

    `include "tests/fetch_base_test.sv"
    `include "tests/fetch_smoke_test.sv"
    `include "tests/fetch_branch_test.sv"
    `include "tests/fetch_pc_increment_test.sv"
    `include "tests/fetch_stall_test.sv"
    `include "tests/fetch_reset_test.sv"
    `include "tests/fetch_random_test.sv"

endpackage
