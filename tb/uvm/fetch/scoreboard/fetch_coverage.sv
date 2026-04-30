class fetch_coverage extends uvm_subscriber #(fetch_seq_item);

    covergroup cg_fetch;

        coverpoint tr.pc_src {
            bins pc_plus4 = {0};
            bins branch   = {1};
            bins jump     = {2};
            bins reserved = {3};
        }

        coverpoint tr.stall {
            bins no_stall = {0};
            bins stall    = {1};
        }

        coverpoint tr.pc_target_ex {
            bins pc_target_ex = {32'h0};
        }

        coverpoint tr.pc_plus4_ex {
            bins pc_plus4_ex = {32'h0};
        }
    
    endgroup

        cross tr.pc_src, tr.stall {
            pc_plus4_stall: cross pc_plus4, stall;
            branch_stall: cross branch, stall;
            jump_stall: cross jump, stall;
            reserved_stall: cross reserved, stall;
        }

    function new(string name = "fetch_coverage");
        super.new(name);
    endfunction
endclass