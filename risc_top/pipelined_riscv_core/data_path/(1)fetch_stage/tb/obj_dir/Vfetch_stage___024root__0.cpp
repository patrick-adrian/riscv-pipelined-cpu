// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vfetch_stage.h for the primary calling header

#include "Vfetch_stage__pch.h"

void Vfetch_stage___024root___eval_triggers_vec__act(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_triggers_vec__act\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((IData)(vlSelfRef.clk_i) 
                                                     & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk_i__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__clk_i__0 = vlSelfRef.clk_i;
}

bool Vfetch_stage___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___trigger_anySet__act\n"); );
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

void Vfetch_stage___024root___nba_sequent__TOP__0(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___nba_sequent__TOP__0\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSelfRef.reset_i) {
        vlSelfRef.pc_fi_o = 0U;
    } else if ((1U & (~ (IData)(vlSelfRef.stall_fi_i)))) {
        vlSelfRef.pc_fi_o = ((2U & (IData)(vlSelfRef.pc_src_i))
                              ? ((1U & (IData)(vlSelfRef.pc_src_i))
                                  ? vlSelfRef.pc_target_ex_i
                                  : vlSelfRef.pc_plus4_ex_i)
                              : ((1U & (IData)(vlSelfRef.pc_src_i))
                                  ? vlSelfRef.pred_pc_target_fi_i
                                  : vlSelfRef.pc_plus4_fi_o));
    }
    vlSelfRef.pc_plus4_fi_o = ((IData)(4U) + vlSelfRef.pc_fi_o);
}

void Vfetch_stage___024root___eval_nba(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_nba\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vfetch_stage___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vfetch_stage___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfetch_stage___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vfetch_stage___024root___eval_phase__act(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_phase__act\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vfetch_stage___024root___eval_triggers_vec__act(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vfetch_stage___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vfetch_stage___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    return (0U);
}

void Vfetch_stage___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vfetch_stage___024root___eval_phase__nba(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_phase__nba\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vfetch_stage___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vfetch_stage___024root___eval_nba(vlSelf);
        Vfetch_stage___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vfetch_stage___024root___eval(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vfetch_stage___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("../fetch_stage.sv", 16, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vfetch_stage___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                VL_FATAL_MT("../fetch_stage.sv", 16, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 100 tries");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactPhaseResult = Vfetch_stage___024root___eval_phase__act(vlSelf);
        } while (vlSelfRef.__VactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vfetch_stage___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

#ifdef VL_DEBUG
void Vfetch_stage___024root___eval_debug_assertions(Vfetch_stage___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root___eval_debug_assertions\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk_i & 0xfeU)))) {
        Verilated::overWidthError("clk_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.reset_i & 0xfeU)))) {
        Verilated::overWidthError("reset_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.pc_src_i & 0xfcU)))) {
        Verilated::overWidthError("pc_src_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.stall_fi_i & 0xfeU)))) {
        Verilated::overWidthError("stall_fi_i");
    }
}
#endif  // VL_DEBUG
