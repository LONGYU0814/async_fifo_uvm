class fifo_env extends uvm_env;

    `uvm_component_utils(fifo_env)


    fifo_wr_agent   wr_agent;
    fifo_rd_agent   rd_agent;

    fifo_scoreboard sb;
    fifo_coverage   cov;


    function new(
        string name = "fifo_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // =====================================================
    // Build Phase
    // =====================================================

    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        wr_agent = fifo_wr_agent::type_id::create(
            "wr_agent",
            this
        );


        rd_agent = fifo_rd_agent::type_id::create(
            "rd_agent",
            this
        );


        sb = fifo_scoreboard::type_id::create(
            "sb",
            this
        );


        cov = fifo_coverage::type_id::create(
            "cov",
            this
        );

    endfunction


    // =====================================================
    // Connect Phase
    // =====================================================

    virtual function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);


        // =================================================
        // Monitor -> Scoreboard
        // =================================================

        wr_agent.mon.ap.connect(
            sb.wr_imp
        );


        rd_agent.mon.ap.connect(
            sb.rd_imp
        );


        // =================================================
        // Monitor -> Coverage
        // =================================================

        wr_agent.mon.ap.connect(
            cov.wr_imp
        );


        rd_agent.mon.ap.connect(
            cov.rd_imp
        );

    endfunction


endclass
