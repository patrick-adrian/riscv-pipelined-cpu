class fetch_coverage extends uvm_subscriber #(fetch_sample);

    `uvm_component_utils(fetch_coverage)

    fetch_sample tr;

    // -------------------------------------------------
    // Functional coverage
    // -------------------------------------------------
    covergroup cg_fetch;

        cp_pc_src: coverpoint tr.pc_src {
            bins pc_plus4 = {0};
            bins branch   = {1};
            bins jump     = {2};
            bins reserved = {3};
        }

        cp_stall: coverpoint tr.stall {
            bins no_stall = {0};
            bins stall    = {1};
        }

        cp_pc_target_align: coverpoint tr.pc_target_ex[1:0] {
            bins aligned     = {2'b00};
            bins misaligned  = default;
        }

        x_pc_src_stall: cross cp_pc_src, cp_stall;

    endgroup

    // -------------------------------------------------
    // Constructor
    // -------------------------------------------------
    function new(string name = "fetch_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_fetch = new();
    endfunction

    // -------------------------------------------------
    // Subscriber write hook
    // -------------------------------------------------
    function void write(fetch_sample t);
        tr = t;
        cg_fetch.sample();
    endfunction

    function void report_phase(uvm_phase phase);

        real cov_total;
        real cov_pc_src;
        real cov_stall;
        real cov_pc_target_align;

        super.report_phase(phase);

        cov_total           = cg_fetch.get_coverage();
        cov_pc_src          = cg_fetch.cp_pc_src.get_coverage();
        cov_stall           = cg_fetch.cp_stall.get_coverage();
        cov_pc_target_align = cg_fetch.cp_pc_target_align.get_coverage();

        `uvm_info("COV", $sformatf("Total Coverage = %0.2f%%", cov_total), UVM_LOW)
        `uvm_info("COV", $sformatf("pc_src Coverage = %0.2f%%", cov_pc_src), UVM_LOW)
        `uvm_info("COV", $sformatf("stall Coverage = %0.2f%%", cov_stall), UVM_LOW)
        `uvm_info("COV", $sformatf("pc_target_align Coverage = %0.2f%%", cov_pc_target_align), UVM_LOW)
    endfunction

endclass
