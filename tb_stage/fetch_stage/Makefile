# Vivado simulator tools
XVLOG = xvlog
XELAB = xelab
XSIM  = xsim

# directories
RTL_DIR = ../../rtl/risc_top/pipelined_riscv_core/data_path/\(1\)fetch_stage/

# includes
INCLUDES = \
../../common/ \
../../common/adder.sv \
../../common/flop.sv

# top module
TOP = fetch_tb

# source files
RTL = $(RTL_DIR)/fetch_stage.sv

TB = \
fetch_tb.sv

all: run

compile:
	$(XVLOG) --sv $(RTL) $(TB) \
	-i $(INCLUDES)

elab:
	$(XELAB) $(TOP) -s sim

run:
	$(XSIM) sim -runall

simulate: compile elab run

waves:
	$(XSIM) sim -gui

clean:
	rm -rf xsim.dir *.jou *.log *.pb *.wdb