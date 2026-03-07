// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals

#include "verilated_vcd_c.h"
#include "Vfetch_stage__Syms.h"


void Vfetch_stage___024root__trace_chg_0_sub_0(Vfetch_stage___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vfetch_stage___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root__trace_chg_0\n"); );
    // Body
    Vfetch_stage___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vfetch_stage___024root*>(voidSelf);
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    Vfetch_stage___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vfetch_stage___024root__trace_chg_0_sub_0(Vfetch_stage___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root__trace_chg_0_sub_0\n"); );
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 0);
    bufp->chgBit(oldp+0,(vlSelfRef.clk_i));
    bufp->chgBit(oldp+1,(vlSelfRef.reset_i));
    bufp->chgCData(oldp+2,(vlSelfRef.pc_src_i),2);
    bufp->chgBit(oldp+3,(vlSelfRef.stall_fi_i));
    bufp->chgIData(oldp+4,(vlSelfRef.pc_target_ex_i),32);
    bufp->chgIData(oldp+5,(vlSelfRef.pc_plus4_ex_i),32);
    bufp->chgIData(oldp+6,(vlSelfRef.pred_pc_target_fi_i),32);
    bufp->chgIData(oldp+7,(vlSelfRef.pc_fi_o),32);
    bufp->chgIData(oldp+8,(vlSelfRef.pc_plus4_fi_o),32);
    bufp->chgIData(oldp+9,(((2U & (IData)(vlSelfRef.pc_src_i))
                             ? ((1U & (IData)(vlSelfRef.pc_src_i))
                                 ? vlSelfRef.pc_target_ex_i
                                 : vlSelfRef.pc_plus4_ex_i)
                             : ((1U & (IData)(vlSelfRef.pc_src_i))
                                 ? vlSelfRef.pred_pc_target_fi_i
                                 : vlSelfRef.pc_plus4_fi_o))),32);
    bufp->chgBit(oldp+10,((1U & (~ (IData)(vlSelfRef.stall_fi_i)))));
}

void Vfetch_stage___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfetch_stage___024root__trace_cleanup\n"); );
    // Locals
    VlUnpacked<CData/*0:0*/, 1> __Vm_traceActivity;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        __Vm_traceActivity[__Vi0] = 0;
    }
    // Body
    Vfetch_stage___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vfetch_stage___024root*>(voidSelf);
    Vfetch_stage__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    vlSymsp->__Vm_activity = false;
    __Vm_traceActivity[0U] = 0U;
}
