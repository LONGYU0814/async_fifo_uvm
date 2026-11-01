class fifo_full_test extends fifo_test;

    `uvm_component_utils(fifo_full_test)


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_full_test",
        uvm_component parent = null
    );

        super.new(name, parent);

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
            "FULL_TEST",
            "Reset released, starting FULL test",
            UVM_LOW
        )


        // =================================================
        // STEP 1:
        // Write exactly DEPTH items.
        //
        // No read sequence is running now.
        // FIFO occupancy will increase until FULL.
        // =================================================

        wr_seq = fifo_wr_sequence::type_id::create(
            "wr_seq"
        );

        wr_seq.num_items = DEPTH;


        `uvm_info(
            "FULL_TEST",
            $sformatf(
                "Writing %0d items to fill FIFO",
                DEPTH
            ),
            UVM_LOW
        )


        wr_seq.start(
            env.wr_agent.sqr
        );


        // =================================================
        // STEP 2:
        // Wait until DUT really asserts FULL
        // =================================================

        wait (
            vif.full === 1'b1
        );


        `uvm_info(
            "FULL_TEST",
            "FIFO reached FULL",
            UVM_LOW
        )


        // Give coverage one more write clock event
        // to clearly sample full=1.
        @(vif.wr_mon_cb);


        // =================================================
        // STEP 3:
        // Start reading.
        //
        // Once read pointer propagates back into write
        // clock domain through CDC synchronizers,
        // FULL should deassert.
        // =================================================

        rd_seq = fifo_rd_sequence::type_id::create(
            "rd_seq"
        );

        rd_seq.num_items = DEPTH;


        `uvm_info(
            "FULL_TEST",
            "Starting reads to drain FIFO",
            UVM_LOW
        )


        rd_seq.start(
            env.rd_agent.sqr
        );


        // =================================================
        // STEP 4:
        // Confirm FULL has been released
        // =================================================

        wait (
            vif.full === 1'b0
        );


        `uvm_info(
            "FULL_TEST",
            "FIFO left FULL state",
            UVM_LOW
        )


        // =================================================
        // STEP 5:
        // Confirm FIFO eventually becomes EMPTY
        // =================================================

        wait (
            vif.empty === 1'b1
        );


        `uvm_info(
            "FULL_TEST",
            "FIFO drained to EMPTY",
            UVM_LOW
        )


        // Allow final monitor / scoreboard / coverage
        // activity to settle.
        #20ns;


        `uvm_info(
            "FULL_TEST",
            "FULL test finished",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask


endclass
