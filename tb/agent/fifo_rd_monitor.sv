class fifo_rd_monitor extends uvm_monitor;

    `uvm_component_utils(fifo_rd_monitor)


    // =====================================================
    // Virtual Interface
    // =====================================================

    virtual fifo_if vif;


    // =====================================================
    // Analysis Port
    // =====================================================

    uvm_analysis_port #(fifo_item) ap;


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_rd_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        ap = new("ap", this);

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
                "RD_MON",
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

        fifo_item tr;


        forever begin

            @(vif.rd_mon_cb);


            // =============================================
            // DUT真正接受read：
            //
            // rd_en = 1
            // empty = 0
            // =============================================

            if (
                vif.rd_mon_cb.rd_en &&
                !vif.rd_mon_cb.empty
            ) begin


                tr = fifo_item::type_id::create("tr");


                // registered read得到的实际数据
                tr.data = vif.rd_mon_cb.rd_data;


                `uvm_info(
                    "RD_MON",
                    $sformatf(
                        "Observed read: data=0x%0h",
                        tr.data
                    ),
                    UVM_MEDIUM
                )


                ap.write(tr);

            end

        end

    endtask

endclass
