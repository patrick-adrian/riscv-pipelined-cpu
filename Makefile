XVLOG = xvlog
XELAB = xelab
XSIM  = xsim
VIVADO_HOME ?= $(patsubst %/bin/,%,$(dir $(shell which xvlog)))

# Runtime test selection (passed to xsim as +TEST=<name>).
# Stage is derived from first component: fetch_smoke_test -> fetch
# Override STAGE on the command line for multi-word stage names (e.g. STAGE=decode_slice).
TEST  ?= fetch_smoke_test
ifndef STAGE
  STAGE := $(firstword $(subst _, ,$(TEST)))
endif

# Optional random seed for xsim (used for constrained-random tests).
# Example: make simulate TEST=fetch_random_test SEED=1234
SEED  ?=

# Defaults
TOP := tb_$(STAGE)

# Directories
RTL_SV     := $(shell find rtl -name "*.sv" | sort)
COMMON_SV  := common/adder.sv common/flop.sv

# Stage-specific assertions (look under tb/assertions/<STAGE>)
ASSERT_SV  := $(wildcard tb/assertions/$(STAGE)/*.sv)

ifeq ($(STAGE),fetch)
TB_FETCH_IF_SV := tb/uvm/fetch/env/fetch_if.sv
TB_UVM_PKG_SV  := tb/uvm/fetch/fetch_uvm_pkg.sv
TB_TOP_SV      := tb/uvm/fetch/fetch_tb_top.sv
SRC_SV         := $(COMMON_SV) $(RTL_SV) $(TB_FETCH_IF_SV) $(TB_UVM_PKG_SV) $(TB_TOP_SV) $(ASSERT_SV)
INCLUDES       := common $(VIVADO_HOME)/data/xsim/system_verilog/uvm_include tb/uvm/fetch tb/uvm/fetch/env tb/uvm/fetch/seq tb/uvm/fetch/tests tb/assertions/$(STAGE)
XVLOG_OPTS     := --uvm_version 1.2 -L uvm -d XSIM_SVA_OFF
XELAB_OPTS     := --uvm_version 1.2 -L uvm --timescale 1ns/1ps
RUN_TEST_ARGS  := -testplusarg UVM_TESTNAME=$(TEST)
else
ENV_DIR        := tb/env/$(STAGE)
TB_ENV_PKG_SV  := $(wildcard tb/env/$(STAGE)/$(STAGE)_env_pkg.sv)
TEST_BASE_SV   := $(wildcard tb/env/$(STAGE)/$(STAGE)_base_test.sv)
TEST_FACTORY_SV := $(wildcard tb/env/$(STAGE)/$(STAGE)_test_factory.sv)
TEST_CLASS_SV  := $(shell find tests/$(STAGE) -name "*_test.sv" | sort)
TB_TOP_SV      := tb/env/$(STAGE)/$(STAGE)_tb_top.sv
SRC_SV         := $(COMMON_SV) $(RTL_SV) $(TB_ENV_PKG_SV) $(TEST_BASE_SV) $(TEST_CLASS_SV) $(TEST_FACTORY_SV) $(TB_TOP_SV) $(ASSERT_SV)
INCLUDES       := common $(ENV_DIR) tb/assertions/$(STAGE)
XVLOG_OPTS     := $(if $(filter fetch,$(STAGE)),-d XSIM_SVA_OFF,)
XELAB_OPTS     :=
RUN_TEST_ARGS  := -testplusarg TEST=$(TEST)
endif

.PHONY: all compile elab run simulate waves clean help

all: simulate

compile:
	$(XVLOG) --sv $(SRC_SV) $(addprefix -i ,$(INCLUDES)) $(XVLOG_OPTS)

elab:
	$(XELAB) $(TOP) -s sim $(XELAB_OPTS)

run:
	$(XSIM) sim -runall $(RUN_TEST_ARGS) $(if $(SEED),-sv_seed $(SEED) -testplusarg SEED=$(SEED),)

simulate: compile elab run

waves:
	$(XSIM) sim -gui

clean:
	rm -rf xsim.dir *.jou *.log *.pb *.wdb *.wcfg *.vcd *.vpd *.vcd.gz *.vcd.bz2 *.vcd.xz *.vcd.lzma *.vcd.lz *.vcd.lzo 

help:
	@echo "Usage: make [target] TEST=<test> [STAGE=<stage>] [SEED=<n>]"
	@echo "  TEST  = runtime test class name (default: fetch_smoke_test). Stage inferred from prefix (e.g. fetch_ -> fetch)."
	@echo "  STAGE = override auto-derived stage for multi-word names (e.g. decode_slice)."
	@echo "  SEED  = optional random seed passed to xsim (-sv_seed SEED) for constrained-random tests."
	@echo ""
	@echo "Examples:"
	@echo "  make simulate TEST=fetch_smoke_test"
	@echo "  make simulate TEST=fetch_random_test SEED=1234"
	@echo "  make simulate STAGE=decode_slice TEST=decode_slice_smoke_test"
	@echo "  make simulate STAGE=control TEST=control_basic_instr_test"
