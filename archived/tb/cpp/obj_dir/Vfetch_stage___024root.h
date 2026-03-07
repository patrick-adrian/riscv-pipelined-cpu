// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vfetch_stage.h for the primary calling header

#ifndef VERILATED_VFETCH_STAGE___024ROOT_H_
#define VERILATED_VFETCH_STAGE___024ROOT_H_  // guard

#include "verilated.h"


class Vfetch_stage__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vfetch_stage___024root final {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk_i,0,0);
    VL_IN8(reset_i,0,0);
    VL_IN8(pc_src_i,1,0);
    VL_IN8(stall_fi_i,0,0);
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VstlPhaseResult;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk_i__0;
    CData/*0:0*/ __VactPhaseResult;
    CData/*0:0*/ __VnbaPhaseResult;
    VL_IN(pc_target_ex_i,31,0);
    VL_IN(pc_plus4_ex_i,31,0);
    VL_IN(pred_pc_target_fi_i,31,0);
    VL_OUT(pc_fi_o,31,0);
    VL_OUT(pc_plus4_fi_o,31,0);
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vfetch_stage__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vfetch_stage___024root(Vfetch_stage__Syms* symsp, const char* namep);
    ~Vfetch_stage___024root();
    VL_UNCOPYABLE(Vfetch_stage___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
