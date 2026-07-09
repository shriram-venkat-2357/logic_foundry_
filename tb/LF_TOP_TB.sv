//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : LF_TOP_TB
//------------------------------------------------------------------------------
// Description:
// Full-system testbench for LF_TOP. Exercises the complete TX->Channel->RX
// path with configurable noise, delay, and modulation.
//
// Verification strategy:
//   1. Configure system (modulation, channel params)
//   2. Send packets through TX pipeline
//   3. Channel model adds impairments
//   4. RX pipeline recovers data
//   5. Check packet_done assertion
//
// FIX: New file - previously missing from repo.
//==============================================================================

`timescale 1ns/1ps
`ifndef LF_TOP_TB_SV
`define LF_TOP_TB_SV

import LF_pkg::*;

module LF_TOP_TB;

    //------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------
    parameter DATA_WIDTH  = 16;
    parameter IQ_WIDTH    = 16;
    parameter FFT_SIZE    = 64;
    parameter CP_LENGTH   = 16;
    parameter FIFO_DEPTH  = 256;
    parameter PACKET_LEN  = 64;
    parameter CLK_PERIOD  = 10;

    //------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------
    logic                      lf_clk_i;
    logic                      lf_rst_n_i;

    // Host Interface
    logic                      lf_cfg_wr_en_i;
    cfg_t                      lf_cfg_i;
    logic                      lf_soft_reset_i;

    perf_t                     lf_perf_o;
    status_t                   lf_status_o;

    // Data Interface
    logic [DATA_WIDTH-1:0]     lf_data_i;
    logic                      lf_valid_i;
    logic                      lf_start_i;

    logic [DATA_WIDTH-1:0]     lf_data_o;
    logic                      lf_valid_o;
    logic                      lf_done_o;

    // Channel Config
    logic [7:0]                lf_noise_level_i;
    logic [3:0]                lf_delay_cfg_i;
    logic [7:0]                lf_freq_offset_i;
    logic [7:0]                lf_drift_cfg_i;

    // Debug
    main_state_t               lf_current_state_o;
    logic [31:0]               lf_system_health_o;

    //------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------
    LF_TOP #(
        .DATA_WIDTH  (DATA_WIDTH),
        .IQ_WIDTH    (IQ_WIDTH),
        .FFT_SIZE    (FFT_SIZE),
        .CP_LENGTH   (CP_LENGTH),
        .FIFO_DEPTH  (FIFO_DEPTH),
        .PACKET_LEN  (PACKET_LEN)
    ) dut (
        .lf_clk_i           (lf_clk_i),
        .lf_rst_n_i         (lf_rst_n_i),
        .lf_cfg_wr_en_i     (lf_cfg_wr_en_i),
        .lf_cfg_i           (lf_cfg_i),
        .lf_soft_reset_i    (lf_soft_reset_i),
        .lf_perf_o          (lf_perf_o),
        .lf_status_o        (lf_status_o),
        .lf_data_i          (lf_data_i),
        .lf_valid_i         (lf_valid_i),
        .lf_start_i         (lf_start_i),
        .lf_data_o          (lf_data_o),
        .lf_valid_o         (lf_valid_o),
        .lf_done_o          (lf_done_o),
        .lf_noise_level_i   (lf_noise_level_i),
        .lf_delay_cfg_i     (lf_delay_cfg_i),
        .lf_freq_offset_i   (lf_freq_offset_i),
        .lf_drift_cfg_i     (lf_drift_cfg_i),
        .lf_current_state_o (lf_current_state_o),
        .lf_system_health_o (lf_system_health_o)
    );

    //------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------
    initial lf_clk_i = 0;
    always #(CLK_PERIOD/2) lf_clk_i = ~lf_clk_i;

    //------------------------------------------------------------
    // Test Variables
    //------------------------------------------------------------
    integer pkt_count;
    integer error_count;

    //------------------------------------------------------------
    // Initialize Configuration
    //------------------------------------------------------------
    task init_config(input mod_t mod_sel, input [7:0] noise);
        lf_cfg_i.modulation    = mod_sel;
        lf_cfg_i.tx_power      = 8'd50;
        lf_cfg_i.channel       = 8'd1;
        lf_cfg_i.packet_length = PACKET_LEN;
        lf_noise_level_i       = noise;
        lf_delay_cfg_i         = 4'd2;
        lf_freq_offset_i       = 8'd0;
        lf_drift_cfg_i         = 8'd0;
    endtask

    //------------------------------------------------------------
    // Apply Configuration (single-cycle pulse)
    //------------------------------------------------------------
    task apply_config;
        lf_cfg_wr_en_i = 1'b1;
        @(posedge lf_clk_i);
        lf_cfg_wr_en_i = 1'b0;
        @(posedge lf_clk_i);
    endtask

    //------------------------------------------------------------
    // Send One Packet
    //------------------------------------------------------------
    task send_packet;
        lf_start_i = 1'b1;
        lf_valid_i = 1'b1;
        for (integer w = 0; w < PACKET_LEN; w = w + 1) begin
            @(posedge lf_clk_i);
            lf_data_i = 16'hA500 + pkt_count * PACKET_LEN + w;
        end
        lf_valid_i = 1'b0;
        lf_start_i = 1'b0;
        pkt_count = pkt_count + 1;
    endtask

    //------------------------------------------------------------
    // Wait for packet to propagate through pipeline
    //------------------------------------------------------------
    task wait_for_done(input integer timeout_cycles);
        integer cycle_cnt;
        cycle_cnt = 0;
        while (!lf_done_o && cycle_cnt < timeout_cycles) begin
            @(posedge lf_clk_i);
            cycle_cnt = cycle_cnt + 1;
        end
        if (!lf_done_o) begin
            $display("[WARN] Timeout waiting for packet done after %0d cycles", timeout_cycles);
            error_count = error_count + 1;
        end else begin
            $display("[INFO] Packet done received after %0d cycles", cycle_cnt);
        end
    endtask

    //------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------
    initial begin
        $dumpfile("waves/lf_top_tb.fst");
        $dumpvars(0, LF_TOP_TB);

        // Initialize
        lf_rst_n_i       = 1'b0;
        lf_cfg_wr_en_i   = 1'b0;
        lf_soft_reset_i  = 1'b0;
        lf_valid_i       = 1'b0;
        lf_start_i       = 1'b0;
        lf_data_i        = '0;
        pkt_count        = 0;
        error_count      = 0;

        // Default config
        init_config(MOD_BPSK, 8'd10);

        // Reset
        repeat (10) @(posedge lf_clk_i);
        lf_rst_n_i = 1'b1;
        repeat (5)  @(posedge lf_clk_i);

        $display("============================================");
        $display("LF-SDR X1 Full System Testbench");
        $display("============================================");

        //---------- Test 1: BPSK with no noise ----------
        $display("[TEST 1] BPSK, noise=0");
        init_config(MOD_BPSK, 8'd0);
        apply_config();

        send_packet();
        wait_for_done(5000);

        //---------- Test 2: QPSK with low noise ----------
        $display("[TEST 2] QPSK, noise=20");
        init_config(MOD_QPSK, 8'd20);
        apply_config();

        send_packet();
        wait_for_done(5000);

        //---------- Test 3: QAM16 with moderate noise ----------
        $display("[TEST 3] QAM16, noise=50");
        init_config(MOD_QAM16, 8'd50);
        apply_config();

        send_packet();
        wait_for_done(5000);

        //---------- Test 4: Burst of packets ----------
        $display("[TEST 4] BPSK burst, 5 packets, noise=10");
        init_config(MOD_BPSK, 8'd10);
        apply_config();

        for (integer p = 0; p < 5; p = p + 1) begin
            send_packet();
            repeat (20) @(posedge lf_clk_i);  // inter-packet gap
        end
        wait_for_done(10000);

        //---------- Test 5: Soft reset ----------
        $display("[TEST 5] Soft reset during operation");
        lf_soft_reset_i = 1'b1;
        @(posedge lf_clk_i);
        @(posedge lf_clk_i);
        lf_soft_reset_i = 1'b0;
        repeat (5) @(posedge lf_clk_i);

        //---------- Results ----------
        $display("============================================");
        if (error_count == 0)
            $display("[PASS] All tests completed with no errors");
        else
            $display("[FAIL] %0d errors detected", error_count);
        $display("============================================");

        $display("[STATUS] Final state: %s", lf_current_state_o.name());
        $display("[STATUS] System health: %h", lf_system_health_o);

        $finish;
    end

    //------------------------------------------------------------
    // Watchdog Timer
    //------------------------------------------------------------
    initial begin
        #(CLK_PERIOD * 200000);
        $display("[ERROR] Watchdog timeout - simulation hung");
        $finish;
    end

endmodule

`endif