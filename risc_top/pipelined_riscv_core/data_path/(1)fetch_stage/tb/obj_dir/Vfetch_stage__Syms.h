// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VFETCH_STAGE__SYMS_H_
#define VERILATED_VFETCH_STAGE__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vfetch_stage.h"

// INCLUDE MODULE CLASSES
#include "Vfetch_stage___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vfetch_stage__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vfetch_stage* const __Vm_modelp;
    bool __Vm_activity = false;  ///< Used by trace routines to determine change occurred
    uint32_t __Vm_baseCode = 0;  ///< Used by trace routines when tracing multiple models
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vfetch_stage___024root         TOP;

    // CONSTRUCTORS
    Vfetch_stage__Syms(VerilatedContext* contextp, const char* namep, Vfetch_stage* modelp);
    ~Vfetch_stage__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
