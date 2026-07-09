//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : LF_INTERCONNECT
//------------------------------------------------------------------------------
// Description:
// Crossbar-style interconnect that routes performance data from
// analytics modules to the control layer's perf_if.
//
// FIX: This module was listed as missing in the architecture.
//      Implements a simple multiplexed interconnect for performance
//      signals, avoiding multi-driver contention on a shared bus.
//==============================================================================

`timescale 1ns/1ps
`ifndef LF_INTERCONNECT_SV
`define LF_INTERCONNECT_SV

import LF_pkg::*;

module LF_INTERCONNECT
#(
    parameter BER_WIDTH     = 32,
    parameter SNR_WIDTH     = 16,
    parameter COUNTER_WIDTH = 32
)
(
    input  logic                         clk,
    input  logic                         rst_n,

    //------------------------------------------------------------
    // BER Counter Inputs
    //------------------------------------------------------------
    input  logic [BER_WIDTH-1:0]         ber_bit_errors_i,
    input  logic [BER_WIDTH-1:0]         ber_total_bits_i,
    input  logic [15:0]                  ber_value_i,

    //------------------------------------------------------------
    // Packet Counter Inputs
    //------------------------------------------------------------
    input  logic [COUNTER_WIDTH-1:0]     tx_packets_i,
    input  logic [COUNTER_WIDTH-1:0]     rx_packets_i,
    input  logic [COUNTER_WIDTH-1:0]     lost_packets_i,

    //------------------------------------------------------------
    // Latency Inputs
    //------------------------------------------------------------
    input  logic [COUNTER_WIDTH-1:0]     current_latency_i,
    input  logic [COUNTER_WIDTH-1:0]     max_latency_i,
    input  logic [COUNTER_WIDTH-1:0]     avg_latency_i,

    //------------------------------------------------------------
    // SNR Input
    //------------------------------------------------------------
    input  logic [SNR_WIDTH-1:0]         snr_estimate_i,

    //------------------------------------------------------------
    // Health Inputs
    //------------------------------------------------------------
    input  logic                         crc_fail_i,
    input  logic                         sync_loss_i,
    input  logic                         fifo_overflow_i,
    input  logic                         fifo_underflow_i,
    input  logic                         frame_loss_i,

    //------------------------------------------------------------
    // Modulation Status
    //------------------------------------------------------------
    input  logic [1:0]                   modulation_mode_i,
    input  logic                         tx_busy_i,
    input  logic                         rx_busy_i,

    //------------------------------------------------------------
    // Merged Output (connects to control/status modules)
    //------------------------------------------------------------
    output logic [BER_WIDTH-1:0]         ber_bit_errors_o,
    output logic [BER_WIDTH-1:0]         ber_total_bits_o,
    output logic [15:0]                  ber_value_o,
    output logic [COUNTER_WIDTH-1:0]     tx_packets_o,
    output logic [COUNTER_WIDTH-1:0]     rx_packets_o,
    output logic [COUNTER_WIDTH-1:0]     lost_packets_o,
    output logic [COUNTER_WIDTH-1:0]     current_latency_o,
    output logic [COUNTER_WIDTH-1:0]     max_latency_o,
    output logic [COUNTER_WIDTH-1:0]     avg_latency_o,
    output logic [SNR_WIDTH-1:0]         snr_estimate_o,
    output logic                         crc_fail_o,
    output logic                         sync_loss_o,
    output logic                         fifo_overflow_o,
    output logic                         fifo_underflow_o,
    output logic                         frame_loss_o,
    output logic [1:0]                   modulation_mode_o,
    output logic                         tx_busy_o,
    output logic                         rx_busy_o,
    output logic                         perf_valid_o
);

    //------------------------------------------------------------
    // Simple pass-through with registered outputs
    // FIX: This avoids multi-driver contention by merging
    // all analytics signals in ONE place before fanout.
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            ber_bit_errors_o <= '0;
            ber_total_bits_o <= '0;
            ber_value_o      <= '0;
            tx_packets_o     <= '0;
            rx_packets_o     <= '0;
            lost_packets_o   <= '0;
            current_latency_o <= '0;
            max_latency_o    <= '0;
            avg_latency_o    <= '0;
            snr_estimate_o   <= '0;
            crc_fail_o       <= 1'b0;
            sync_loss_o      <= 1'b0;
            fifo_overflow_o  <= 1'b0;
            fifo_underflow_o <= 1'b0;
            frame_loss_o     <= 1'b0;
            modulation_mode_o <= 2'b0;
            tx_busy_o        <= 1'b0;
            rx_busy_o        <= 1'b0;
            perf_valid_o     <= 1'b0;
        end
        else
        begin
            ber_bit_errors_o <= ber_bit_errors_i;
            ber_total_bits_o <= ber_total_bits_i;
            ber_value_o      <= ber_value_i;
            tx_packets_o     <= tx_packets_i;
            rx_packets_o     <= rx_packets_i;
            lost_packets_o   <= lost_packets_i;
            current_latency_o <= current_latency_i;
            max_latency_o    <= max_latency_i;
            avg_latency_o    <= avg_latency_i;
            snr_estimate_o   <= snr_estimate_i;
            crc_fail_o       <= crc_fail_i;
            sync_loss_o      <= sync_loss_i;
            fifo_overflow_o  <= fifo_overflow_i;
            fifo_underflow_o <= fifo_underflow_i;
            frame_loss_o     <= frame_loss_i;
            modulation_mode_o <= modulation_mode_i;
            tx_busy_o        <= tx_busy_i;
            rx_busy_o        <= rx_busy_i;
            perf_valid_o     <= 1'b1;
        end
    end

endmodule

`endif