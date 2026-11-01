class fifo_wr_monitor extends uvm_monitor;

    `uvm_component_utils(fifo_wr_monitor)


    // =====================================================
    // Virtual Interface
    // =====================================================

    virtual fifo_if vif;


    // =====================================================
    // Analysis Port
    //
    // Monitor通过它向外广播transaction
    // =====================================================

    uvm_analysis_port #(fifo_item) ap;


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_wr_monitor",
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
                "WR_MON",
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

            // 等待write monitor clocking event
            @(vif.wr_mon_cb);


            // =============================================
            // DUT真正接受write：
            //
            // wr_en = 1
            // full  = 0
            // =============================================

            if (
                vif.wr_mon_cb.wr_en &&
                !vif.wr_mon_cb.full
            ) begin


                // 每次transaction都创建一个新对象
                tr = fifo_item::type_id::create("tr");


                // signal -> transaction
                tr.data = vif.wr_mon_cb.wr_data;


                `uvm_info(
                    "WR_MON",
                    $sformatf(
                        "Observed write: data=0x%0h",
                        tr.data
                    ),
                    UVM_MEDIUM
                )


                // 向外广播
                ap.write(tr);

            end

        end

    endtask

endclass
