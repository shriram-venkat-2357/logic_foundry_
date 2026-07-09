`timescale 1ns/1ps
`ifndef LF_LINK_POWER_CTRL_SV
`define LF_LINK_POWER_CTRL_SV

import LF_pkg::*;

module LF_LINK_POWER_CTRL
(
    input  logic clk,
    input  logic rst_n,

    //------------------------------------------------------------
    // Link Status
    //------------------------------------------------------------
    input logic           link_good,
    input logic           ber_high,
    input logic           snr_low,

    //------------------------------------------------------------
    // Requested Power Mode
    //------------------------------------------------------------
    input power_mode_t    requested_mode,

    //------------------------------------------------------------
    // Outputs
    //------------------------------------------------------------
    output logic [7:0]    tx_power,
    output power_mode_t   current_mode,
    output logic          power_update

);

    //------------------------------------------------------------
    // Power Control Logic
    //------------------------------------------------------------

    always_comb
    begin

        //--------------------------------------------------------
        // Defaults
        //--------------------------------------------------------

        tx_power     = 8'd50;
        current_mode = POWER_NORMAL;
        power_update = 1'b0;

        //--------------------------------------------------------
        // Link Adaptation Request
        //--------------------------------------------------------

        case(requested_mode)

            //----------------------------------------------------
            // Low Power Mode
            //----------------------------------------------------

            POWER_LOW:
            begin
                tx_power     = 8'd25;
                current_mode = POWER_LOW;
                power_update = 1'b1;
            end

            //----------------------------------------------------
            // Normal Mode
            //----------------------------------------------------

            POWER_NORMAL:
            begin
                tx_power     = 8'd50;
                current_mode = POWER_NORMAL;
                power_update = 1'b1;
            end

            //----------------------------------------------------
            // High Performance Mode
            //----------------------------------------------------

            POWER_HIGH:
            begin
                tx_power     = 8'd100;
                current_mode = POWER_HIGH;
                power_update = 1'b1;
            end

            default:
            begin
                tx_power     = 8'd50;
                current_mode = POWER_NORMAL;
                power_update = 1'b0;
            end

        endcase

        //--------------------------------------------------------
        // Emergency Override
        //--------------------------------------------------------

        if(ber_high || snr_low)
        begin
            tx_power     = 8'd100;
            current_mode = POWER_HIGH;
            power_update = 1'b1;
        end

    end

endmodule

`endif