class fifo_reset_test extends fifo_test;

    `uvm_component_utils(fifo_reset_test)


    function new(
        string name = "fifo_reset_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual task run_phase(
        uvm_phase phase
    );

        fifo_wr_sequence pre_reset_wr_seq;

        fifo_wr_sequence post_reset_wr_seq;
        fifo_rd_sequence post_reset_rd_seq;


        phase.raise_objection(this);


        // =================================================
        // Wait initial reset release
        // =================================================

        wait (
            vif.wr_rst_n &&
            vif.rd_rst_n
        );


        `uvm_info(
            "RESET_TEST",
            "Initial reset released",
            UVM_LOW
        )


        // =================================================
        // STEP 1:
        // Put some valid data into FIFO.
        //
        // Important:
        // Do NOT drain it.
        // We intentionally reset while FIFO is non-empty.
        // =================================================

        pre_reset_wr_seq =
            fifo_wr_sequence::type_id::create(
                "pre_reset_wr_seq"
            );

        pre_reset_wr_seq.num_items     = DEPTH / 2;
        pre_reset_wr_seq.force_illegal = 1'b0;


        pre_reset_wr_seq.start(
            env.wr_agent.sqr
        );


        `uvm_info(
            "RESET_TEST",
            "FIFO contains data, applying mid-test reset",
            UVM_LOW
        )


        // Avoid asserting asynchronous reset exactly
        // on the clock event that completed the final write.
        #1ns;


        // =================================================
        // STEP 2:
        // Mid-test reset
        // =================================================

        vif.apply_reset(50ns);


        `uvm_info(
            "RESET_TEST",
            "Mid-test reset released",
            UVM_LOW
        )


        // =================================================
        // STEP 3:
        // Check reset state
        // =================================================

        if (vif.full !== 1'b0) begin

            `uvm_error(
                "RESET_TEST",
                "FULL is not 0 after reset"
            )

        end


        if (vif.empty !== 1'b1) begin

            `uvm_error(
                "RESET_TEST",
                "EMPTY is not 1 after reset"
            )

        end


        // =================================================
        // STEP 4:
        // After reset, verify FIFO can operate normally again
        // =================================================

        post_reset_wr_seq =
            fifo_wr_sequence::type_id::create(
                "post_reset_wr_seq"
            );

        post_reset_wr_seq.num_items     = DEPTH / 2;
        post_reset_wr_seq.force_illegal = 1'b0;


        post_reset_wr_seq.start(
            env.wr_agent.sqr
        );


        post_reset_rd_seq =
            fifo_rd_sequence::type_id::create(
                "post_reset_rd_seq"
            );

        post_reset_rd_seq.num_items     = DEPTH / 2;
        post_reset_rd_seq.force_illegal = 1'b0;


        post_reset_rd_seq.start(
            env.rd_agent.sqr
        );


        wait (
            vif.empty === 1'b1
        );


        #20ns;


        `uvm_info(
            "RESET_TEST",
            "Reset recovery test finished",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask


endclass
