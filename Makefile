XVLOG = xvlog
XELAB = xelab
XSIM  = xsim

# Default test
TEST ?= fetch_smoke_test

# Directories
RTL_SV     := $(shell find rtl -name "*.sv" | sort)
COMMON_SV  := common/adder.sv common/flop.sv
TB_ENV_SV  := tb/env/fetch/fetch_env_pkg.sv tb/env/fetch/fetch_tb.sv
TEST_SV    := $(shell find tests -name "$(TEST).sv" 2>/dev/null | sort)

SRC_SV     := $(COMMON_SV) $(RTL_SV) $(TB_ENV_SV) $(TEST_SV)

# Include directories
INCLUDES = common tb/env/fetch

# Top-level module is the test
TOP = $(TEST)

.PHONY: all compile elab run simulate waves clean

all: simulate

compile:
	$(XVLOG) --sv $(SRC_SV) $(addprefix -i ,$(INCLUDES))

elab:
	$(XELAB) $(TOP) -s sim

run:
	$(XSIM) sim -runall

simulate: compile elab run

waves:
	$(XSIM) sim -gui

clean:
	rm -rf xsim.dir *.jou *.log *.pb *.wdb *.wcfg

