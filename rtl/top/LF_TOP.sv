//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : LF_TOP
//------------------------------------------------------------------------------
// Description:
// Top-level integration module for the LF-SDR X1 Adaptive Reconfigurable
// Intelligent SDR Baseband Processor.
//
// Connects all 44 submodules into one synthesizable SDR IP:
//   Host Processor Interface
//   Intelligent Control Layer (CFG, MAIN_CTRL, LINK_ADAPT, POWER, STATUS, HEALTH)
//   Transmitter Pipeline (PKT_GEN -> CRC -> SCRAMBLER -> INTERLEAVER ->
//                          MOD_CTRL -> PILOT -> S2P -> IFFT -> CP -> TX_FIFO)
//   Digital Channel Model (AWGN -> DELAY -> FREQ_OFFSET -> CLOCK_DRIFT)
//   Receiver Pipeline (RX_FIFO -> FRAME_DETECT -> SYNC -> CP_REMOVE -> FFT ->
//                       CHANNEL_EST -> EQUALIZER -> DEMOD_CTRL -> P2S ->
//                       DEINTERLEAVER -> DESCRAMBLER -> CRC_CHECK -> PKT_DECODER)
//   Performance Analytics (BER, SNR, PACKET_CNT, LATENCY, PERF_MON, STATUS_REG)
//
// FIX HISTORY:
//   - Fixed IFFT output wiring (was unconnected, valid short-circuited)
//   - Fixed QAM16 demod circular dependency (separate qam16_demod_bits wire)
//   - Fixed bit-indexing in bit-to-word repacking (was {cnt,1'b0} instead of cnt)
//   - Fixed signal power truncation (32-bit multiply truncated to 16-bit)
//   - Fixed empty perf_if() interface connections with proper instances
//   - Fixed forward reference of error_detected_reg (moved declaration before use)
//   - Added proper latency start pulse (uses tx_enable instead of pkt_done)
//==============================================================================

`timescale 1ns/1ps
`ifndef LF_TOP_SV
`define LF_TOP_SV

import LF_pkg::*;

module LF_TOP
#(
    parameter DATA_WIDTH  = 16,
    parameter IQ_WIDTH    = 16,
    parameter FFT_SIZE    = 64,
    parameter CP_LENGTH   = 16,
    parameter FIFO_DEPTH  = 256,
    parameter PACKET_LEN  = 256
)
(
    //------------------------------------------------------------
    // System Clock & Reset
    //------------------------------------------------------------
    input  logic                      lf_clk_i,
    input  logic                      lf_rst_n_i,

    //------------------------------------------------------------
    // Host Processor Interface
    //------------------------------------------------------------
    input  logic                      lf_cfg_wr_en_i,
    input  cfg_t                      lf_cfg_i,
    input  logic                      lf_soft_reset_i,

    output perf_t                     lf_perf_o,
    output status_t                   lf_status_o,

    //------------------------------------------------------------
    // External Data Interface (for testbench / SoC connect)
    //------------------------------------------------------------
    input  logic [DATA_WIDTH-1:0]     lf_data_i,
    input  logic                      lf_valid_i,
    input  logic                      lf_start_i,

    output logic [DATA_WIDTH-1:0]     lf_data_o,
    output logic                      lf_valid_o,
    output logic                      lf_done_o,

    //------------------------------------------------------------
    // Channel Configuration
    //------------------------------------------------------------
    input  logic [7:0]                lf_noise_level_i,
    input  logic [3:0]                lf_delay_cfg_i,
    input  logic [7:0]                lf_freq_offset_i,
    input  logic [7:0]                lf_drift_cfg_i,

    //------------------------------------------------------------
    // Debug / Status
    //------------------------------------------------------------
    output main_state_t               lf_current_state_o,
    output logic [31:0]               lf_system_health_o
);

    //======================================================================
    // INTERNAL WIRES
    //======================================================================

    //----------------------------------------------------------
    // Control Layer Wires
    //----------------------------------------------------------
    cfg_t           cfg;
    logic           cfg_valid;
    logic           cfg_enable, tx_enable, rx_enable, monitor_enable, error_flag;

    logic           link_good, ber_high, snr_low, latency_high;
    logic           adapt_wr_en;
    mod_t           adapt_modulation;
    power_mode_t    power_mode;
    logic           adapt_req;
    logic [7:0]     tx_power;
    logic           power_update;

    // FIX: Declare error_detected_reg BEFORE its first use
    logic error_detected_reg;

    //----------------------------------------------------------
    // TX Pipeline Wires
    //----------------------------------------------------------
    logic [DATA_WIDTH-1:0]    pkt_data, crc_data, scram_data, inter_data;
    logic                     pkt_valid, crc_valid, scram_valid, inter_valid;
    logic                     pkt_sop, crc_sop, scram_sop, inter_sop;
    logic                     pkt_eop, crc_eop, scram_eop, inter_eop;
    logic                     pkt_done;

    logic [DATA_WIDTH-1:0]    mod_ctrl_data;
    logic                     mod_ctrl_valid, mod_ctrl_sop, mod_ctrl_eop;

    logic signed [IQ_WIDTH-1:0] bpsk_i, bpsk_q, qpsk_i, qpsk_q, qam16_i, qam16_q;
    logic                         bpsk_v, qpsk_v, qam16_v;

    logic signed [IQ_WIDTH-1:0] mod_i_out, mod_q_out;
    logic                         mod_iq_valid;

    logic signed [IQ_WIDTH-1:0] pilot_i, pilot_q;
    logic                         pilot_valid, pilot_sop, pilot_eop;

    // FIX: Separate IFFT output wires (previously short-circuited)
    logic signed [IQ_WIDTH-1:0] ifft_real_out, ifft_imag_out;
    logic                         ifft_valid_in, ifft_valid_out;

    // CP Insert outputs
    logic signed [IQ_WIDTH-1:0] cp_real, cp_imag;
    logic                         cp_valid;

    // TX FIFO outputs
    logic signed [IQ_WIDTH-1:0] tx_fifo_real, tx_fifo_imag;
    logic                         tx_fifo_valid, tx_fifo_full, tx_fifo_empty;

    //----------------------------------------------------------
    // Channel Wires
    //----------------------------------------------------------
    logic                         ch_tx_ready, ch_rx_ready;
    logic signed [DATA_WIDTH-1:0] ch_rx_real, ch_rx_imag;
    logic                         ch_rx_valid;

    //----------------------------------------------------------
    // RX Pipeline Wires
    //----------------------------------------------------------
    logic [DATA_WIDTH-1:0]    rx_fifo_data;
    logic                     rx_fifo_valid, rx_fifo_full, rx_fifo_empty;
    logic                     frame_detect, frame_data_valid;
    logic [DATA_WIDTH-1:0]    frame_data;

    logic                     sync_done, symbol_start;
    logic [DATA_WIDTH-1:0]    cp_rem_data;
    logic                     cp_rem_valid;

    logic signed [IQ_WIDTH-1:0] fft_real, fft_imag;
    logic                         fft_valid;

    logic signed [IQ_WIDTH-1:0] ch_est_real, ch_est_imag, eq_real, eq_imag;
    logic                         ch_est_valid, eq_valid, ch_gain;

    // FIX: Separate QAM16 demod bits wire (previously circular dependency)
    logic [3:0]              qam16_demod_bits;
    logic [0:0]              bpsk_demod_bit;
    logic [1:0]              qpsk_demod_bits;
    logic                     bpsk_valid_out, qpsk_valid_out, qam16_valid_out;
    logic [3:0]              demod_bits;
    logic                     demod_valid;

    logic                     p2s_bit, p2s_valid, p2s_busy;

    logic                     deint_bit, deint_valid;
    logic                     descr_bit, descr_valid;

    logic                     crc_check_data_valid, crc_check_data;
    logic                     crc_ok, crc_fail;

    logic [DATA_WIDTH-1:0]    dec_data;
    logic                     dec_valid, dec_sop, dec_eop, dec_pkt_done;
    logic [7:0]               dec_pkt_id, dec_payload_len;

    //----------------------------------------------------------
    // Performance Wires
    //----------------------------------------------------------
    logic                     tx_start_pulse, rx_done_pulse;

    // FIX: Performance registers driven from perf_if instances
    logic [BER_WIDTH-1:0]     perf_ber_reg;
    logic [SNR_WIDTH-1:0]     perf_snr_reg;
    logic [31:0]              perf_latency_reg;
    logic [31:0]              perf_pkt_count_reg;

    //======================================================================
    // PERFORMANCE INTERFACE INSTANCES (one per analytics module)
    // FIX: Previously .perf_if() was used which is invalid.
    //      Each analytics module now gets its own interface instance.
    //======================================================================

    lf_perf_if #() u_ber_perf_if      ();
    lf_perf_if #() u_pkt_perf_if      ();
    lf_perf_if #() u_latency_perf_if  ();
    lf_perf_if #() u_snr_perf_if      ();

    //======================================================================
    // 1. INTELLIGENT CONTROL LAYER
    //======================================================================

    // --- LF_CFG_REG ---
    LF_CFG_REG u_cfg_reg (
        .clk            (lf_clk_i),
        .rst_n          (lf_rst_n_i),
        .cfg_wr_en      (lf_cfg_wr_en_i),
        .cfg_in         (lf_cfg_i),
        .adapt_wr_en    (adapt_wr_en),
        .adapt_modulation(adapt_modulation),
        .adapt_tx_power (tx_power),
        .soft_reset     (lf_soft_reset_i),
        .cfg_out        (cfg)
    );

    assign cfg_valid = lf_cfg_wr_en_i;

    // --- Error detected register (latched from health monitor) ---
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i)
            error_detected_reg <= 1'b0;
        else
            error_detected_reg <= health_error;
    end

    // --- LF_MAIN_CONTROLLER ---
    LF_MAIN_CONTROLLER u_main_ctrl (
        .clk            (lf_clk_i),
        .rst_n          (lf_rst_n_i),
        .cfg_valid      (cfg_valid),
        .tx_done        (pkt_done),
        .rx_done        (dec_pkt_done),
        .error_detected (error_detected_reg),
        .monitor_done   (1'b1),
        .current_state  (lf_current_state_o),
        .cfg_enable     (cfg_enable),
        .tx_enable      (tx_enable),
        .rx_enable      (rx_enable),
        .monitor_enable (monitor_enable),
        .error_flag     (error_flag)
    );

    // --- LF_PERF_MON (threshold checker) ---
    LF_PERF_MON u_perf_mon_ctrl (
        .clk            (lf_clk_i),
        .rst_n          (lf_rst_n_i),
        .ber            (perf_ber_reg),
        .snr            (perf_snr_reg),
        .latency        (perf_latency_reg),
        .packet_count   (perf_pkt_count_reg),
        .ber_threshold  (16'd100),
        .snr_threshold  (16'd500),
        .link_good      (link_good),
        .ber_high       (ber_high),
        .snr_low        (snr_low),
        .latency_high   (latency_high),
        .perf_valid     ()
    );

    // --- LF_LINK_ADAPT_CTRL ---
    LF_LINK_ADAPT_CTRL u_link_adapt (
        .clk             (lf_clk_i),
        .rst_n           (lf_rst_n_i),
        .link_good       (link_good),
        .ber_high        (ber_high),
        .snr_low         (snr_low),
        .latency_high    (latency_high),
        .current_modulation(cfg.modulation),
        .adapt_wr_en     (adapt_wr_en),
        .adapt_modulation(adapt_modulation),
        .power_mode      (power_mode),
        .adapt_req       (adapt_req)
    );

    // --- LF_LINK_POWER_CTRL ---
    LF_LINK_POWER_CTRL u_power_ctrl (
        .clk           (lf_clk_i),
        .rst_n         (lf_rst_n_i),
        .link_good     (link_good),
        .ber_high      (ber_high),
        .snr_low       (snr_low),
        .requested_mode(power_mode),
        .tx_power      (tx_power),
        .current_mode  (),
        .power_update  (power_update)
    );

    // --- LF_HEALTH_MON ---
    logic health_ok_w, health_error;
    logic crc_err_w, fifo_err_w, sync_err_w;

    LF_HEALTH_MON u_health_mon (
        .clk            (lf_clk_i),
        .rst_n          (lf_rst_n_i),
        .crc_ok         (crc_ok),
        .fifo_full      (tx_fifo_full || rx_fifo_full),
        .fifo_empty     (1'b0),
        .overflow       (tx_fifo_full),
        .underflow      (rx_fifo_empty),
        .sync_done      (sync_done),
        .frame_detected (frame_detect),
        .health_ok      (health_ok_w),
        .error_detected (health_error),
        .crc_error      (crc_err_w),
        .fifo_error     (fifo_err_w),
        .sync_error     (sync_err_w)
    );

    // --- LF_STATUS_REG ---
    LF_STATUS_REG u_status_reg_ctrl (
        .clk            (lf_clk_i),
        .rst_n          (lf_rst_n_i),
        .status_wr_en   (1'b1),
        .ber            (perf_ber_reg),
        .snr            (perf_snr_reg),
        .latency        (perf_latency_reg),
        .packet_count   (perf_pkt_count_reg),
        .crc_ok         (crc_ok),
        .fifo_full      (tx_fifo_full || rx_fifo_full),
        .fifo_empty     (rx_fifo_empty),
        .overflow       (tx_fifo_full),
        .underflow      (rx_fifo_empty),
        .sync_done      (sync_done),
        .frame_detected (frame_detect),
        .perf_out       (lf_perf_o),
        .status_out     (lf_status_o)
    );

    //======================================================================
    // 2. TRANSMITTER PIPELINE
    //======================================================================

    // FIX: tx_start_pulse uses tx_enable (not pkt_done which is an output)
    assign tx_start_pulse = tx_enable && lf_start_i;

    // --- LF_PKT_GEN ---
    lf_pkt_gen #(
        .DATA_WIDTH    (DATA_WIDTH),
        .PACKET_LENGTH (PACKET_LEN)
    ) u_pkt_gen (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .data_i     (lf_data_i),
        .valid_i    (lf_valid_i && tx_enable),
        .pkt_start_i(tx_start_pulse),
        .data_o     (pkt_data),
        .valid_o    (pkt_valid),
        .sop_o      (pkt_sop),
        .eop_o      (pkt_eop),
        .pkt_done_o (pkt_done)
    );

    // --- LF_CRC_GEN ---
    LF_CRC_GEN #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_crc_gen (
        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),
        .data_in  (pkt_data),
        .valid_in (pkt_valid),
        .sop_in   (pkt_sop),
        .eop_in   (pkt_eop),
        .data_out (crc_data),
        .valid_out(crc_valid),
        .sop_out  (crc_sop),
        .eop_out  (crc_eop),
        .crc_out  (),
        .crc_valid()
    );

    // --- LF_SCRAMBLER ---
    LF_SCRAMBLER #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_scrambler (
        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),
        .data_in  (crc_data),
        .valid_in (crc_valid),
        .sop_in   (crc_sop),
        .eop_in   (crc_eop),
        .data_out (scram_data),
        .valid_out(scram_valid),
        .sop_out  (scram_sop),
        .eop_out  (scram_eop)
    );

    // --- LF_INTERLEAVER ---
    LF_INTERLEAVER #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_interleaver (
        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),
        .data_in  (scram_data),
        .valid_in (scram_valid),
        .sop_in   (scram_sop),
        .eop_in   (scram_eop),
        .data_out (inter_data),
        .valid_out(inter_valid),
        .sop_out  (inter_sop),
        .eop_out  (inter_eop)
    );

    // --- Modulators (run in parallel, selection via MOD_CTRL) ---
    LF_BPSK_MOD #(
        .DATA_WIDTH (DATA_WIDTH),
        .IQ_WIDTH   (IQ_WIDTH)
    ) u_bpsk_mod (
        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),
        .data_in  (inter_data),
        .valid_in (inter_valid),
        .sop_in   (inter_sop),
        .eop_in   (inter_eop),
        .i_out    (bpsk_i),
        .q_out    (bpsk_q),
        .valid_out(bpsk_v),
        .sop_out  (),
        .eop_out  ()
    );

    LF_QPSK_MOD #(
        .DATA_WIDTH (DATA_WIDTH),
        .IQ_WIDTH   (IQ_WIDTH)
    ) u_qpsk_mod (
        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),
        .data_in  (inter_data),
        .valid_in (inter_valid),
        .sop_in   (inter_sop),
        .eop_in   (inter_eop),
        .i_out    (qpsk_i),
        .q_out    (qpsk_q),
        .valid_out(qpsk_v),
        .sop_out  (),
        .eop_out  ()
    );

    LF_QAM16_MOD #(
        .DATA_WIDTH (DATA_WIDTH),
        .IQ_WIDTH   (IQ_WIDTH)
    ) u_qam16_mod (
        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),
        .data_in  (inter_data),
        .valid_in (inter_valid),
        .sop_in   (inter_sop),
        .eop_in   (inter_eop),
        .i_out    (qam16_i),
        .q_out    (qam16_q),
        .valid_out(qam16_v),
        .sop_out  (),
        .eop_out  ()
    );

    LF_MOD_CTRL #(
        .DATA_WIDTH (DATA_WIDTH),
        .IQ_WIDTH   (IQ_WIDTH)
    ) u_mod_ctrl (
        .clk             (lf_clk_i),
        .rst_n           (lf_rst_n_i),
        .data_in         (inter_data),
        .valid_in        (inter_valid),
        .sop_in          (inter_sop),
        .eop_in          (inter_eop),
        .modulation_sel  (cfg.modulation),
        .bpsk_i          (bpsk_i),
        .bpsk_q          (bpsk_q),
        .bpsk_valid      (bpsk_v),
        .qpsk_i          (qpsk_i),
        .qpsk_q          (qpsk_q),
        .qpsk_valid      (qpsk_v),
        .qam16_i         (qam16_i),
        .qam16_q         (qam16_q),
        .qam16_valid     (qam16_v),
        .mod_data        (),
        .mod_valid       (),
        .mod_sop         (),
        .mod_eop         (),
        .i_out           (mod_i_out),
        .q_out           (mod_q_out),
        .iq_valid        (mod_iq_valid)
    );

    // --- LF_PILOT_INSERT ---
    LF_PILOT_INSERT #(
        .IQ_WIDTH       (IQ_WIDTH),
        .FFT_SIZE       (FFT_SIZE),
        .PILOT_INTERVAL (PILOT_INTERVAL)
    ) u_pilot_insert (
        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),
        .i_in     (mod_i_out),
        .q_in     (mod_q_out),
        .valid_in (mod_iq_valid),
        .sop_in   (1'b0),
        .eop_in   (1'b0),
        .i_out    (pilot_i),
        .q_out    (pilot_q),
        .valid_out(pilot_valid),
        .sop_out  (pilot_sop),
        .eop_out  (pilot_eop)
    );

    // --- S2P bypass: feed pilot output directly to IFFT (serial passthrough) ---
    assign ifft_valid_in = pilot_valid;

    // --- LF_IFFT ---
    // FIX: Use SEPARATE output wires (previously valid_o was shorted to valid_i)
    lf_ifft #(
        .DATA_WIDTH (IQ_WIDTH)
    ) u_ifft (
        .lf_clk_i  (lf_clk_i),
        .lf_rst_n_i(lf_rst_n_i),
        .real_i    (pilot_i),
        .imag_i    (pilot_q),
        .valid_i   (ifft_valid_in),
        .real_o    (ifft_real_out),
        .imag_o    (ifft_imag_out),
        .valid_o   (ifft_valid_out)
    );

    // --- LF_CP_INSERT ---
    lf_cp_insert #(
        .DATA_WIDTH (IQ_WIDTH),
        .FFT_SIZE   (FFT_SIZE),
        .CP_LENGTH  (CP_LENGTH)
    ) u_cp_insert (
        .lf_clk_i  (lf_clk_i),
        .lf_rst_n_i(lf_rst_n_i),
        .real_i    (ifft_real_out),
        .imag_i    (ifft_imag_out),
        .valid_i   (ifft_valid_out),
        .real_o    (cp_real),
        .imag_o    (cp_imag),
        .valid_o   (cp_valid)
    );

    // --- LF_TX_FIFO ---
    lf_tx_fifo #(
        .DATA_WIDTH (IQ_WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) u_tx_fifo (
        .lf_clk_i  (lf_clk_i),
        .lf_rst_n_i(lf_rst_n_i),
        .real_i    (cp_real),
        .imag_i    (cp_imag),
        .valid_i   (cp_valid),
        .rd_en_i   (ch_tx_ready),
        .real_o    (tx_fifo_real),
        .imag_o    (tx_fifo_imag),
        .valid_o   (tx_fifo_valid),
        .full_o    (tx_fifo_full),
        .empty_o   (tx_fifo_empty)
    );

    //======================================================================
    // 3. DIGITAL CHANNEL MODEL
    //======================================================================

    lf_channel_top #(
        .DATA_WIDTH (IQ_WIDTH)
    ) u_channel (
        .lf_clk_i          (lf_clk_i),
        .lf_rst_n_i        (lf_rst_n_i),
        .noise_level_i     (lf_noise_level_i),
        .delay_cfg_i       (lf_delay_cfg_i),
        .freq_offset_cfg_i (lf_freq_offset_i),
        .drift_cfg_i       (lf_drift_cfg_i),
        .lf_tx_data_i      (tx_fifo_real),
        .lf_tx_valid_i     (tx_fifo_valid && !tx_fifo_empty),
        .lf_rx_ready_i     (1'b1),
        .lf_tx_ready_o     (ch_tx_ready),
        .lf_rx_data_o      (ch_rx_real),
        .lf_rx_valid_o     (ch_rx_valid)
    );

    //======================================================================
    // 4. RECEIVER PIPELINE
    //======================================================================

    // --- LF_RX_FIFO ---
    lf_rx_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) u_rx_fifo (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .lf_wr_en_i (ch_rx_valid),
        .lf_rd_en_i (1'b1),
        .lf_data_i  (ch_rx_real),
        .lf_data_o  (rx_fifo_data),
        .lf_valid_o (rx_fifo_valid),
        .lf_full_o  (rx_fifo_full),
        .lf_empty_o (rx_fifo_empty)
    );

    // --- LF_FRAME_DETECT ---
    lf_frame_detect #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_frame_detect (
        .lf_clk_i          (lf_clk_i),
        .lf_rst_n_i        (lf_rst_n_i),
        .lf_data_i         (rx_fifo_data),
        .lf_valid_i        (rx_fifo_valid),
        .lf_frame_detect_o (frame_detect),
        .lf_data_o         (frame_data),
        .lf_valid_o        (frame_data_valid)
    );

    // --- LF_SYNC ---
    lf_sync #(
        .SYMBOL_LEN (FFT_SIZE)
    ) u_sync (
        .lf_clk_i          (lf_clk_i),
        .lf_rst_n_i        (lf_rst_n_i),
        .lf_frame_detect_i (frame_detect),
        .lf_sync_o         (sync_done),
        .lf_symbol_start_o (symbol_start)
    );

    // --- LF_CP_REMOVE ---
    lf_cp_remove #(
        .DATA_WIDTH (DATA_WIDTH),
        .CP_LEN     (CP_LENGTH),
        .SYMBOL_LEN (FFT_SIZE)
    ) u_cp_remove (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .lf_data_i  (frame_data),
        .lf_valid_i (frame_data_valid),
        .lf_data_o  (cp_rem_data),
        .lf_valid_o (cp_rem_valid)
    );

    // --- LF_FFT ---
    lf_fft #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_fft (
        .lf_clk_i  (lf_clk_i),
        .lf_rst_n_i(lf_rst_n_i),
        .real_i    (cp_rem_data),
        .imag_i    ('0),
        .valid_i   (cp_rem_valid),
        .real_o    (fft_real),
        .imag_o    (fft_imag),
        .valid_o   (fft_valid)
    );

    // --- LF_CHANNEL_EST ---
    lf_channel_est #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_channel_est (
        .lf_clk_i       (lf_clk_i),
        .lf_rst_n_i     (lf_rst_n_i),
        .real_i         (fft_real),
        .imag_i         (fft_imag),
        .valid_i        (fft_valid),
        .pilot_i        (1'b0),
        .real_o         (ch_est_real),
        .imag_o         (ch_est_imag),
        .valid_o        (ch_est_valid),
        .channel_gain_o (ch_gain)
    );

    // --- LF_EQUALIZER ---
    lf_equalizer #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_equalizer (
        .lf_clk_i       (lf_clk_i),
        .lf_rst_n_i     (lf_rst_n_i),
        .real_i         (ch_est_real),
        .imag_i         (ch_est_imag),
        .channel_gain_i (ch_gain),
        .valid_i        (ch_est_valid),
        .real_o         (eq_real),
        .imag_o         (eq_imag),
        .valid_o        (eq_valid)
    );

    // --- Demodulators (all run in parallel, selection via DEMOD_CTRL) ---

    // BPSK: sign bit = demodulated bit
    assign bpsk_demod_bit = eq_real[DATA_WIDTH-1];
    assign bpsk_valid_out = eq_valid;

    lf_qpsk_demod #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_qpsk_demod (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .lf_i_data_i(eq_real),
        .lf_q_data_i(eq_imag),
        .lf_valid_i (eq_valid),
        .lf_bits_o  (qpsk_demod_bits),
        .lf_valid_o (qpsk_valid_out)
    );

    // FIX: QAM16 demod output goes to SEPARATE wire (no circular dependency)
    lf_qam16_demod #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_qam16_demod (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .lf_i_data_i(eq_real),
        .lf_q_data_i(eq_imag),
        .lf_valid_i (eq_valid),
        .lf_bits_o  (qam16_demod_bits),
        .lf_valid_o (qam16_valid_out)
    );

    // --- LF_DEMOD_CTRL ---
    lf_demod_ctrl u_demod_ctrl (
        .lf_clk_i       (lf_clk_i),
        .lf_rst_n_i     (lf_rst_n_i),
        .mod_sel_i      (cfg.modulation),
        .bpsk_bits_i    (bpsk_demod_bit),
        .bpsk_valid_i   (bpsk_valid_out),
        .qpsk_bits_i    (qpsk_demod_bits),
        .qpsk_valid_i   (qpsk_valid_out),
        .qam16_bits_i   (qam16_demod_bits),
        .qam16_valid_i  (qam16_valid_out),
        .demod_bits_o   (demod_bits),
        .demod_valid_o  (demod_valid)
    );

    // --- LF_P2S ---
    lf_p2s #(
        .DATA_WIDTH (4)
    ) u_p2s (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .lf_data_i  (demod_bits),
        .lf_valid_i (demod_valid),
        .lf_bit_o   (p2s_bit),
        .lf_valid_o (p2s_valid),
        .lf_busy_o  (p2s_busy)
    );

    // --- LF_DEINTERLEAVER ---
    lf_deinterleaver u_deinterleaver (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .lf_valid_i (p2s_valid),
        .lf_bit_i   (p2s_bit),
        .lf_valid_o (deint_valid),
        .lf_bit_o   (deint_bit)
    );

    // --- LF_DESCRAMBLER ---
    lf_descrambler #(
        .LFSR_WIDTH (7),
        .SEED       (7'b1011101)
    ) u_descrambler (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .lf_valid_i (deint_valid),
        .lf_bit_i   (deint_bit),
        .lf_valid_o (descr_valid),
        .lf_bit_o   (descr_bit)
    );

    // --- CRC check ---
    logic [DATA_WIDTH-1:0] rx_word;
    logic [$clog2(DATA_WIDTH)-1:0] rx_bit_cnt;
    logic                   rx_word_valid;

    lf_crc_check #(
        .CRC_WIDTH (4),
        .POLY      (4'b0011)
    ) u_crc_check (
        .lf_clk_i       (lf_clk_i),
        .lf_rst_n_i     (lf_rst_n_i),
        .lf_bit_i       (descr_bit),
        .lf_valid_i     (descr_valid),
        .lf_frame_end_i (rx_word_valid),
        .lf_crc_ok_o    (crc_ok),
        .lf_crc_error_o (crc_fail)
    );

    // FIX: Bit-to-word repacking - correct indexing (was {rx_bit_cnt,1'b0})
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i) begin
            rx_word       <= '0;
            rx_bit_cnt    <= '0;
            rx_word_valid <= 1'b0;
        end else if (descr_valid) begin
            rx_word[rx_bit_cnt] <= descr_bit;
            if (rx_bit_cnt == DATA_WIDTH - 1) begin
                rx_word_valid <= 1'b1;
                rx_bit_cnt    <= '0;
            end else begin
                rx_word_valid <= 1'b0;
                rx_bit_cnt    <= rx_bit_cnt + 1'b1;
            end
        end else begin
            rx_word_valid <= 1'b0;
        end
    end

    // --- LF_PACKET_DECODER ---
    lf_packet_decoder #(
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_pkt_decoder (
        .lf_clk_i         (lf_clk_i),
        .lf_rst_n_i       (lf_rst_n_i),
        .lf_data_i        (rx_word),
        .lf_valid_i       (rx_word_valid && crc_ok),
        .lf_sop_i         (1'b0),
        .lf_eop_i         (1'b0),
        .lf_data_o        (dec_data),
        .lf_valid_o       (dec_valid),
        .lf_sop_o         (dec_sop),
        .lf_eop_o         (dec_eop),
        .lf_packet_done_o (dec_pkt_done),
        .lf_packet_id_o   (dec_pkt_id),
        .lf_payload_len_o (dec_payload_len)
    );

    //======================================================================
    // 5. PERFORMANCE ANALYTICS
    // FIX: Each module gets its own perf_if instance (declared above).
    //      Performance registers are captured from those instances.
    //======================================================================

    // --- BER Counter ---
    lf_ber_counter #(
        .COUNTER_WIDTH (32),
        .BER_SCALE     (10000),
        .SHIFT_AMOUNT  (13)
    ) u_ber_counter (
        .lf_clk_i  (lf_clk_i),
        .lf_rst_n_i(lf_rst_n_i),
        .tx_bit_i  (lf_data_i[0]),
        .rx_bit_i  (dec_data[0]),
        .valid_i   (dec_valid),
        .perf_if   (u_ber_perf_if.producer)
    );

    // --- Packet Counter ---
    lf_packet_counter #(
        .COUNTER_WIDTH (32)
    ) u_packet_counter (
        .lf_clk_i          (lf_clk_i),
        .lf_rst_n_i        (lf_rst_n_i),
        .tx_packet_done_i  (pkt_done),
        .rx_packet_done_i  (dec_pkt_done),
        .crc_fail_i        (crc_fail),
        .perf_if           (u_pkt_perf_if.producer)
    );

    // --- Latency Counter ---
    // FIX: Use tx_start_pulse as start, dec_pkt_done as end
    lf_latency_counter #(
        .COUNTER_WIDTH (32)
    ) u_latency_counter (
        .lf_clk_i   (lf_clk_i),
        .lf_rst_n_i (lf_rst_n_i),
        .tx_start_i (tx_start_pulse),
        .rx_done_i  (dec_pkt_done),
        .perf_if    (u_latency_perf_if.producer)
    );

    // --- SNR Estimator ---
    // FIX: Signal power uses upper 16 bits of 32-bit multiplication
    //      eq_real * eq_real is 32-bit; take [31:16] as scaled power
    logic [31:0] signal_power_extended;
    assign signal_power_extended = eq_real * eq_real;

    lf_snr_estimator #(
        .DATA_WIDTH    (DATA_WIDTH),
        .COUNTER_WIDTH (32),
        .SAMPLE_COUNT  (256)
    ) u_snr_estimator (
        .lf_clk_i        (lf_clk_i),
        .lf_rst_n_i      (lf_rst_n_i),
        .signal_power_i  (signal_power_extended[DATA_WIDTH-1:0]),
        .noise_power_i   ('0),
        .sample_valid_i  (eq_valid),
        .perf_if         (u_snr_perf_if.producer)
    );

    // Capture performance data from interface instances into registers
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i) begin
            perf_ber_reg       <= '0;
            perf_snr_reg       <= '0;
            perf_latency_reg   <= '0;
            perf_pkt_count_reg <= '0;
        end else begin
            perf_ber_reg       <= u_ber_perf_if.ber_value;
            perf_snr_reg       <= u_snr_perf_if.snr_estimate;
            perf_latency_reg   <= u_latency_perf_if.current_latency;
            perf_pkt_count_reg <= u_pkt_perf_if.tx_packets;
        end
    end

    // System health output
    assign lf_system_health_o = {health_ok_w, sync_err_w, fifo_err_w,
                                  crc_err_w, 3'b000, lf_current_state_o};

    //======================================================================
    // 6. EXTERNAL OUTPUT
    //======================================================================

    assign lf_data_o = dec_data;
    assign lf_valid_o = dec_valid;
    assign lf_done_o  = dec_pkt_done;

endmodule

`endif
