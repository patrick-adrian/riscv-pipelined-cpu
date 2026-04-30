class fetch_env extends uvm_env;

    fetch_agent      agent;
    fetch_scoreboard scoreboard;
    fetch_coverage   cov;

    `uvm_component_utils(fetch_env)

    function new(string name = "fetch_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent      = fetch_agent::type_id::create("agent", this);
        scoreboard = fetch_scoreboard::type_id::create("scoreboard", this);
        cov        = fetch_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agent.monitor.ap.connect(scoreboard.analysis_export);
        agent.monitor.ap.connect(cov.analysis_export);
    endfunction

endclass