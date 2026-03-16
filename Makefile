XVLOG = xvlog
XELAB = xelab
XSIM  = xsim

# Test name (module and filename, e.g. fetch_smoke_test -> tests/fetch/fetch_smoke_test.sv)
# Stage is derived from first component: fetch_smoke_test -> fetch
TEST  ?= fetch_smoke_test
STAGE := $(firstword $(subst _, ,$(TEST)))

# Directories
# Stage env: <stage>_tb.sv always; <stage>_env_pkg.sv optional (if present, include first)
RTL_SV     := $(shell find rtl -name "*.sv" | sort)
COMMON_SV  := common/adder.sv common/flop.sv
TB_ENV_SV  := $(wildcard tb/env/$(STAGE)/$(STAGE)_env_pkg.sv) tb/env/$(STAGE)/$(STAGE)_tb.sv
TEST_SV    := tests/$(STAGE)/$(TEST).sv

# Stage-specific assertions (look under tb/assertions/<STAGE>)
ASSERT_SV  := $(wildcard tb/assertions/$(STAGE)/*.sv)
SRC_SV     := $(COMMON_SV) $(RTL_SV) $(TB_ENV_SV) $(TEST_SV) $(ASSERT_SV)

# Include directories (stage env + stage assertions for `include and package visibility)
INCLUDES   := common tb/env/$(STAGE) tb/assertions/$(STAGE)

# Top-level module is the test (e.g. fetch_smoke_test, decode_smoke_test)
TOP := $(TEST)

.PHONY: all compile elab run simulate waves clean help

all: simulate

# Define XSIM_SVA_OFF when building for fetch to use procedural assertions (xsim has limited SVA support)
XVLOG_OPTS := $(if $(filter fetch,$(STAGE)),-d XSIM_SVA_OFF,)
compile:
	$(XVLOG) --sv $(SRC_SV) $(addprefix -i ,$(INCLUDES)) $(XVLOG_OPTS)

elab:
	$(XELAB) $(TOP) -s sim

run:
	$(XSIM) sim -runall

simulate: compile elab run

waves:
	$(XSIM) sim -gui

clean:
	rm -rf xsim.dir *.jou *.log *.pb *.wdb *.wcfg *.vcd *.vpd *.vcd.gz *.vcd.bz2 *.vcd.xz *.vcd.lzma *.vcd.lz *.vcd.lzo 

help:
	@echo "Usage: make [target] TEST=<test>"
	@echo "  TEST = test module name (default: fetch_smoke_test). Stage inferred from prefix (e.g. fetch_ -> fetch)."
	@echo ""
	@echo "Examples:"
	@echo "  make run"
	@echo "  make run TEST=fetch_reset_test"
	@echo "  make run TEST=decode_smoke_test"
	@echo "  make run TEST=execute_smoke_test"
