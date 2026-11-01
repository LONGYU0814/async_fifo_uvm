package fifo_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"


    // =====================================================
    // Global Parameters
    // =====================================================

    parameter int DATA_WIDTH = 8;
    parameter int DEPTH      = 16;


    // =====================================================
    // Transaction
    // =====================================================

    `include "sequence/fifo_item.sv"


    // =====================================================
    // Sequences
    // =====================================================

    `include "sequence/fifo_wr_sequence.sv"
    `include "sequence/fifo_rd_sequence.sv"


    // =====================================================
    // Sequencers
    // =====================================================

    `include "agent/fifo_wr_sequencer.sv"
    `include "agent/fifo_rd_sequencer.sv"


    // =====================================================
    // Drivers
    // =====================================================

    `include "agent/fifo_wr_driver.sv"
    `include "agent/fifo_rd_driver.sv"


    // =====================================================
    // Monitors
    // =====================================================

    `include "agent/fifo_wr_monitor.sv"
    `include "agent/fifo_rd_monitor.sv"


    // =====================================================
    // Agents
    // =====================================================

    `include "agent/fifo_wr_agent.sv"
    `include "agent/fifo_rd_agent.sv"


    // =====================================================
    // Scoreboard
    // =====================================================

    `include "env/fifo_scoreboard.sv"


    // =====================================================
    // Functional Coverage
    // =====================================================

    `include "env/fifo_coverage.sv"


    // =====================================================
    // Environment
    // =====================================================

    `include "env/fifo_env.sv"


// =====================================================
// Tests
// =====================================================

// Tests
`include "test/fifo_test.sv"
`include "test/fifo_full_test.sv"
`include "test/fifo_illegal_test.sv"
`include "test/fifo_wrap_test.sv"
`include "test/fifo_reset_test.sv"


endpackage
