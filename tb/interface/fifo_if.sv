`timescale 1ns/1ps

interface fifo_if #(
    parameter int DATA_WIDTH = 8
)(
    input logic wr_clk,
    input logic rd_clk
);

    logic wr_rst_n;
    logic rd_rst_n;

    logic wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic full;

    logic rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic empty;


    // =====================================================
    // Reset Task
    // =====================================================

    task automatic apply_reset(
        time hold_time = 100ns
    );

        wr_rst_n = 1'b0;
        rd_rst_n = 1'b0;

        #(hold_time);

        wr_rst_n = 1'b1;
        rd_rst_n = 1'b1;

    endtask


    clocking wr_drv_cb @(posedge wr_clk);
        default input #1step output #0;

        input  full;
        output wr_en;
        output wr_data;
    endclocking


    clocking wr_mon_cb @(posedge wr_clk);
        default input #1step;

        input wr_en;
        input wr_data;
        input full;
    endclocking


    clocking rd_drv_cb @(posedge rd_clk);
        default input #1step output #0;

        input  empty;
        output rd_en;
    endclocking


    clocking rd_mon_cb @(posedge rd_clk);

        input #1step rd_en;
        input #1step empty;

        input #0 rd_data;

    endclocking


    modport WR_DRIVER  (clocking wr_drv_cb);
    modport WR_MONITOR (clocking wr_mon_cb);

    modport RD_DRIVER  (clocking rd_drv_cb);
    modport RD_MONITOR (clocking rd_mon_cb);


endinterface
