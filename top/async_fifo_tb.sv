`timescale 1ns/1ps

module async_fifo_tb;

    // =========================================================
    // Parameters
    // =========================================================

    localparam int DATA_WIDTH    = 8;
    localparam int DEPTH         = 16;

    localparam int ADDR_WIDTH    = $clog2(DEPTH);
    localparam int PTR_WIDTH     = ADDR_WIDTH + 1;

    localparam int RANDOM_CYCLES = 100;


    // =========================================================
    // DUT Signals
    // =========================================================

logic wr_clk;
logic wr_rst_n;

logic rd_clk;
logic rd_rst_n;

    // =========================================================
    // Reference Model
    // =========================================================

    logic [DATA_WIDTH-1:0] expected_q[$];

    int unsigned error_count;

    int unsigned random_write_count;
    int unsigned random_read_count;


    // expected_q 是 write/read 两个线程共享的资源
    semaphore q_lock;


    //interface
    fifo_if #(
    .DATA_WIDTH(DATA_WIDTH)
) fifo_vif (
    .wr_clk   (wr_clk),
    .wr_rst_n (wr_rst_n),

    .rd_clk   (rd_clk),
    .rd_rst_n (rd_rst_n)
);

















    // =========================================================
    // DUT
    // =========================================================
async_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH)
) dut (
    .wr_clk   (wr_clk),
    .wr_rst_n (wr_rst_n),

    .wr_en    (fifo_vif.wr_en),
    .wr_data  (fifo_vif.wr_data),
    .full     (fifo_vif.full),

    .rd_clk   (rd_clk),
    .rd_rst_n (rd_rst_n),

    .rd_en    (fifo_vif.rd_en),
    .rd_data  (fifo_vif.rd_data),
    .empty    (fifo_vif.empty)
);


    // =========================================================
    // Semaphore Initialization
    // =========================================================

    initial begin
        q_lock = new(1);
    end


    // =========================================================
    // FSDB
    // =========================================================

    initial begin
        $fsdbDumpfile("../waves/async_fifo.fsdb");
        $fsdbDumpvars(0, async_fifo_tb);
    end


    // =========================================================
    // Write Clock
    //
    // Period = 10ns
    // =========================================================

    initial begin

        wr_clk = 1'b0;

        forever #5
            wr_clk = ~wr_clk;

    end


    // =========================================================
    // Read Clock
    //
    // Period = 14ns
    // =========================================================

    initial begin

        rd_clk = 1'b0;

        forever #7
            rd_clk = ~rd_clk;

    end


    // =========================================================
    // Normal Write
    // =========================================================

    task automatic write_one(
    input logic [DATA_WIDTH-1:0] data
);

    // ---------------------------------
    // Wait until FIFO can accept write
    // ---------------------------------

    @(fifo_vif.wr_drv_cb);

    while (fifo_vif.wr_drv_cb.full) begin
        @(fifo_vif.wr_drv_cb);
    end


    // ---------------------------------
    // Drive through clocking block
    // ---------------------------------

    fifo_vif.wr_drv_cb.wr_en   <= 1'b1;
    fifo_vif.wr_drv_cb.wr_data <= data;


    // ---------------------------------
    // Next posedge:
    // DUT sees this transaction
    // ---------------------------------

    @(fifo_vif.wr_mon_cb);


    // wr_mon_cb uses #1step
    // so these values describe what
    // DUT saw at this edge

    if (
        fifo_vif.wr_mon_cb.wr_en &&
        !fifo_vif.wr_mon_cb.full
    ) begin

        q_lock.get(1);

        expected_q.push_back(data);

        q_lock.put(1);


        $display(
            "[%0t] WRITE : data=0x%0h",
            $time,
            data
        );

    end
    else begin

        error_count++;

        $error(
            "[%0t] WRITE was not accepted",
            $time
        );

    end


    // ---------------------------------
    // Deassert through clocking block
    // ---------------------------------

    fifo_vif.wr_drv_cb.wr_en <= 1'b0;

endtask


    // =========================================================
    // Normal Read + Compare
    // =========================================================

    task automatic read_one();

    logic [DATA_WIDTH-1:0] expected;


    // ---------------------------------
    // Wait until FIFO has data
    // ---------------------------------

    @(fifo_vif.rd_drv_cb);

    while (fifo_vif.rd_drv_cb.empty) begin
        @(fifo_vif.rd_drv_cb);
    end


    // ---------------------------------
    // Drive read request
    // ---------------------------------

    fifo_vif.rd_drv_cb.rd_en <= 1'b1;


    // ---------------------------------
    // Next read clock:
    // monitor observes transaction
    // ---------------------------------

    @(fifo_vif.rd_mon_cb);


    // 判断刚刚这个edge是否真的read
    if (
        fifo_vif.rd_mon_cb.rd_en &&
        !fifo_vif.rd_mon_cb.empty
    ) begin


        // ---------------------------------
        // Reference Model
        // ---------------------------------

        q_lock.get(1);


        if (expected_q.size() == 0) begin

            q_lock.put(1);

            error_count++;

            $fatal(
                1,
                "[%0t] ERROR: Reference queue underflow!",
                $time
            );

        end


        expected = expected_q.pop_front();

        q_lock.put(1);


        // ---------------------------------
        // Compare
        // ---------------------------------

        if (fifo_vif.rd_mon_cb.rd_data !== expected) begin

            error_count++;

            $error(
                "[%0t] READ ERROR: expected=0x%0h actual=0x%0h",
                $time,
                expected,
                fifo_vif.rd_mon_cb.rd_data
            );

        end
        else begin

            $display(
                "[%0t] READ PASS : data=0x%0h",
                $time,
                fifo_vif.rd_mon_cb.rd_data
            );

        end

    end
    else begin

        error_count++;

        $error(
            "[%0t] READ was not accepted",
            $time
        );

    end


    // ---------------------------------
    // Deassert read request
    // ---------------------------------

    fifo_vif.rd_drv_cb.rd_en <= 1'b0;

endtask


    // =========================================================
    // Try Write While FULL
    // =========================================================

    task automatic try_write_when_full(
        input logic [DATA_WIDTH-1:0] data
    );

        logic [PTR_WIDTH-1:0] old_wbin;


        wait (fifo_vif.full);


        old_wbin = dut.wbin;


        @(negedge wr_clk);

        fifo_vif.wr_en   = 1'b1;
        fifo_vif.wr_data = data;


        // DUT sees:
        //
        // fifo_vif.wr_en = 1
        // fifo_vif.full  = 1
        //
        // write_fire = 0

        @(posedge wr_clk);

        #1ps;


        if (dut.wbin !== old_wbin) begin

            error_count++;

            $error(
                "[%0t] FULL PROTECTION ERROR: old_wbin=%0d new_wbin=%0d",
                $time,
                old_wbin,
                dut.wbin
            );

        end
        else begin

            $display(
                "[%0t] FULL PROTECTION PASS",
                $time
            );

        end


        @(negedge wr_clk);

        fifo_vif.wr_en = 1'b0;

    endtask


    // =========================================================
    // Try Read While EMPTY
    // =========================================================

    task automatic try_read_when_empty();

        logic [PTR_WIDTH-1:0] old_rbin;


        wait (fifo_vif.empty);


        old_rbin = dut.rbin;


        @(negedge rd_clk);

        fifo_vif.rd_en = 1'b1;


        // DUT sees:
        //
        // fifo_vif.rd_en = 1
        // fifo_vif.empty = 1
        //
        // read_fire = 0

        @(posedge rd_clk);

        #1ps;


        if (dut.rbin !== old_rbin) begin

            error_count++;

            $error(
                "[%0t] EMPTY PROTECTION ERROR: old_rbin=%0d new_rbin=%0d",
                $time,
                old_rbin,
                dut.rbin
            );

        end
        else begin

            $display(
                "[%0t] EMPTY PROTECTION PASS",
                $time
            );

        end


        @(negedge rd_clk);

        fifo_vif.rd_en = 1'b0;

    endtask


    // =========================================================
    // Random Write Thread
    // =========================================================

task automatic random_write_thread();

    logic [DATA_WIDTH-1:0] data;

    for (int i = 0; i < RANDOM_CYCLES; i++) begin

        // ==========================================
        // Driver在clocking block事件上工作
        // ==========================================
        @(fifo_vif.wr_drv_cb);


        // 随机决定是否发起write
        if (
            ($urandom_range(1, 0) == 1) &&
            (fifo_vif.wr_drv_cb.full == 1'b0)
        ) begin

            data = $urandom();

            fifo_vif.wr_drv_cb.wr_en   <= 1'b1;
            fifo_vif.wr_drv_cb.wr_data <= data;


            // ======================================
            // 下一个wr_clk：
            // Monitor观察DUT是否真正接受
            // ======================================
            @(fifo_vif.wr_mon_cb);


            if (
                fifo_vif.wr_mon_cb.wr_en &&
                !fifo_vif.wr_mon_cb.full
            ) begin

                q_lock.get(1);

                expected_q.push_back(
                    fifo_vif.wr_mon_cb.wr_data
                );

                q_lock.put(1);


                random_write_count++;


                $display(
                    "[%0t] RANDOM WRITE : data=0x%0h",
                    $time,
                    fifo_vif.wr_mon_cb.wr_data
                );

            end


            // 当前transaction结束
            fifo_vif.wr_drv_cb.wr_en <= 1'b0;

        end
        else begin

            fifo_vif.wr_drv_cb.wr_en <= 1'b0;

        end

    end


    fifo_vif.wr_drv_cb.wr_en <= 1'b0;


    $display(
        "[%0t] RANDOM WRITE THREAD DONE, accepted=%0d",
        $time,
        random_write_count
    );

endtask

    // =========================================================
    // Random Read Thread
    // =========================================================

 task automatic random_read_thread();

    logic [DATA_WIDTH-1:0] expected;


    for (int i = 0; i < RANDOM_CYCLES; i++) begin

        // ==========================================
        // Driver
        // ==========================================
        @(fifo_vif.rd_drv_cb);


        if (
            ($urandom_range(1, 0) == 1) &&
            (fifo_vif.rd_drv_cb.empty == 1'b0)
        ) begin

            fifo_vif.rd_drv_cb.rd_en <= 1'b1;


            // ======================================
            // Monitor观察下一次read edge
            // ======================================
            @(fifo_vif.rd_mon_cb);


            if (
                fifo_vif.rd_mon_cb.rd_en &&
                !fifo_vif.rd_mon_cb.empty
            ) begin

                // ==================================
                // Reference Model
                // ==================================
                q_lock.get(1);


                if (expected_q.size() == 0) begin

                    q_lock.put(1);

                    error_count++;

                    $fatal(
                        1,
                        "[%0t] RANDOM ERROR: reference queue underflow",
                        $time
                    );

                end


                expected = expected_q.pop_front();

                q_lock.put(1);


                // ==================================
                // Compare
                //
                // rd_data通过rd_mon_cb的input #0采样
                // 所以不再需要#1ps
                // ==================================
                if (
                    fifo_vif.rd_mon_cb.rd_data
                    !==
                    expected
                ) begin

                    error_count++;

                    $error(
                        "[%0t] RANDOM READ ERROR: expected=0x%0h actual=0x%0h",
                        $time,
                        expected,
                        fifo_vif.rd_mon_cb.rd_data
                    );

                end
                else begin

                    $display(
                        "[%0t] RANDOM READ PASS : data=0x%0h",
                        $time,
                        fifo_vif.rd_mon_cb.rd_data
                    );

                end


                random_read_count++;

            end


            fifo_vif.rd_drv_cb.rd_en <= 1'b0;

        end
        else begin

            fifo_vif.rd_drv_cb.rd_en <= 1'b0;

        end

    end


    fifo_vif.rd_drv_cb.rd_en <= 1'b0;


    $display(
        "[%0t] RANDOM READ THREAD DONE, accepted=%0d",
        $time,
        random_read_count
    );

endtask

    // =========================================================
    // Watchdog
    // =========================================================

    initial begin

        #100000;

        $fatal(
            1,
            "SIMULATION TIMEOUT"
        );

    end


    // =========================================================
    // Main Test
    // =========================================================

    initial begin


        // =====================================================
        // Initialization
        // =====================================================

        wr_rst_n = 1'b0;
        rd_rst_n = 1'b0;

        fifo_vif.wr_en    = 1'b0;
        fifo_vif.wr_data  = '0;

        fifo_vif.rd_en    = 1'b0;

        error_count        = 0;
        random_write_count = 0;
        random_read_count  = 0;

        expected_q.delete();


        // =====================================================
        // RESET
        // =====================================================

        $display("");
        $display("======================================");
        $display("              RESET");
        $display("======================================");


        repeat (2)
            @(posedge wr_clk);


        @(negedge wr_clk);

        wr_rst_n = 1'b1;


        repeat (2)
            @(posedge rd_clk);


        @(negedge rd_clk);

        rd_rst_n = 1'b1;


        $display(
            "[%0t] RESET RELEASED",
            $time
        );


        // =====================================================
        // TEST 1 : FULL
        // =====================================================

        $display("");
        $display("======================================");
        $display("          TEST 1 : FULL");
        $display("======================================");


        for (int i = 0; i < DEPTH; i++) begin

            write_one(i);

        end


        wait (fifo_vif.full);


        if (fifo_vif.full !== 1'b1) begin

            error_count++;

            $error(
                "[%0t] FULL FLAG ERROR",
                $time
            );

        end
        else begin

            $display(
                "[%0t] FIFO FULL PASS",
                $time
            );

        end


        try_write_when_full(8'hFF);


        // =====================================================
        // TEST 2 : EMPTY
        // =====================================================

        $display("");
        $display("======================================");
        $display("          TEST 2 : EMPTY");
        $display("======================================");


        for (int i = 0; i < DEPTH; i++) begin

            read_one();

        end


        wait (fifo_vif.empty);


        if (fifo_vif.empty !== 1'b1) begin

            error_count++;

            $error(
                "[%0t] EMPTY FLAG ERROR",
                $time
            );

        end
        else begin

            $display(
                "[%0t] FIFO EMPTY PASS",
                $time
            );

        end


        try_read_when_empty();


        // =====================================================
        // TEST 3 : WRAP-AROUND
        // =====================================================

        $display("");
        $display("======================================");
        $display("       TEST 3 : WRAP-AROUND");
        $display("======================================");


        // -----------------------------------------------------
        // Write 16
        // -----------------------------------------------------

        for (int i = 0; i < DEPTH; i++) begin

            write_one(i);

        end


        // -----------------------------------------------------
        // Read 8
        //
        // 00 ~ 07
        // -----------------------------------------------------

        for (int i = 0; i < DEPTH/2; i++) begin

            read_one();

        end


        // -----------------------------------------------------
        // Write another 8
        //
        // 80 ~ 87
        //
        // write address wraps around here
        // -----------------------------------------------------

        for (int i = 0; i < DEPTH/2; i++) begin

            write_one(8'h80 + i);

        end


        // -----------------------------------------------------
        // Read all remaining 16
        //
        // Expected:
        //
        // 08 ~ 0F
        // 80 ~ 87
        // -----------------------------------------------------

        for (int i = 0; i < DEPTH; i++) begin

            read_one();

        end


        wait (fifo_vif.empty);


        // =====================================================
        // TEST 4 : RANDOM CONCURRENT
        // =====================================================

        $display("");
        $display("======================================");
        $display("     TEST 4 : RANDOM CONCURRENT");
        $display("======================================");


        // 此时FIFO应该是空的

        if (expected_q.size() != 0) begin

            error_count++;

            $error(
                "Reference queue is not empty before random test"
            );

        end


        // =====================================================
        // fork:
        //
        // Write Domain 和 Read Domain
        // 真正同时运行
        // =====================================================

        fork

            random_write_thread();

            random_read_thread();

        join


        $display("");
        $display("Random concurrent phase finished");
        $display(
            "Random accepted writes = %0d",
            random_write_count
        );

        $display(
            "Random accepted reads  = %0d",
            random_read_count
        );


        // =====================================================
        // Drain Phase
        //
        // Random阶段结束以后：
        //
        // 有可能
        //
        // write_count > read_count
        //
        // FIFO里面仍然有数据。
        //
        // 停止写以后，把剩余数据全部读出来。
        // =====================================================

        $display("");
        $display("======================================");
        $display("          DRAIN PHASE");
        $display("======================================");


        while (expected_q.size() != 0) begin

            read_one();

        end


        // 等待read domain真正产生empty
        wait (fifo_vif.empty);


        $display(
            "[%0t] FIFO DRAIN COMPLETE",
            $time
        );


        // =====================================================
        // FINAL CHECK
        // =====================================================

        #20;


        $display("");
        $display("======================================");
        $display("           FINAL RESULT");
        $display("======================================");


        if (
            (error_count       == 0) &&
            (expected_q.size() == 0) &&
            (fifo_vif.empty             === 1'b1)
        ) begin

            $display("");
            $display("######################################");
            $display("#                                    #");
            $display("#          ALL TEST PASS             #");
            $display("#                                    #");
            $display("######################################");
            $display("");

        end
        else begin

            $display("");
            $display("######################################");
            $display("#                                    #");
            $display("#             TEST FAIL              #");
            $display("#                                    #");
            $display("######################################");

            $display(
                "error_count = %0d",
                error_count
            );

            $display(
                "queue_size  = %0d",
                expected_q.size()
            );

            $display(
                "empty       = %0b",
                fifo_vif.empty
            );

            $display("");

        end


        #20;

        $finish;

    end

endmodule
