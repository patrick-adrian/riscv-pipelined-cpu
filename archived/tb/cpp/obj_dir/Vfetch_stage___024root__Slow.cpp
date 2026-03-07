// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vfetch_stage.h for the primary calling header

#include "Vfetch_stage__pch.h"

void Vfetch_stage___024root___ctor_var_reset(Vfetch_stage___024root* vlSelf);

Vfetch_stage___024root::Vfetch_stage___024root(Vfetch_stage__Syms* symsp, const char* namep)
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vfetch_stage___024root___ctor_var_reset(this);
}

void Vfetch_stage___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vfetch_stage___024root::~Vfetch_stage___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
