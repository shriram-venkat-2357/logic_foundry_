`timescale 1ns/1ps
`ifndef LF_HEALTH_MON_SV
`define LF_HEALTH_MON_SV

module LF_HEALTH_MON
(
    input  logic clk,
    input  logic rst_n,

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
    output logic health_ok,
    output logic error_detected,

    output logic crc_error,
    output logic fifo_error,
    output logic sync_error
);

    //------------------------------------------------------------
    // Health Monitoring
    //------------------------------------------------------------

    always_comb
    begin

        //--------------------------------------------------------
        // Default Outputs
        //--------------------------------------------------------

        crc_error      = 1'b0;
        fifo_error     = 1'b0;
        sync_error     = 1'b0;
        error_detected = 1'b0;
        health_ok      = 1'b1;

        //--------------------------------------------------------
        // CRC Check
        //--------------------------------------------------------

        if(!crc_ok)
            crc_error = 1'b1;

        //--------------------------------------------------------
        // FIFO Check
        //--------------------------------------------------------

        if(overflow || underflow)
            fifo_error = 1'b1;

        //--------------------------------------------------------
        // Synchronization Check
        //--------------------------------------------------------

        if(!sync_done || !frame_detected)
            sync_error = 1'b1;

        //--------------------------------------------------------
        // Overall Health
        //--------------------------------------------------------

        if(crc_error || fifo_error || sync_error)
        begin
            error_detected = 1'b1;
            health_ok      = 1'b0;
        end

    end

endmodule

`endif