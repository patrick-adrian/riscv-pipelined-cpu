function automatic ds_base_test create_test(
    string name,
    virtual ds_if vif,
    ds_env env
);
    case (name)
        "decode_slice_smoke_test": begin
            decode_slice_smoke_test t = new(vif, env);
            return t;
        end
        default: return null;
    endcase
endfunction
