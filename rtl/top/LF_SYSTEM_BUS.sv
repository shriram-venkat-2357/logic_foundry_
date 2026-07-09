//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : LF_SYSTEM_BUS
//------------------------------------------------------------------------------
// Description:
// Simple system bus that broadcasts configuration from LF_CFG_REG
// to all subsystems. Provides a common clock/reset distribution point.
//
// FIX: This module was listed as missing in the architecture.
//      Implemented as a configuration fanout + clock/reset distribution.
//==============================================================================

`timescale 1ns/1ps
`ifndef LF_SYSTEM_BUS_SV
`define LF_SYSTEM_BUS_SV

import LF_pkg::*;

module LF_SYSTEM_BUS
#(
    parameter DATA_WIDTH = 16
)
(
    input  logic             clk,
    input  logic             rst_n,

    //------------------------------------------------------------
    // Configuration Input (from LF_CFG_REG)
    //------------------------------------------------------------
    input  cfg_t             cfg_i,
    input  logic             cfg_valid_i,

    //------------------------------------------------------------
    // Configuration Fanout Outputs
    //------------------------------------------------------------
    output cfg_t             cfg_tx_o,       // to transmitter
    output cfg_t             cfg_rx_o,       // to receiver
    output cfg_t             cfg_channel_o,  // to channel
    output cfg_t             cfg_analytics_o, // to analytics
    output logic             cfg_valid_o,

    //------------------------------------------------------------
    // Clock & Reset Distribution
    //------------------------------------------------------------
    output logic             sys_clk_o,
    output logic             sys_rst_n_o,

    //------------------------------------------------------------
    // System Status Aggregation
    //------------------------------------------------------------
    input  logic             tx_busy_i,
    input  logic             rx_busy_i,
    output logic             system_idle_o
);

    //------------------------------------------------------------
    // Configuration Broadcast
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            cfg_tx_o       <= cfg_t'{modulation: MOD_BPSK, tx_power: 8'd50,
                                       channel: 8'd1, packet_length: 16'd256};
            cfg_rx_o       <= cfg_tx_o;
            cfg_channel_o  <= cfg_tx_o;
            cfg_analytics_o <= cfg_tx_o;
            cfg_valid_o    <= 1'b0;
        end
        else
        begin
            cfg_tx_o        <= cfg_i;
            cfg_rx_o        <= cfg_i;
            cfg_channel_o   <= cfg_i;
            cfg_analytics_o <= cfg_i;
            cfg_valid_o     <= cfg_valid_i;
        end
    end

    //------------------------------------------------------------
    // Clock & Reset
    //------------------------------------------------------------

    assign sys_clk_o   = clk;
    assign sys_rst_n_o = rst_n;

    //------------------------------------------------------------
    // System Idle
    //------------------------------------------------------------

    assign system_idle_o = !(tx_busy_i || rx_busy_i);

endmodule

`endif