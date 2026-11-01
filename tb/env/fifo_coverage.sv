`uvm_analysis_imp_decl(_wr_cov)
`uvm_analysis_imp_decl(_rd_cov)


class fifo_coverage extends uvm_component;

    `uvm_component_utils(fifo_coverage)


    // =====================================================
    // Virtual Interface
    // =====================================================

    virtual fifo_if vif;


    // =====================================================
    // Analysis Implementations
    //
    // WR Monitor -> wr_imp
    // RD Monitor -> rd_imp
    // =====================================================

    uvm_analysis_imp_wr_cov #(fifo_item, fifo_coverage) wr_imp;
    uvm_analysis_imp_rd_cov #(fifo_item, fifo_coverage) rd_imp;


    // =====================================================
    // Write Data Coverage
    //
    // 只统计真正成功写入FIFO的数据
    // =====================================================

    covergroup wr_data_cg with function sample(
        logic [DATA_WIDTH-1:0] data
    );

        option.per_instance = 1;


        cp_data : coverpoint data {

            bins low = {
                [8'h00 : 8'h3F]
            };

            bins mid_low = {
                [8'h40 : 8'h7F]
            };

            bins mid_high = {
                [8'h80 : 8'hBF]
            };

            bins high = {
                [8'hC0 : 8'hFF]
            };

        }

    endgroup


    // =====================================================
    // Read Data Coverage
    //
    // 只统计真正成功读出的数据
    // =====================================================

    covergroup rd_data_cg with function sample(
        logic [DATA_WIDTH-1:0] data
    );

        option.per_instance = 1;


        cp_data : coverpoint data {

            bins low = {
                [8'h00 : 8'h3F]
            };

            bins mid_low = {
                [8'h40 : 8'h7F]
            };

            bins mid_high = {
                [8'h80 : 8'hBF]
            };

            bins high = {
                [8'hC0 : 8'hFF]
            };

        }

    endgroup


    // =====================================================
    // Write-side State Coverage
    // =====================================================

    covergroup wr_state_cg with function sample(
        bit wr_en,
        bit full
    );

        option.per_instance = 1;


        // -------------------------------------------------
        // wr_en状态
        // -------------------------------------------------

        cp_wr_en : coverpoint wr_en {

            bins disabled = {0};
            bins enabled  = {1};

        }


        // -------------------------------------------------
        // full当前状态
        // -------------------------------------------------

        cp_full_state : coverpoint full {

            bins not_full = {0};
            bins is_full  = {1};

        }


        // -------------------------------------------------
        // full状态跳变
        // -------------------------------------------------

        cp_full_transition : coverpoint full {

            bins enter_full = (0 => 1);
            bins leave_full = (1 => 0);

        }


        // -------------------------------------------------
        // wr_en × full
        //
        // 观察：
        // wr_en=0/full=0
        // wr_en=0/full=1
        // wr_en=1/full=0
        // wr_en=1/full=1
        // -------------------------------------------------

        wr_en_x_full : cross cp_wr_en, cp_full_state;


    endgroup


    // =====================================================
    // Read-side State Coverage
    // =====================================================

    covergroup rd_state_cg with function sample(
        bit rd_en,
        bit empty
    );

        option.per_instance = 1;


        cp_rd_en : coverpoint rd_en {

            bins disabled = {0};
            bins enabled  = {1};

        }


        cp_empty_state : coverpoint empty {

            bins not_empty = {0};
            bins is_empty  = {1};

        }


        cp_empty_transition : coverpoint empty {

            bins enter_empty = (0 => 1);
            bins leave_empty = (1 => 0);

        }


        rd_en_x_empty : cross cp_rd_en, cp_empty_state;


    endgroup


    // =====================================================
    // Constructor
    // =====================================================

    function new(
        string name = "fifo_coverage",
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


        // Covergroup必须实例化
        wr_data_cg  = new();
        rd_data_cg  = new();

        wr_state_cg = new();
        rd_state_cg = new();

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
                "FIFO_COV",
                "Cannot get virtual interface vif"
            )

        end

    endfunction


    // =====================================================
    // Write Transaction Coverage
    //
    // WR Monitor每观察到一次成功write，
    // 就会调用这里。
    // =====================================================

    virtual function void write_wr_cov(
        fifo_item tr
    );

        wr_data_cg.sample(
            tr.data
        );

    endfunction


    // =====================================================
    // Read Transaction Coverage
    // =====================================================

    virtual function void write_rd_cov(
        fifo_item tr
    );

        rd_data_cg.sample(
            tr.data
        );

    endfunction


    // =====================================================
    // State Coverage Sampling
    // =====================================================

    virtual task run_phase(
        uvm_phase phase
    );

        fork


            // =============================================
            // Write clock domain
            // =============================================

            forever begin

                @(vif.wr_mon_cb);


                // reset期间的数据不计入coverage
                if (vif.wr_rst_n) begin

                    wr_state_cg.sample(
                        vif.wr_mon_cb.wr_en,
                        vif.wr_mon_cb.full
                    );

                end

            end


            // =============================================
            // Read clock domain
            // =============================================

            forever begin

                @(vif.rd_mon_cb);


                if (vif.rd_rst_n) begin

                    rd_state_cg.sample(
                        vif.rd_mon_cb.rd_en,
                        vif.rd_mon_cb.empty
                    );

                end

            end


        join

    endtask


    // =====================================================
    // Report Phase
    // =====================================================

    virtual function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);


        `uvm_info(
            "FIFO_COV",
            $sformatf(
                {
                    "Coverage Summary: ",
                    "wr_data=%0.2f%% ",
                    "rd_data=%0.2f%% ",
                    "wr_state=%0.2f%% ",
                    "rd_state=%0.2f%%"
                },

                wr_data_cg.get_inst_coverage(),
                rd_data_cg.get_inst_coverage(),
                wr_state_cg.get_inst_coverage(),
                rd_state_cg.get_inst_coverage()

            ),
            UVM_LOW
        )

    endfunction


endclass
