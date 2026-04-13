function automatic fetch_decode_base_test create_test(
    string name,
    virtual fetch_decode_control_if vif,
    fetch_decode_env env
);
    // Test selection is stage-agnostic; each concrete test drives control
    // stimulus and observes the resulting fetch/decode/control behavior.
    case (name)
        "fetch_decode_flush_redirect_test": begin
            fetch_decode_flush_redirect_test t = new(vif, env);
            return t;
        end
        "fetch_decode_imem_smoke_test": begin
            fetch_decode_imem_smoke_test t = new(vif, env);
            return t;
        end
        "fetch_decode_program_test": begin
            fetch_decode_program_test t = new(vif, env);
            return t;
        end
        "fetch_decode_stall_test": begin
            fetch_decode_stall_test t = new(vif, env);
            return t;
        end
        default: return null;
    endcase
endfunction
