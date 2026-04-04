function automatic control_base_test create_test(
    string name,
    virtual control_if vif,
    control_env env
);
    case (name)
        "control_basic_instr_test": begin
            control_basic_instr_test t = new(vif, env);
            return t;
        end
        "control_branch_jump_test": begin
            control_branch_jump_test t = new(vif, env);
            return t;
        end
        "control_mem_ops_test": begin
            control_mem_ops_test t = new(vif, env);
            return t;
        end
        "control_reset_test": begin
            control_reset_test t = new(vif, env);
            return t;
        end
        default: return null;
    endcase
endfunction
