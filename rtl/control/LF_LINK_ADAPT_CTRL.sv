`timescale 1ns/1ps
`ifndef LF_LINK_ADAPT_CTRL_SV
`define LF_LINK_ADAPT_CTRL_SV

import LF_pkg::*;

module LF_LINK_ADAPT_CTRL
(
    input  logic clk,
    input  logic rst_n,

    //------------------------------------------------------------
    // Performance Monitor Inputs
    //------------------------------------------------------------
    input  logic link_good,
    input  logic ber_high,
    input  logic snr_low,
    input  logic latency_high,

    //------------------------------------------------------------
    // Current Configuration
    //------------------------------------------------------------
    input  mod_t current_modulation,

    //------------------------------------------------------------
    // Outputs to CFG_REG
    //------------------------------------------------------------
    output logic adapt_wr_en,
    output mod_t adapt_modulation,

    //------------------------------------------------------------
    // Outputs to Power Controller
    //------------------------------------------------------------
    output power_mode_t power_mode,

    //------------------------------------------------------------
    // Adaptation Request
    //------------------------------------------------------------
    output logic adapt_req

);

    //------------------------------------------------------------
    // Adaptation Logic
    //------------------------------------------------------------

    always_comb
    begin

        //--------------------------------------------------------
        // Defaults
        //--------------------------------------------------------

        adapt_wr_en      = 1'b0;
        adapt_modulation = current_modulation;
        power_mode       = POWER_NORMAL;
        adapt_req        = 1'b0;

        //--------------------------------------------------------
        // Poor Link
        //--------------------------------------------------------

        if(!link_good)
        begin

            adapt_req   = 1'b1;
            adapt_wr_en = 1'b1;

            //----------------------------------------------------
            // Highest Reliability
            //----------------------------------------------------

            if(ber_high)
            begin
                adapt_modulation = MOD_BPSK;
                power_mode       = POWER_HIGH;
            end

            //----------------------------------------------------
            // Medium Reliability
            //----------------------------------------------------

            else if(snr_low)
            begin
                adapt_modulation = MOD_QPSK;
                power_mode       = POWER_NORMAL;
            end

            //----------------------------------------------------
            // Latency Constraint
            //----------------------------------------------------

            else if(latency_high)
            begin
                adapt_modulation = MOD_QAM16;
                power_mode       = POWER_HIGH;
            end

        end

        //--------------------------------------------------------
        // Good Channel
        //--------------------------------------------------------

        else
        begin

            adapt_req        = 1'b0;
            adapt_wr_en      = 1'b0;
            adapt_modulation = MOD_QAM16;
            power_mode       = POWER_LOW;

        end

    end

endmodule

`endif