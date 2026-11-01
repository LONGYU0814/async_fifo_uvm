class fifo_rd_driver extends uvm_driver #(fifo_item);

    `uvm_component_utils(fifo_rd_driver)


    // =====================================================
    // Virtual Interface
    // =====================================================

    virtual fifo_if vif;


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_rd_driver",
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


        if (
            !uvm_config_db #(virtual fifo_if)::get(
                this,
                "",
                "vif",
                vif
            )
        ) begin

            `uvm_fatal(
                "RD_DRV",
                "Cannot get virtual interface vif"
            )

        end

    endfunction


    // =====================================================
    // Run Phase
    // =====================================================

    virtual task run_phase(
        uvm_phase phase
    );

        vif.rd_drv_cb.rd_en <= 1'b0;


        forever begin

            // ---------------------------------------------
            // Get read transaction
            // ---------------------------------------------

            seq_item_port.get_next_item(req);


            `uvm_info(
                "RD_DRV",
                "Get one read request",
                UVM_MEDIUM
            )


            // ---------------------------------------------
            // Drive read
            // ---------------------------------------------

            drive_one_item(req);


            // ---------------------------------------------
            // Complete item
            // ---------------------------------------------

            seq_item_port.item_done();

        end

    endtask


    // =====================================================
    // Drive One Read
    // =====================================================

virtual task drive_one_item(
    fifo_item tr
);

    @(vif.rd_drv_cb);


    // =====================================================
    // ILLEGAL READ
    //
    // 故意在EMPTY=1时assert rd_en
    // =====================================================

    if (tr.force_illegal) begin


        while (!vif.rd_drv_cb.empty) begin

            vif.rd_drv_cb.rd_en <= 1'b0;

            @(vif.rd_drv_cb);

        end


        `uvm_info(
            "RD_DRV",
            "Force illegal read while EMPTY",
            UVM_LOW
        )


        vif.rd_drv_cb.rd_en <= 1'b1;


        @(vif.rd_drv_cb);


        vif.rd_drv_cb.rd_en <= 1'b0;


    end


    // =====================================================
    // NORMAL READ
    // =====================================================

    else begin


        while (vif.rd_drv_cb.empty) begin

            vif.rd_drv_cb.rd_en <= 1'b0;

            @(vif.rd_drv_cb);

        end


        vif.rd_drv_cb.rd_en <= 1'b1;


        @(vif.rd_drv_cb);


        vif.rd_drv_cb.rd_en <= 1'b0;


        `uvm_info(
            "RD_DRV",
            "Drive normal read done",
            UVM_MEDIUM
        )

    end

endtask

endclass
