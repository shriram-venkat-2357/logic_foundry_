`timescale 1ns/1ps
`ifndef LF_PERF_MON_SV
`define LF_PERF_MON_SV

import LF_pkg::*;

module LF_PERF_MON
(
    input  logic clk,
    input  logic rst_n,

    //------------------------------------------------------------
    // Performance Inputs
    //------------------------------------------------------------
    input logic [BER_WIDTH-1:0] ber,
    input logic [SNR_WIDTH-1:0] snr,
    input logic [31:0] latency,
    input logic [31:0] packet_count,

    //------------------------------------------------------------
    // Thresholds
    //------------------------------------------------------------
    input logic [BER_WIDTH-1:0] ber_threshold,
    input logic [SNR_WIDTH-1:0] snr_threshold,

    //------------------------------------------------------------
    // Outputs
    //------------------------------------------------------------
    output logic link_good,
    output logic ber_high,
    output logic snr_low,
    output logic latency_high,
    output logic perf_valid

);

    //------------------------------------------------------------
    // Local Parameters
    //------------------------------------------------------------

    localparam int LATENCY_LIMIT = 1000;

    //------------------------------------------------------------
    // Performance Evaluation
    //------------------------------------------------------------

    always_comb
    begin

        //--------------------------------------------------------
        // Default
        //--------------------------------------------------------

        ber_high      = 1'b0;
        snr_low       = 1'b0;
        latency_high  = 1'b0;
        link_good     = 1'b1;
        perf_valid    = 1'b1;

        //--------------------------------------------------------
        // BER
        //--------------------------------------------------------

        if(ber > ber_threshold)
            ber_high = 1'b1;

        //--------------------------------------------------------
        // SNR
        //--------------------------------------------------------

        if(snr < snr_threshold)
            snr_low = 1'b1;

        //--------------------------------------------------------
        // Latency
        //--------------------------------------------------------

        if(latency > LATENCY_LIMIT)
            latency_high = 1'b1;

        //--------------------------------------------------------
        // Overall Link Quality
        //--------------------------------------------------------

        if(ber_high || snr_low || latency_high)
            link_good = 1'b0;

    end

endmodule

`endif