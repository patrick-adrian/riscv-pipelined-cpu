function automatic control_base_test create_test(
    string name,
    virtual control_if vif,
    control_env env
);
    case (name)
        "test_basic_instr": begin
            test_basic_instr t = new(vif, env);
            return t;
        end
        "test_branch_jump": begin
            test_branch_jump t = new(vif, env);
            return t;
        end
        "test_mem_ops": begin
            test_mem_ops t = new(vif, env);
            return t;
        end
        default: return null;
    endcase
endfunction
