class fifo_wr_agent extends uvm_agent;

    `uvm_component_utils(fifo_wr_agent)


    // =====================================================
    // Components
    // =====================================================

    fifo_wr_sequencer sqr;
    fifo_wr_driver    drv;
    fifo_wr_monitor   mon;


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_wr_agent",
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


        // Monitor无论active/passive都需要
        mon = fifo_wr_monitor::type_id::create(
            "mon",
            this
        );


        // Active Agent才创建Driver和Sequencer
        if (is_active == UVM_ACTIVE) begin

            sqr = fifo_wr_sequencer::type_id::create(
                "sqr",
                this
            );

            drv = fifo_wr_driver::type_id::create(
                "drv",
                this
            );

        end

    endfunction


    // =====================================================
    // Connect Phase
    // =====================================================

    virtual function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);


        if (is_active == UVM_ACTIVE) begin

            drv.seq_item_port.connect(
                sqr.seq_item_export
            );

        end

    endfunction

endclass
