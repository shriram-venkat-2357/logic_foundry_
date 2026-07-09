`timescale 1ns/1ps
`ifndef LF_STATUS_REG_SV
`define LF_STATUS_REG_SV

import LF_pkg::*;

module LF_STATUS_REG
(
    input  logic               clk,
    input  logic               rst_n,

    //------------------------------------------------------------
    // Update Enable
    //------------------------------------------------------------
    input  logic               status_wr_en,

    //------------------------------------------------------------
    // Performance Inputs
    //------------------------------------------------------------
    input  logic [BER_WIDTH-1:0] ber,
    input  logic [SNR_WIDTH-1:0] snr,

    input  logic [31:0]          latency,
    input  logic [31:0]          packet_count,

    //------------------------------------------------------------
    // Health Inputs
    //------------------------------------------------------------
    input  logic crc_ok,
    input  logic fifo_full,
    input  logic fifo_empty,
    input  logic overflow,
    input  logic underflow,
    input  logic sync_done,
    input  logic frame_detected,

    //------------------------------------------------------------
    // Outputs
    //------------------------------------------------------------
    output perf_t   perf_out,
    output status_t status_out

);

    //------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------

    perf_t   perf_reg;
    status_t status_reg;

    //------------------------------------------------------------
    // Register Update
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            perf_reg   <= '0;
            status_reg <= '0;

        end

        else if(status_wr_en)
        begin

            //----------------------------------------------------
            // Performance
            //----------------------------------------------------

            perf_reg.ber          <= ber;
            perf_reg.snr          <= snr;
            perf_reg.latency      <= latency;
            perf_reg.packet_count <= packet_count;

            //----------------------------------------------------
            // Status
            //----------------------------------------------------

            status_reg.crc_ok         <= crc_ok;
            status_reg.fifo_full      <= fifo_full;
            status_reg.fifo_empty     <= fifo_empty;
            status_reg.sync_done      <= sync_done;
            status_reg.frame_detected <= frame_detected;
            status_reg.overflow       <= overflow;
            status_reg.underflow      <= underflow;

        end

    end

    //------------------------------------------------------------
    // Outputs
    //------------------------------------------------------------

    assign perf_out   = perf_reg;
    assign status_out = status_reg;

endmodule

`endif