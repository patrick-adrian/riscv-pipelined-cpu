XVLOG = xvlog
XELAB = xelab
XSIM  = xsim

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
TOP := tb_top
ENV_DIR := tb/env/$(STAGE)

# Stage-specific overrides
ifeq ($(STAGE),decode_slice)
  TOP       := tb_decode_slice
endif
ifeq ($(STAGE),control)
  TOP       := tb_control_unit
  ENV_DIR   := tb/env/control
endif

# Directories
RTL_SV     := $(shell find rtl -name "*.sv" | sort)
COMMON_SV  := common/adder.sv common/flop.sv
TB_ENV_PKG_SV := $(wildcard tb/env/$(STAGE)/$(STAGE)_env_pkg.sv)
TEST_BASE_SV := $(wildcard tb/env/$(STAGE)/$(STAGE)_base_test.sv)
TEST_FACTORY_SV := $(wildcard tb/env/$(STAGE)/$(STAGE)_test_factory.sv)
TEST_CLASS_SV := $(shell find tests/$(STAGE) -name "*_test.sv" | sort)

ifeq ($(STAGE),control)
  TB_ENV_PKG_SV := $(wildcard tb/env/control/control_env_pkg.sv)
  TEST_BASE_SV := $(wildcard tb/env/control/control_base_test.sv)
  TEST_FACTORY_SV := $(wildcard tb/env/control/control_test_factory.sv)
  TEST_CLASS_SV := $(shell find tests/control -name "*.sv" | sort)
endif

ifeq ($(STAGE),decode_slice)
  TB_TOP_SV := tb/env/decode_slice/tb_decode_slice.sv
else ifeq ($(STAGE),control)
  TB_TOP_SV := tb/env/control/tb_control_unit.sv
else
  TB_TOP_SV := tb/env/$(STAGE)/tb_top.sv
endif

# Stage-specific assertions (look under tb/assertions/<STAGE>)
ASSERT_SV  := $(wildcard tb/assertions/$(STAGE)/*.sv)
SRC_SV     := $(COMMON_SV) $(RTL_SV) $(TB_ENV_PKG_SV) $(TEST_BASE_SV) $(TEST_CLASS_SV) $(TEST_FACTORY_SV) $(TB_TOP_SV) $(ASSERT_SV)

# Include directories (stage env + stage assertions for `include and package visibility)
INCLUDES   := common $(ENV_DIR) tb/assertions/$(STAGE)

.PHONY: all compile elab run simulate waves clean help

all: simulate

# Define XSIM_SVA_OFF when building for fetch to use procedural assertions (xsim has limited SVA support)
XVLOG_OPTS := $(if $(filter fetch,$(STAGE)),-d XSIM_SVA_OFF,)
compile:
	$(XVLOG) --sv $(SRC_SV) $(addprefix -i ,$(INCLUDES)) $(XVLOG_OPTS)

elab:
	$(XELAB) $(TOP) -s sim

run:
	$(XSIM) sim -runall -testplusarg TEST=$(TEST) $(if $(SEED),-sv_seed $(SEED) -testplusarg SEED=$(SEED),)

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
	@echo "  make simulate STAGE=control TEST=test_basic_instr"
