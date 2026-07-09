`timescale 1ns/1ps
`ifndef LF_STATUS_IF_SV
`define LF_STATUS_IF_SV

import LF_pkg::*;

interface LF_status_if
(
    input logic clk,
    input logic rst_n
);

    //------------------------------------------------------------
    // Performance Metrics
    //------------------------------------------------------------

    logic [BER_WIDTH-1:0] ber;
    logic [SNR_WIDTH-1:0] snr;

    logic [31:0] latency;
    logic [31:0] packet_count;

    //------------------------------------------------------------
    // Health Status
    //------------------------------------------------------------

    logic crc_ok;
    logic fifo_full;
    logic fifo_empty;
    logic overflow;
    logic underflow;

    logic sync_done;
    logic frame_detected;

    //------------------------------------------------------------
    // Status Handshake
    //------------------------------------------------------------

    logic status_valid;
    logic status_ready;

    //------------------------------------------------------------
    // Performance Analytics (Producer)
    //------------------------------------------------------------

    modport producer
    (
        output ber,
        output snr,
        output latency,
        output packet_count,

        output crc_ok,
        output fifo_full,
        output fifo_empty,
        output overflow,
        output underflow,
        output sync_done,
        output frame_detected,

        output status_valid,

        input status_ready
    );

    //------------------------------------------------------------
    // Intelligent Control Layer (Consumer)
    //------------------------------------------------------------

    modport consumer
    (
        input ber,
        input snr,
        input latency,
        input packet_count,

        input crc_ok,
        input fifo_full,
        input fifo_empty,
        input overflow,
        input underflow,
        input sync_done,
        input frame_detected,

        input status_valid,

        output status_ready
    );

endinterface

`endif