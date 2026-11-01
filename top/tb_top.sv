
module tb_top;

    import uvm_pkg::*;
    import fifo_pkg::*;


    // =====================================================
    // Clock / Reset
    // =====================================================

    logic wr_clk;
    logic wr_rst_n;

    logic rd_clk;
    logic rd_rst_n;


    // =====================================================
    // Interface
    // =====================================================

fifo_if #(
    .DATA_WIDTH(DATA_WIDTH)
) fifo_vif (
    .wr_clk (wr_clk),
    .rd_clk (rd_clk)
);


    // =====================================================
    // DUT
    // =====================================================

    async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH     (DEPTH)
) dut (

    .wr_clk   (wr_clk),
    .wr_rst_n (fifo_vif.wr_rst_n),

    .wr_en    (fifo_vif.wr_en),
    .wr_data  (fifo_vif.wr_data),
    .full     (fifo_vif.full),

    .rd_clk   (rd_clk),
    .rd_rst_n (fifo_vif.rd_rst_n),

    .rd_en    (fifo_vif.rd_en),
    .rd_data  (fifo_vif.rd_data),
    .empty    (fifo_vif.empty)

);

    // =====================================================
    // Write Clock
    //
    // period = 10ns
    // =====================================================

    initial begin

        wr_clk = 1'b0;

        forever #5ns
            wr_clk = ~wr_clk;

    end


    // =====================================================
    // Read Clock
    //
    // period = 14ns
    //
    // 故意与write clock异步
    // =====================================================

    initial begin

        rd_clk = 1'b0;

        forever #7ns
            rd_clk = ~rd_clk;

    end


    // =====================================================
    // Reset
    // =====================================================

initial begin

    fifo_vif.apply_reset(100ns);

end


    // =====================================================
    // UVM
    // =====================================================

initial begin

    uvm_config_db #(virtual fifo_if)::set(
        null,
        "*",
        "vif",
        fifo_vif
    );

	run_test();

end


    // =====================================================
    // FSDB
    // =====================================================

    initial begin

        $fsdbDumpfile(
            "../waves/async_fifo_uvm.fsdb"
        );

        $fsdbDumpvars(
            0,
            tb_top
        );

    end


endmodule
