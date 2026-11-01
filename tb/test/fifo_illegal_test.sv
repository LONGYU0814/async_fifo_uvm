class fifo_illegal_test extends fifo_test;

    `uvm_component_utils(fifo_illegal_test)


    function new(
        string name = "fifo_illegal_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual task run_phase(
        uvm_phase phase
    );

        fifo_wr_sequence fill_seq;
        fifo_wr_sequence illegal_wr_seq;

        fifo_rd_sequence drain_seq;
        fifo_rd_sequence illegal_rd_seq;

        fifo_wr_sequence probe_wr_seq;
        fifo_rd_sequence probe_rd_seq;


        phase.raise_objection(this);


        // =================================================
        // Wait reset
        // =================================================

        wait (
            vif.wr_rst_n &&
            vif.rd_rst_n
        );


        `uvm_info(
            "ILLEGAL_TEST",
            "Reset released",
            UVM_LOW
        )


        // =================================================
        // STEP 1:
        // Fill FIFO normally
        // =================================================

        fill_seq =
            fifo_wr_sequence::type_id::create(
                "fill_seq"
            );

        fill_seq.num_items     = DEPTH;
        fill_seq.force_illegal = 1'b0;


        fill_seq.start(
            env.wr_agent.sqr
        );


        wait (
            vif.full === 1'b1
        );


        `uvm_info(
            "ILLEGAL_TEST",
            "FIFO FULL reached",
            UVM_LOW
        )


        // =================================================
        // STEP 2:
        // Illegal write while FULL
        // =================================================

        illegal_wr_seq =
            fifo_wr_sequence::type_id::create(
                "illegal_wr_seq"
            );

        illegal_wr_seq.num_items     = 1;
        illegal_wr_seq.force_illegal = 1'b1;


        illegal_wr_seq.start(
            env.wr_agent.sqr
        );


        `uvm_info(
            "ILLEGAL_TEST",
            "Illegal write attempt completed",
            UVM_LOW
        )


        // =================================================
        // STEP 3:
        // Drain FIFO normally
        //
        // Scoreboard should still see exactly DEPTH items.
        // =================================================

        drain_seq =
            fifo_rd_sequence::type_id::create(
                "drain_seq"
            );

        drain_seq.num_items     = DEPTH;
        drain_seq.force_illegal = 1'b0;


        drain_seq.start(
            env.rd_agent.sqr
        );


        wait (
            vif.empty === 1'b1
        );


        `uvm_info(
            "ILLEGAL_TEST",
            "FIFO EMPTY reached",
            UVM_LOW
        )


        // =================================================
        // STEP 4:
        // Illegal read while EMPTY
        // =================================================

        illegal_rd_seq =
            fifo_rd_sequence::type_id::create(
                "illegal_rd_seq"
            );

        illegal_rd_seq.num_items     = 1;
        illegal_rd_seq.force_illegal = 1'b1;


        illegal_rd_seq.start(
            env.rd_agent.sqr
        );


        `uvm_info(
            "ILLEGAL_TEST",
            "Illegal read attempt completed",
            UVM_LOW
        )


        // =================================================
        // STEP 5:
        // Probe:
        //
        // 再做一次正常write/read。
        // 如果非法操作破坏了FIFO pointer/state，
        // 后续Scoreboard更容易发现异常。
        // =================================================

        probe_wr_seq =
            fifo_wr_sequence::type_id::create(
                "probe_wr_seq"
            );

        probe_wr_seq.num_items     = 1;
        probe_wr_seq.force_illegal = 1'b0;


        probe_wr_seq.start(
            env.wr_agent.sqr
        );


        probe_rd_seq =
            fifo_rd_sequence::type_id::create(
                "probe_rd_seq"
            );

        probe_rd_seq.num_items     = 1;
        probe_rd_seq.force_illegal = 1'b0;


        probe_rd_seq.start(
            env.rd_agent.sqr
        );


        wait (
            vif.empty === 1'b1
        );


        #20ns;


        `uvm_info(
            "ILLEGAL_TEST",
            "Illegal operation test finished",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask

endclass
