// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vfetch_stage__pch.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

Vfetch_stage::Vfetch_stage(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vfetch_stage__Syms(contextp(), _vcname__, this)}
    , clk_i{vlSymsp->TOP.clk_i}
    , reset_i{vlSymsp->TOP.reset_i}
    , pc_src_i{vlSymsp->TOP.pc_src_i}
    , stall_fi_i{vlSymsp->TOP.stall_fi_i}
    , pc_target_ex_i{vlSymsp->TOP.pc_target_ex_i}
    , pc_plus4_ex_i{vlSymsp->TOP.pc_plus4_ex_i}
    , pred_pc_target_fi_i{vlSymsp->TOP.pred_pc_target_fi_i}
    , pc_fi_o{vlSymsp->TOP.pc_fi_o}
    , pc_plus4_fi_o{vlSymsp->TOP.pc_plus4_fi_o}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
    contextp()->traceBaseModelCbAdd(
        [this](VerilatedTraceBaseC* tfp, int levels, int options) { traceBaseModel(tfp, levels, options); });
}

Vfetch_stage::Vfetch_stage(const char* _vcname__)
    : Vfetch_stage(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vfetch_stage::~Vfetch_stage() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vfetch_stage___024root___eval_debug_assertions(Vfetch_stage___024root* vlSelf);
#endif  // VL_DEBUG
void Vfetch_stage___024root___eval_static(Vfetch_stage___024root* vlSelf);
void Vfetch_stage___024root___eval_initial(Vfetch_stage___024root* vlSelf);
void Vfetch_stage___024root___eval_settle(Vfetch_stage___024root* vlSelf);
void Vfetch_stage___024root___eval(Vfetch_stage___024root* vlSelf);

void Vfetch_stage::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vfetch_stage::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vfetch_stage___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vfetch_stage___024root___eval_static(&(vlSymsp->TOP));
        Vfetch_stage___024root___eval_initial(&(vlSymsp->TOP));
        Vfetch_stage___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vfetch_stage___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vfetch_stage::eventsPending() { return false; }

uint64_t Vfetch_stage::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vfetch_stage::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vfetch_stage___024root___eval_final(Vfetch_stage___024root* vlSelf);

VL_ATTR_COLD void Vfetch_stage::final() {
    Vfetch_stage___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vfetch_stage::hierName() const { return vlSymsp->name(); }
const char* Vfetch_stage::modelName() const { return "Vfetch_stage"; }
unsigned Vfetch_stage::threads() const { return 1; }
void Vfetch_stage::prepareClone() const { contextp()->prepareClone(); }
void Vfetch_stage::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> Vfetch_stage::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void Vfetch_stage___024root__trace_decl_types(VerilatedVcd* tracep);

void Vfetch_stage___024root__trace_init_top(Vfetch_stage___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vfetch_stage___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vfetch_stage___024root*>(voidSelf);
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(vlSymsp->name(), VerilatedTracePrefixType::SCOPE_MODULE);
    Vfetch_stage___024root__trace_decl_types(tracep);
    Vfetch_stage___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vfetch_stage___024root__trace_register(Vfetch_stage___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Vfetch_stage::traceBaseModel(VerilatedTraceBaseC* tfp, int levels, int options) {
    (void)levels; (void)options;
    VerilatedVcdC* const stfp = dynamic_cast<VerilatedVcdC*>(tfp);
    if (VL_UNLIKELY(!stfp)) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'Vfetch_stage::trace()' called on non-VerilatedVcdC object;"
            " use --trace-fst with VerilatedFst object, and --trace-vcd with VerilatedVcd object");
    }
    stfp->spTrace()->addModel(this);
    stfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Vfetch_stage___024root__trace_register(&(vlSymsp->TOP), stfp->spTrace());
}
