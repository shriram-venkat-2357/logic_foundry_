`timescale 1ns/1ps
`ifndef LF_CFG_REG_SV
`define LF_CFG_REG_SV

import LF_pkg::*;

module LF_CFG_REG
(
    input  logic          clk,
    input  logic          rst_n,

    //------------------------------------------------------------
    // Host Configuration Interface
    //------------------------------------------------------------
    input  logic          cfg_wr_en,
    input  cfg_t          cfg_in,

    //------------------------------------------------------------
    // Link Adaptation Override
    //------------------------------------------------------------
    input  logic          adapt_wr_en,
    input  mod_t          adapt_modulation,
    input  logic [7:0]    adapt_tx_power,

    //------------------------------------------------------------
    // Soft Reset
    //------------------------------------------------------------
    input  logic          soft_reset,

    //------------------------------------------------------------
    // Configuration Outputs
    //------------------------------------------------------------
    output cfg_t          cfg_out
);

    //------------------------------------------------------------
    // Internal Configuration Register
    //------------------------------------------------------------

    cfg_t cfg_reg;

    //------------------------------------------------------------
    // Register Logic
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            cfg_reg.modulation    <= MOD_BPSK;
            cfg_reg.tx_power      <= 8'd50;
            cfg_reg.channel       <= 8'd1;
            cfg_reg.packet_length <= 16'd256;

        end

        else if(soft_reset)
        begin

            cfg_reg.modulation    <= MOD_BPSK;
            cfg_reg.tx_power      <= 8'd50;
            cfg_reg.channel       <= 8'd1;
            cfg_reg.packet_length <= 16'd256;

        end

        //--------------------------------------------------------
        // Host Configuration
        //--------------------------------------------------------

        else if(cfg_wr_en)
        begin

            cfg_reg <= cfg_in;

        end

        //--------------------------------------------------------
        // Closed Loop Update
        //--------------------------------------------------------

        else if(adapt_wr_en)
        begin

            cfg_reg.modulation <= adapt_modulation;
            cfg_reg.tx_power   <= adapt_tx_power;

        end

    end

    //------------------------------------------------------------
    // Output
    //------------------------------------------------------------

    assign cfg_out = cfg_reg;

endmodule

`endif