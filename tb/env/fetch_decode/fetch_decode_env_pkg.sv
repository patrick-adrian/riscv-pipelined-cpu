`include "fetch_decode_control_if.sv"
`include "instr_mem_model.sv"
// Package contents cover the fetch model plus the integrated decode/control
// testbench components that share the same observation path.
`include "../decode_slice/decode_slice_ref_model.sv"
`include "../control/control_ref_model.sv"
`include "fetch_decode_txn.sv"
`include "integrated_obs.sv"
`include "fetch_decode_driver.sv"
`include "integrated_monitor.sv"
`include "integrated_scoreboard.sv"
`include "fetch_decode_env.sv"
