function automatic decode_base_test create_test(
    string name,
    virtual decode_if vif,
    decode_env env
);
    if (name == "decode_smoke_test") begin
        decode_smoke_test t = new(vif, env);
        return t;
    end
    if (name == "decode_reset_test") begin
        decode_reset_test t = new(vif, env);
        return t;
    end
    if (name == "decode_flush_test") begin
        decode_flush_test t = new(vif, env);
        return t;
    end
    if (name == "decode_stall_test") begin
        decode_stall_test t = new(vif, env);
        return t;
    end
    if (name == "decode_precedence_test") begin
        decode_precedence_test t = new(vif, env);
        return t;
    end
    if (name == "decode_imm_random_test") begin
        decode_imm_random_test t = new(vif, env);
        return t;
    end

    return null;
endfunction

