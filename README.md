<h1> Objectives </h1>
<ul>
<li>Understand Biggo03's CPU pipeline and create diagrams for each RTL module <b><i>(Semi-finished)</b></i></li>
<li>Create a UVM-like framework for each stage using SystemVerilog testbenches and Vivado <b><i>(In progress)</b></i></li></li>
<li>Build a full UVM framework for the entire CPU pipeline <b><i>(Soon)</b></i></li></li>
</ul>

<h1> Goals </h1>
<ul>
<li>End of February: Begin SV and C++ testbench modules. Begin creating SV testbenches for pipeline stages. </li>
<li>End of March: Finish UVM-like environments for each pipelined stage. </li>
<li>End of April: Full UVM testbench for entire pipelined CPU. </li>
<li>May: Design a minimal GPU or accelerator and AXI cache modules. </li>
<li>June: Write UVM testbenches for these designed modules. </li>
</ul>

<h1> Devlog </h1>
<ul>
<li>Mon Jan 12: Add fetch stage RTL and diagram. </li>
<li>Tues Jan 13: Add decode diagram. </li>
<li>Sat Jan 24: Add to execute.drawio. </li>
<li>Tues Jan 27: Turn old laptop into 24/7 Linux server for iVerilog compilation and simulation via SSH. Add ALU testbench results. </li>
<li>Sat Jan 31: Upload execute.png. </li>
<li>Mon Feb 2: Add writeback stage and reg file RTL. </li>
<li>Wed Feb 4: Add notebook, memory stage diagram, and data mem RTL. </li>
<li>Thurs Feb 5: Add writeback stage diagram, fix repo structure. </li>
<li>Fri Feb 6: Reorg, fix decode diagram. </li>
<li>Sat Feb 7: Fix datapath diagrams, reg file diagram. </li>
<li>Mon Feb 9: Add datapath and CSR reg RTL. Add reg file diagram. </li>
<li>Wed Feb 11: Forked modules. Begin learning modules for RTL testbenches and UVM. </li>
<li>Tues Feb 17: Completed Module 0: RTL testbenches. </li>
<li>Thurs Feb 19: Added testbenches for fetch module. </li>
<li>Sat Feb 21: Added Remote - SSH extension to SSH into Linux server for local compilation and simulation of TBs. Added waveform compilation for fetch TB. </li>
<li> Tues Feb 24: Added modular SV testbench for fetch stage. </li>
<li> Thurs Feb 26: Added C++ testbench for fetch stage. </li>
<li> Sat Feb 28: New plan: Focus on full UVM and SV testbenches. Need proper tooling for doing so. </li>
<li> Mon Mar 2: Installed Vivado on Linux home server. </li>
<li> Tues Mar 3: Added UVM-like tb for fetch stage and compilation with Vivado. </li>
<li> Wed Mar 4: Attempted UVM compilation with Verilator. Took very long; sticking with Vivado. </li>
<li> Sat Mar 7: Separated RTL and testbench directories, makefiles for Vivado compilation. </li>
<li> Tues Mar 10: Add TXN IDs to fetch stage tb. </li>
<li> Thurs Mar 12: Fix fetch stage tb cycle mismatch issues, add waveforms. </li>
<li> Fri Mar 13: Abstract fetch testbench components with env, refactor project structure with tests/, scripts/, results/, regressions/, add regression tool script. </li>
<li> Sat Mar 14: Add assertions for fetch stage. </li>
<li> Mon Mar 16: Fix assertions B and C for fetch stage. </li>
<li> Tues Mar 17: Fix test finish logic and regression script output. </li>
<li> Thurs Mar 19: Fix scoreboard and driver single-cycle model. </li>
<li> Fri Mar 20: Fix reset test thoroughness and reset assertion. </li>
<li> Mon Mar 23: Fix tb_top, convert tests from modules to classes to allow for "compile once sim many". </li>
<li> Tues Mar 24: Decouple driver and monitor and make monitor passive. </li>
<li> Wed Mar 25: Abstract scoreboard from tests for more UVM accuracy. </li>
<li> Thurs Mar 26: Clean up reset contract. </li>
<li> Fri Mar 27: Add decode testbench and regression results. </li>
<li> Tues Mar 31: Add decode_slice testbench, assertions, and regression results. </li>
<li> Wed Apr 1: Add control testbench.</li>
<li> Thurs Apr 2: Add rest of signals to decode_slice tb.</li>
<li> Sat Apr 4: More tb fixes to prep for fetch + decode + control integration TB. </li>
<li> Mon Apr 6: Fixed logging and some discrepancies across fetch and decode TBs. </li>
<li> Tues Apr 7: Fixed logging and some discrepancies for control TB. </li>
<li> Wed Apr 8: Fetch and decode scoreboard improvements. </li>
<li> Thurs Apr 9: Reset test fix and planning for fetch_decode bench. </li>
<li> Fri Apr 10: Inital fetch_decode tb commit. </li>
<li> Sun Apr 12: Look into waveform automation: todo. </li>
<li> Mon Apr 13: Add comments in fetch_decode tb, fix logging. </li>
<li> Tues Apr 14: ALU UVM testbench compilation and simulation (separate repo). </li>
<li> Wed Apr 15: Planning to convert fetch into full UVM. </li>
<li> Mon Apr 20: Initial fetch stage UVM tb. </li>
<li> Tues Apr 21: Made fetch agent be passive or active. </li>
<li> Thurs Apr 23: </li>

</ul>

<h1> UVM Architecture</h1>
<img width="1000" height="580" alt="um" src="https://github.com/user-attachments/assets/56b85a02-f317-46e2-a16a-d06819279b36" />
<h1> RISC-V Format and Instruction Set</h1>
<img width="946" height="577" alt="riscv32_format" src="https://github.com/user-attachments/assets/0765fe23-b1ce-49bf-9e6d-af0b28f10014" />
<img width="1654" height="2339" alt="RV32I_BaseInstructionSet" src="https://github.com/user-attachments/assets/78626772-ff0e-4074-a373-e643c356704b" />
