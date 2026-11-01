class fifo_wrap_test extends fifo_test;

    `uvm_component_utils(fifo_wrap_test)


    function new(
        string name = "fifo_wrap_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    virtual task run_phase(
        uvm_phase phase
    );

        fifo_wr_sequence wr_seq;
        fifo_rd_sequence rd_seq;


        phase.raise_objection(this);


        // =================================================
        // Wait reset release
        // =================================================

        wait (
            vif.wr_rst_n &&
            vif.rd_rst_n
        );


        `uvm_info(
            "WRAP_TEST",
            "Reset released, starting wrap-around test",
            UVM_LOW
        )


        // =================================================
        // 3 rounds:
        //
        // 3 * DEPTH
        // = 3 * 16
        // = 48 successful writes / reads
        //
        // PTR_WIDTH = 5
        // 48 operations are enough to make MSB:
        //
        // 0 -> 1 -> 0 -> 1
        // =================================================

        for (int round = 0; round < 3; round++) begin


            `uvm_info(
                "WRAP_TEST",
                $sformatf(
                    "Round %0d: filling FIFO",
                    round
                ),
                UVM_LOW
            )


            // =============================================
            // Fill FIFO
            // =============================================

            wr_seq =
                fifo_wr_sequence::type_id::create(
                    $sformatf(
                        "wr_seq_%0d",
                        round
                    )
                );

            wr_seq.num_items     = DEPTH;
            wr_seq.force_illegal = 1'b0;


            wr_seq.start(
                env.wr_agent.sqr
            );


            // Wait until write domain really sees FULL
            wait (
                vif.full === 1'b1
            );


            `uvm_info(
                "WRAP_TEST",
                $sformatf(
                    "Round %0d: FIFO FULL",
                    round
                ),
                UVM_LOW
            )


            // =============================================
            // Drain FIFO
            // =============================================

            rd_seq =
                fifo_rd_sequence::type_id::create(
                    $sformatf(
                        "rd_seq_%0d",
                        round
                    )
                );

            rd_seq.num_items     = DEPTH;
            rd_seq.force_illegal = 1'b0;


            rd_seq.start(
                env.rd_agent.sqr
            );


            wait (
                vif.empty === 1'b1
            );


            `uvm_info(
                "WRAP_TEST",
                $sformatf(
                    "Round %0d: FIFO EMPTY",
                    round
                ),
                UVM_LOW
            )


            // =============================================
            // Give CDC synchronizers enough time
            // to propagate pointer state across domains
            // =============================================

            repeat (4)
                @(vif.wr_mon_cb);

            repeat (4)
                @(vif.rd_mon_cb);

        end


        // =================================================
        // Final settling time
        // =================================================

        #20ns;


        `uvm_info(
            "WRAP_TEST",
            "Wrap-around test finished",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask


endclass
