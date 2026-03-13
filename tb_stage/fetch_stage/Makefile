# Vivado simulator tools
XVLOG = xvlog
XELAB = xelab
XSIM  = xsim

# directories
RTL_DIR := $(shell find ../../rtl/risc_top -name "*.sv")

# includes
INCLUDES = \
../../common/ \
../../common/adder.sv \
../../common/flop.sv \

# top module
TOP = fetch_tb

# source files
RTL = $(RTL_DIR)

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