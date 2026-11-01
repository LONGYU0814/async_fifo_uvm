module fifo_assertions #(

    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16,

    parameter int PTR_WIDTH  = $clog2(DEPTH) + 1

)(

    // =====================================================
    // Write Domain
    // =====================================================

    input logic wr_clk,
    input logic wr_rst_n,

    input logic wr_en,
    input logic full,
    input logic write_fire,

    input logic [PTR_WIDTH-1:0] wbin,
    input logic [PTR_WIDTH-1:0] wgray,


    // =====================================================
    // Read Domain
    // =====================================================

    input logic rd_clk,
    input logic rd_rst_n,

    input logic rd_en,
    input logic empty,
    input logic read_fire,

    input logic [DATA_WIDTH-1:0] rd_data,

    input logic [PTR_WIDTH-1:0] rbin,
    input logic [PTR_WIDTH-1:0] rgray

);


    // =====================================================
    // 1. FULL时即使wr_en=1
    //    write pointer也绝不能移动
    // =====================================================

    property p_no_write_when_full;

        @(posedge wr_clk)

        disable iff (!wr_rst_n)

        (full && wr_en)

        |=>

        (
            $stable(wbin) &&
            $stable(wgray)
        );

    endproperty


    a_no_write_when_full :
        assert property (
            p_no_write_when_full
        )
        else begin

            $error(
                "ASSERT FAIL: write pointer changed while FULL"
            );

        end


    // =====================================================
    // 2. EMPTY时即使rd_en=1
    //    read pointer也绝不能移动
    // =====================================================

    property p_no_read_when_empty;

        @(posedge rd_clk)

        disable iff (!rd_rst_n)

        (empty && rd_en)

        |=>

        (
            $stable(rbin) &&
            $stable(rgray) &&
            $stable(rd_data)
        );

    endproperty


    a_no_read_when_empty :
        assert property (
            p_no_read_when_empty
        )
        else begin

            $error(
                "ASSERT FAIL: read state changed while EMPTY"
            );

        end


    // =====================================================
    // 3. 每次真正write
    //    binary write pointer必须+1
    // =====================================================

    property p_write_pointer_increment;

        @(posedge wr_clk)

        disable iff (!wr_rst_n)

        write_fire

        |=>

        (
            wbin ==
            ($past(wbin) + 1'b1)
        );

    endproperty


    a_write_pointer_increment :
        assert property (
            p_write_pointer_increment
        )
        else begin

            $error(
                "ASSERT FAIL: write pointer did not increment correctly"
            );

        end


    // =====================================================
    // 4. 每次真正read
    //    binary read pointer必须+1
    // =====================================================

    property p_read_pointer_increment;

        @(posedge rd_clk)

        disable iff (!rd_rst_n)

        read_fire

        |=>

        (
            rbin ==
            ($past(rbin) + 1'b1)
        );

    endproperty


    a_read_pointer_increment :
        assert property (
            p_read_pointer_increment
        )
        else begin

            $error(
                "ASSERT FAIL: read pointer did not increment correctly"
            );

        end


    // =====================================================
    // 5. 有效write之后
    //    Gray pointer应该只变化1个bit
    // =====================================================

    property p_write_gray_onebit;

        @(posedge wr_clk)

        disable iff (!wr_rst_n)

        write_fire

        |=>

        $onehot(
            wgray ^ $past(wgray)
        );

    endproperty


    a_write_gray_onebit :
        assert property (
            p_write_gray_onebit
        )
        else begin

            $error(
                "ASSERT FAIL: write Gray pointer changed by more than one bit"
            );

        end


    // =====================================================
    // 6. 有效read之后
    //    Gray pointer应该只变化1个bit
    // =====================================================

    property p_read_gray_onebit;

        @(posedge rd_clk)

        disable iff (!rd_rst_n)

        read_fire

        |=>

        $onehot(
            rgray ^ $past(rgray)
        );

    endproperty


    a_read_gray_onebit :
        assert property (
            p_read_gray_onebit
        )
        else begin

            $error(
                "ASSERT FAIL: read Gray pointer changed by more than one bit"
            );

        end


    // =====================================================
    // Assertion Coverage
    // =====================================================


    // FIFO曾经进入FULL
    c_enter_full :
        cover property (

            @(posedge wr_clk)

            disable iff (!wr_rst_n)

            (!full ##1 full)

        );


    // FIFO曾经离开FULL
    c_leave_full :
        cover property (

            @(posedge wr_clk)

            disable iff (!wr_rst_n)

            (full ##1 !full)

        );


    // 曾经真的尝试FULL时write
    c_illegal_write_full :
        cover property (

            @(posedge wr_clk)

            disable iff (!wr_rst_n)

            (full && wr_en)

        );


    // FIFO曾经从非空变为空
    c_enter_empty :
        cover property (

            @(posedge rd_clk)

            disable iff (!rd_rst_n)

            (!empty ##1 empty)

        );


    // FIFO曾经从空变成非空
    c_leave_empty :
        cover property (

            @(posedge rd_clk)

            disable iff (!rd_rst_n)

            (empty ##1 !empty)

        );


    // 曾经真的尝试EMPTY时read
    c_illegal_read_empty :
        cover property (

            @(posedge rd_clk)

            disable iff (!rd_rst_n)

            (empty && rd_en)

        );


endmodule



// =========================================================
// Bind Assertions into DUT
// =========================================================

bind async_fifo

    fifo_assertions #(

        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)

    ) fifo_assertions_i (

        .wr_clk      (wr_clk),
        .wr_rst_n    (wr_rst_n),

        .wr_en       (wr_en),
        .full        (full),
        .write_fire  (write_fire),

        .wbin        (wbin),
        .wgray       (wgray),


        .rd_clk      (rd_clk),
        .rd_rst_n    (rd_rst_n),

        .rd_en       (rd_en),
        .empty       (empty),
        .read_fire   (read_fire),

        .rd_data     (rd_data),

        .rbin        (rbin),
        .rgray       (rgray)

    );
