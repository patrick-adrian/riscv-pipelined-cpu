function automatic fetch_base_test create_test(
    string name,
    virtual fetch_if vif,
    fetch_env env
);
    if (name == "fetch_smoke_test") begin
        fetch_smoke_test t = new(vif, env);
        return t;
    end
    if (name == "fetch_branch_test") begin
        fetch_branch_test t = new(vif, env);
        return t;
    end
    if (name == "fetch_pc_increment_test") begin
        fetch_pc_increment_test t = new(vif, env);
        return t;
    end
    if (name == "fetch_reset_test") begin
        fetch_reset_test t = new(vif, env);
        return t;
    end
    if (name == "fetch_random_test") begin
        fetch_random_test t = new(vif, env);
        return t;
    end
    if (name == "fetch_stall_test") begin
        fetch_stall_test t = new(vif, env);
        return t;
    end
    return null;
endfunction
