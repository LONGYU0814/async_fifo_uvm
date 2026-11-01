// =========================================================
// Two independent analysis inputs:
//
// WR Monitor -> write_wr()
// RD Monitor -> write_rd()
// =========================================================

`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)


class fifo_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(fifo_scoreboard)


    // =====================================================
    // Virtual Interface
    //
    // Used here mainly for reset detection.
    // =====================================================

    virtual fifo_if vif;


    // =====================================================
    // Analysis Implementations
    // =====================================================

    uvm_analysis_imp_wr #(fifo_item, fifo_scoreboard) wr_imp;
    uvm_analysis_imp_rd #(fifo_item, fifo_scoreboard) rd_imp;


    // =====================================================
    // Reference Model
    // =====================================================

    logic [DATA_WIDTH-1:0] expected_q[$];


    // =====================================================
    // Statistics
    // =====================================================

    int unsigned write_count;
    int unsigned read_count;

    int unsigned pass_count;
    int unsigned error_count;

    int unsigned reset_count;


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);


        wr_imp = new(
            "wr_imp",
            this
        );


        rd_imp = new(
            "rd_imp",
            this
        );

    endfunction


    // =====================================================
    // Build Phase
    //
    // Get virtual interface from config_db.
    // =====================================================

    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        if (
            !uvm_config_db #(virtual fifo_if)::get(
                this,
                "",
                "vif",
                vif
            )
        ) begin

            `uvm_fatal(
                "FIFO_SB",
                "Cannot get virtual interface vif"
            )

        end

    endfunction


    // =====================================================
    // Run Phase
    //
    // Reference model must also respond to DUT reset.
    //
    // DUT reset:
    //     FIFO contents are discarded.
    //
    // Therefore:
    //     expected_q must also be cleared.
    // =====================================================

    virtual task run_phase(
        uvm_phase phase
    );

        forever begin

            // -------------------------------------------------
            // Detect either reset being asserted.
            // Our current project asserts both resets together,
            // but watching both makes the scoreboard safer.
            // -------------------------------------------------

            @(
                negedge vif.wr_rst_n
                or
                negedge vif.rd_rst_n
            );


            // -------------------------------------------------
            // Clear reference model
            // -------------------------------------------------

            expected_q.delete();

            reset_count++;


            `uvm_info(
                "FIFO_SB",
                $sformatf(
                    "RESET detected: reference queue cleared, reset_count=%0d",
                    reset_count
                ),
                UVM_LOW
            )


            // -------------------------------------------------
            // Wait until reset is released before waiting for
            // another reset event.
            //
            // This also avoids counting wr_rst_n / rd_rst_n
            // falling in the same reset operation as two
            // independent resets.
            // -------------------------------------------------

            wait (
                vif.wr_rst_n &&
                vif.rd_rst_n
            );

        end

    endtask


    // =====================================================
    // Write Monitor -> Scoreboard
    //
    // Every real successful write enters reference queue.
    // =====================================================

    virtual function void write_wr(
        fifo_item tr
    );

        // -------------------------------------------------
        // Ignore transactions during reset.
        // -------------------------------------------------

        if (!vif.wr_rst_n) begin

            `uvm_info(
                "FIFO_SB",
                "Ignore write transaction during reset",
                UVM_HIGH
            )

            return;

        end


        // -------------------------------------------------
        // Reference Model:
        //
        // FIFO write -> push_back()
        // -------------------------------------------------

        expected_q.push_back(
            tr.data
        );


        write_count++;


        `uvm_info(
            "FIFO_SB",
            $sformatf(
                "WRITE MODEL: push data=0x%0h, queue_size=%0d",
                tr.data,
                expected_q.size()
            ),
            UVM_MEDIUM
        )

    endfunction


    // =====================================================
    // Read Monitor -> Scoreboard
    //
    // Actual read data is compared against the oldest
    // expected FIFO data.
    // =====================================================

    virtual function void write_rd(
        fifo_item tr
    );

        logic [DATA_WIDTH-1:0] expected;


        // -------------------------------------------------
        // Ignore transactions during reset.
        // -------------------------------------------------

        if (!vif.rd_rst_n) begin

            `uvm_info(
                "FIFO_SB",
                "Ignore read transaction during reset",
                UVM_HIGH
            )

            return;

        end


        read_count++;


        // -------------------------------------------------
        // Reference queue underflow check
        // -------------------------------------------------

        if (expected_q.size() == 0) begin

            error_count++;


            `uvm_error(
                "FIFO_SB",
                $sformatf(
                    "REFERENCE QUEUE UNDERFLOW! actual read data=0x%0h",
                    tr.data
                )
            )


            return;

        end


        // -------------------------------------------------
        // FIFO:
        //
        // Write -> push_back()
        // Read  -> pop_front()
        // -------------------------------------------------

        expected = expected_q.pop_front();


        // -------------------------------------------------
        // Compare Expected vs Actual
        // -------------------------------------------------

        if (tr.data !== expected) begin

            error_count++;


            `uvm_error(
                "FIFO_SB",
                $sformatf(
                    {
                        "READ MISMATCH: ",
                        "expected=0x%0h ",
                        "actual=0x%0h ",
                        "queue_size=%0d"
                    },
                    expected,
                    tr.data,
                    expected_q.size()
                )
            )

        end
        else begin

            pass_count++;


            `uvm_info(
                "FIFO_SB",
                $sformatf(
                    {
                        "READ PASS: ",
                        "expected=0x%0h ",
                        "actual=0x%0h ",
                        "queue_size=%0d"
                    },
                    expected,
                    tr.data,
                    expected_q.size()
                ),
                UVM_MEDIUM
            )

        end

    endfunction


    // =====================================================
    // Check Phase
    //
    // At the end of a normal completed testcase,
    // reference queue should be empty.
    // =====================================================

    virtual function void check_phase(
        uvm_phase phase
    );

        super.check_phase(phase);


        if (expected_q.size() != 0) begin

            `uvm_error(
                "FIFO_SB",
                $sformatf(
                    "Simulation ended with %0d unread items in reference queue",
                    expected_q.size()
                )
            )

        end

    endfunction


    // =====================================================
    // Report Phase
    // =====================================================

    virtual function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);


        `uvm_info(
            "FIFO_SB",
            $sformatf(
                {
                    "SUMMARY: ",
                    "writes=%0d ",
                    "reads=%0d ",
                    "pass=%0d ",
                    "errors=%0d ",
                    "resets=%0d"
                },
                write_count,
                read_count,
                pass_count,
                error_count,
                reset_count
            ),
            UVM_LOW
        )

    endfunction


endclass
