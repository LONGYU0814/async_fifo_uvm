class fifo_wr_driver extends uvm_driver #(fifo_item);

    `uvm_component_utils(fifo_wr_driver)


    // =====================================================
    // Virtual Interface
    // =====================================================

    virtual fifo_if vif;


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_wr_driver",
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
                "WR_DRV",
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

        // 初始状态
        vif.wr_drv_cb.wr_en   <= 1'b0;
        vif.wr_drv_cb.wr_data <= '0;


        forever begin

            // ---------------------------------------------
            // 从Sequencer取得一个transaction
            // ---------------------------------------------

            seq_item_port.get_next_item(req);


            `uvm_info(
                "WR_DRV",
                $sformatf(
                    "Get write item: data=0x%0h",
                    req.data
                ),
                UVM_MEDIUM
            )


            // ---------------------------------------------
            // 将transaction驱动到DUT
            // ---------------------------------------------

            drive_one_item(req);


            // ---------------------------------------------
            // 告诉Sequencer：
            // 这一笔处理完成
            // ---------------------------------------------

            seq_item_port.item_done();

        end

    endtask


    // =====================================================
    // Drive One Write Item
    // =====================================================

    virtual task drive_one_item(
    fifo_item tr
);

    @(vif.wr_drv_cb);


    // =====================================================
    // ILLEGAL WRITE
    //
    // 故意在FULL=1时assert wr_en
    // =====================================================

    if (tr.force_illegal) begin


        // 等FIFO进入FULL
        while (!vif.wr_drv_cb.full) begin

            vif.wr_drv_cb.wr_en <= 1'b0;

            @(vif.wr_drv_cb);

        end


        `uvm_info(
            "WR_DRV",
            $sformatf(
                "Force illegal write while FULL: data=0x%0h",
                tr.data
            ),
            UVM_LOW
        )


        vif.wr_drv_cb.wr_data <= tr.data;
        vif.wr_drv_cb.wr_en   <= 1'b1;


        // 保持一个完整write cycle
        @(vif.wr_drv_cb);


        vif.wr_drv_cb.wr_en <= 1'b0;


    end


    // =====================================================
    // NORMAL WRITE
    // =====================================================

    else begin


        while (vif.wr_drv_cb.full) begin

            vif.wr_drv_cb.wr_en <= 1'b0;

            @(vif.wr_drv_cb);

        end


        vif.wr_drv_cb.wr_data <= tr.data;
        vif.wr_drv_cb.wr_en   <= 1'b1;


        @(vif.wr_drv_cb);


        vif.wr_drv_cb.wr_en <= 1'b0;


        `uvm_info(
            "WR_DRV",
            $sformatf(
                "Drive normal write done: data=0x%0h",
                tr.data
            ),
            UVM_MEDIUM
        )

    end

endtask
endclass
