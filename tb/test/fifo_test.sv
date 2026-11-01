class fifo_test extends uvm_test;

    `uvm_component_utils(fifo_test)

    fifo_env env;

    virtual fifo_if vif;


    function new(
        string name = "fifo_test",
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

        env = fifo_env::type_id::create(
            "env",
            this
        );


        if (
            !uvm_config_db #(virtual fifo_if)::get(
                this,
                "",
                "vif",
                vif
            )
        ) begin

            `uvm_fatal(
                "FIFO_TEST",
                "Cannot get virtual interface vif"
            )

        end

    endfunction


    // =====================================================
    // End of Elaboration
    // =====================================================

    virtual function void end_of_elaboration_phase(
        uvm_phase phase
    );

        super.end_of_elaboration_phase(phase);

        uvm_top.print_topology();

    endfunction


    // =====================================================
    // Run Phase
    // =====================================================

    virtual task run_phase(
        uvm_phase phase
    );

        fifo_wr_sequence wr_seq;
        fifo_rd_sequence rd_seq;


        phase.raise_objection(this);


        // =================================================
        // Wait for reset release
        // =================================================

        wait (
            vif.wr_rst_n &&
            vif.rd_rst_n
        );


        `uvm_info(
            "FIFO_TEST",
            "Reset released, starting sequences",
            UVM_LOW
        )


        // =================================================
        // Create sequences
        // =================================================

        wr_seq = fifo_wr_sequence::type_id::create(
            "wr_seq"
        );

        rd_seq = fifo_rd_sequence::type_id::create(
            "rd_seq"
        );


        wr_seq.num_items = 20;
        rd_seq.num_items = 20;


        // =================================================
        // Start write/read concurrently
        // =================================================

        fork

            begin

                wr_seq.start(
                    env.wr_agent.sqr
                );

            end


            begin

                rd_seq.start(
                    env.rd_agent.sqr
                );

            end

        join


        // Allow final monitor/scoreboard transaction to settle
        #20ns;


        `uvm_info(
            "FIFO_TEST",
            "All sequences finished",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask


endclass
