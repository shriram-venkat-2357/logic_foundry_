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
    // Latched error flags (pulse-capture, cleared only on reset
    // or explicit recovery)
    //------------------------------------------------------------

    logic crc_error_latched;
    logic fifo_error_latched;
    logic sync_error_latched;
    logic sync_was_ok;

    //------------------------------------------------------------
    // Track if sync was ever achieved (one-shot latch)
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            sync_was_ok <= 1'b0;
        else if(sync_done && frame_detected)
            sync_was_ok <= 1'b1;
    end

    //------------------------------------------------------------
    // Latch errors on first occurrence
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            crc_error_latched   <= 1'b0;
            fifo_error_latched  <= 1'b0;
            sync_error_latched  <= 1'b0;
        end
        else
        begin
            // Latch CRC error
            if(!crc_ok)
                crc_error_latched <= 1'b1;

            // Latch FIFO error
            if(overflow || underflow)
                fifo_error_latched <= 1'b1;

            // Latch sync loss ONLY after sync was once achieved
            // This prevents false errors during normal startup
            if(sync_was_ok && (!sync_done || !frame_detected))
                sync_error_latched <= 1'b1;
        end
    end

    //------------------------------------------------------------
    // Combinational error outputs
    //------------------------------------------------------------

    always_comb
    begin
        crc_error      = crc_error_latched;
        fifo_error     = fifo_error_latched;
        sync_error     = sync_error_latched;
        error_detected = crc_error || fifo_error || sync_error;
        health_ok      = !error_detected;
    end

endmodule

`endif