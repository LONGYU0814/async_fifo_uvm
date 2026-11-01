class fifo_rd_agent extends uvm_agent;

    `uvm_component_utils(fifo_rd_agent)


    // =====================================================
    // Components
    // =====================================================

    fifo_rd_sequencer sqr;
    fifo_rd_driver    drv;
    fifo_rd_monitor   mon;


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_rd_agent",
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


        mon = fifo_rd_monitor::type_id::create(
            "mon",
            this
        );


        if (is_active == UVM_ACTIVE) begin

            sqr = fifo_rd_sequencer::type_id::create(
                "sqr",
                this
            );

            drv = fifo_rd_driver::type_id::create(
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
