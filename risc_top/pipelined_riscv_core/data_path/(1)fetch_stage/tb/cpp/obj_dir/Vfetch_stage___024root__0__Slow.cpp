// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vfetch_stage.h for the primary calling header

#include "Vfetch_stage__pch.h"

VL_ATTR_COLD void Vfetch_stage___024root___eval_static(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_static\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__clk_i__0 = vlSelfRef.clk_i;
}

VL_ATTR_COLD void Vfetch_stage___024root___eval_initial(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_initial\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vfetch_stage___024root___eval_final(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_final\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfetch_stage___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vfetch_stage___024root___eval_phase__stl(Vfetch_stage___024root* vlSelf);

VL_ATTR_COLD void Vfetch_stage___024root___eval_settle(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_settle\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vfetch_stage___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("../fetch_stage.sv", 16, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = Vfetch_stage___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD void Vfetch_stage___024root___eval_triggers_vec__stl(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_triggers_vec__stl\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
}

VL_ATTR_COLD bool Vfetch_stage___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfetch_stage___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vfetch_stage___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vfetch_stage___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___trigger_anySet__stl\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

VL_ATTR_COLD void Vfetch_stage___024root___stl_sequent__TOP__0(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___stl_sequent__TOP__0\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.pc_plus4_fi_o = ((IData)(4U) + vlSelfRef.pc_fi_o);
}

VL_ATTR_COLD void Vfetch_stage___024root___eval_stl(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_stl\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        Vfetch_stage___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD bool Vfetch_stage___024root___eval_phase__stl(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_phase__stl\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vfetch_stage___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vfetch_stage___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vfetch_stage___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vfetch_stage___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vfetch_stage___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfetch_stage___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vfetch_stage___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge clk_i)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vfetch_stage___024root___ctor_var_reset(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___ctor_var_reset\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->clk_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11908517815223722933ull);
    vlSelf->reset_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12763055357940243356ull);
    vlSelf->pc_src_i = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 17187312967273587732ull);
    vlSelf->stall_fi_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13075762576381328138ull);
    vlSelf->pc_target_ex_i = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4951179772547688107ull);
    vlSelf->pc_plus4_ex_i = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10641018154397862904ull);
    vlSelf->pred_pc_target_fi_i = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16128323267781978100ull);
    vlSelf->pc_fi_o = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3253427691165920092ull);
    vlSelf->pc_plus4_fi_o = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 18267189922926610200ull);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__clk_i__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
}
