ENTRY(_start)

MEMORY {
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
  DMEM (rwx) : ORIGIN = 0x20000000, LENGTH = 32K
}

/* Define stack pointer at the very top of DMEM */
__stack_top = ORIGIN(DMEM) + LENGTH(DMEM);

SECTIONS {
    /* Code lives in IMEM */
    .text : ALIGN(4) {
        KEEP(*(.text._start))   /* don’t strip your reset/entry */
        *(.init)                /* startup sections */
        *(.text .text.*)        /* all other code */
    } > IMEM

    /* --- Constants --- */
    .rodata : {
        *(.rodata .rodata.*)
    } > DMEM

    /* --- Initialized variables --- */
    .data : {
        __data_start = .;
        *(.data .data.*)
        __data_end = .;
    } > DMEM

    /* --- Small data section --- */
    .sdata : ALIGN(4) {
        __sdata_start = .;
        *(.sdata .sdata.*)
        __sdata_end = .;
    } > DMEM

    /* --- Small BSS --- */
    .sbss (NOLOAD) : ALIGN(4) {
        __sbss_start = .;
        *(.sbss .sbss.*)
        __sbss_end = .;
    } > DMEM

    /* --- Initialize global pointer */
    __global_pointer$ = (__sdata_start + __sbss_end) / 2;

    /* --- Zero-init variables --- */
    .bss (NOLOAD) : ALIGN(4) {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    } > DMEM

    /* --- Heap region --- */
    . = ALIGN(8);
    __heap_start = .;
    __heap_end   = __stack_top - 0x100;
}
