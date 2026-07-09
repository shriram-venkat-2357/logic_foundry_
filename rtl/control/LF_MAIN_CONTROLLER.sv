`timescale 1ns/1ps
`ifndef LF_MAIN_CONTROLLER_SV
`define LF_MAIN_CONTROLLER_SV

import LF_pkg::*;

module LF_MAIN_CONTROLLER
(
    input  logic clk,
    input  logic rst_n,

    //------------------------------------------------------------
    // Configuration
    //------------------------------------------------------------
    input logic cfg_valid,

    //------------------------------------------------------------
    // Transmitter Status
    //------------------------------------------------------------
    input logic tx_done,

    //------------------------------------------------------------
    // Receiver Status
    //------------------------------------------------------------
    input logic rx_done,

    //------------------------------------------------------------
    // Health Status
    //------------------------------------------------------------
    input logic error_detected,

    //------------------------------------------------------------
    // Performance Monitor
    //------------------------------------------------------------
    input logic monitor_done,

    //------------------------------------------------------------
    // Outputs
    //------------------------------------------------------------
    output main_state_t current_state,

    output logic cfg_enable,
    output logic tx_enable,
    output logic rx_enable,
    output logic monitor_enable,
    output logic error_flag

);

    //------------------------------------------------------------
    // State Registers
    //------------------------------------------------------------

    main_state_t state;
    main_state_t next_state;

    //------------------------------------------------------------
    // State Register
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
            state <= ST_RESET;
        else
            state <= next_state;

    end

    //------------------------------------------------------------
    // Next State Logic
    //------------------------------------------------------------

    always_comb
    begin

        next_state = state;

        case(state)

            //----------------------------------------------------
            ST_RESET:
            //----------------------------------------------------
            begin

                next_state = ST_CONFIG;

            end

            //----------------------------------------------------
            ST_CONFIG:
            //----------------------------------------------------
            begin

                if(cfg_valid)
                    next_state = ST_IDLE;

            end

            //----------------------------------------------------
            ST_IDLE:
            //----------------------------------------------------
            begin

                if(error_detected)
                    next_state = ST_ERROR;
                else
                    next_state = ST_TX;

            end

            //----------------------------------------------------
            ST_TX:
            //----------------------------------------------------
            begin

                if(tx_done)
                    next_state = ST_RX;

            end

            //----------------------------------------------------
            ST_RX:
            //----------------------------------------------------
            begin

                if(rx_done)
                    next_state = ST_MONITOR;

            end

            //----------------------------------------------------
            ST_MONITOR:
            //----------------------------------------------------
            begin

                if(monitor_done)
                    next_state = ST_TX;

            end

            //----------------------------------------------------
            ST_ERROR:
            //----------------------------------------------------
            begin

                if(!error_detected)
                    next_state = ST_IDLE;

            end

            default:

                next_state = ST_RESET;

        endcase

    end

    //------------------------------------------------------------
    // Output Logic
    //------------------------------------------------------------

    always_comb
    begin

        cfg_enable     = 1'b0;
        tx_enable      = 1'b0;
        rx_enable      = 1'b0;
        monitor_enable = 1'b0;
        error_flag     = 1'b0;

        case(state)

            ST_CONFIG:
                cfg_enable = 1'b1;

            ST_TX:
                tx_enable = 1'b1;

            ST_RX:
                rx_enable = 1'b1;

            ST_MONITOR:
                monitor_enable = 1'b1;

            ST_ERROR:
                error_flag = 1'b1;

            default:
                ;

        endcase

    end

    //------------------------------------------------------------
    // Output State
    //------------------------------------------------------------

    assign current_state = state;

endmodule

`endif