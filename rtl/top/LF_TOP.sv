`timescale 1ns/1ps

//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : LF_TOP
//------------------------------------------------------------------------------
// Description:
// Top-level SDR module integrating transmitter, receiver, channel model,
// and control subsystems.
//==============================================================================

module LF_TOP (
    // Clock and Reset
    input  logic       clk_sys,
    input  logic       clk_rf,
    input  logic       rst_n,

    // Configuration Interface
    input  logic [2:0] modulation_type,
    input  logic [3:0] fft_size,
    input  logic [15:0] packet_length,
    input  logic       crc_enable,
    input  logic       scrambler_enable,
    input  logic       interleaver_enable,

    // TX Side
    input  logic [15:0] tx_data,
    input  logic       tx_valid,
    output logic       tx_ready,

    // RX Side
    output logic [15:0] rx_data,
    output logic       rx_valid,
    input  logic       rx_ready,

    // Status Interface
    output logic [31:0] status_flags,
    output logic [31:0] error_count,
    output logic [31:0] packet_count
);

  //--------------------------------------------------------------------
  // Reset Synchronizer
  //--------------------------------------------------------------------

  logic rst_sync_n;

  LF_RESET_SYNC u_reset_sync (
    .clk       (clk_sys),
    .rst_n_in  (rst_n),
    .rst_n_out (rst_sync_n)
  );

  //--------------------------------------------------------------------
  // Channel Model (Loopback)
  //--------------------------------------------------------------------
  // For now, channel is a direct connection (loopback)
  // Will be replaced with lf_channel_top when fully integrated

  logic [15:0] tx_to_ch_data;
  logic        tx_to_ch_valid;
  logic        tx_to_ch_ready;

  logic [15:0] ch_to_rx_data;
  logic        ch_to_rx_valid;
  logic        ch_to_rx_ready;

  // Simple loopback for now
  assign ch_to_rx_data  = tx_to_ch_data;
  assign ch_to_rx_valid = tx_to_ch_valid;
  assign tx_to_ch_ready = ch_to_rx_ready;

  //--------------------------------------------------------------------
  // Status Monitoring
  //--------------------------------------------------------------------
  // Placeholder for actual monitoring logic
  always_ff @(posedge clk_sys or negedge rst_sync_n) begin
    if (!rst_sync_n) begin
      packet_count <= '0;
      error_count  <= '0;
      status_flags <= '0;
    end else begin
      // Will be connected to performance monitor module
      status_flags <= 32'h0000_0000;  // IDLE
      // packet_count and error_count updated by performance monitor
    end
  end

  //--------------------------------------------------------------------
  // TX Path (Placeholder)
  //--------------------------------------------------------------------
  assign tx_to_ch_data  = tx_data;
  assign tx_to_ch_valid = tx_valid;
  assign tx_ready       = tx_to_ch_ready;

  //--------------------------------------------------------------------
  // RX Path (Placeholder)
  //--------------------------------------------------------------------
  assign rx_data  = ch_to_rx_data;
  assign rx_valid = ch_to_rx_valid;
  assign ch_to_rx_ready = rx_ready;

endmodule : LF_TOP
