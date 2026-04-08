function automatic decode_slice_base_test create_test(
    string name,
    virtual decode_slice_if vif,
    decode_slice_env env
);
    case (name)
        "decode_slice_flush_test": begin
            decode_slice_flush_test t = new(vif, env);
            return t;
        end
        "decode_slice_random_test": begin
            decode_slice_random_test t = new(vif, env);
            return t;
        end
        "decode_slice_reset_recovery_test": begin
            decode_slice_reset_recovery_test t = new(vif, env);
            return t;
        end
        "decode_slice_smoke_test": begin
            decode_slice_smoke_test t = new(vif, env);
            return t;
        end
        "decode_slice_stall_flush_precedence_test": begin
            decode_slice_stall_flush_precedence_test t = new(vif, env);
            return t;
        end
        "decode_slice_stall_test": begin
            decode_slice_stall_test t = new(vif, env);
            return t;
        end
        default: return null;
    endcase
endfunction
