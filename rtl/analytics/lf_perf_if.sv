//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_perf_if
//------------------------------------------------------------------------------
// Description:
// Performance Monitoring Interface
//
// Shared interface for exchanging communication performance metrics between
// BER Counter, Packet Counter, Latency Counter, SNR Estimator,
// Performance Monitor and Status Register.
//==============================================================================

interface lf_perf_if #(

    parameter BER_WIDTH      = 32,
    parameter PACKET_WIDTH   = 32,
    parameter LATENCY_WIDTH  = 32,
    parameter SNR_WIDTH      = 16

);

    //----------------------------------------------------------------------
    // BER Statistics
    //----------------------------------------------------------------------

    logic [BER_WIDTH-1:0] bit_errors;
    logic [BER_WIDTH-1:0] total_bits;
    logic [15:0]          ber_value;

    //----------------------------------------------------------------------
    // Packet Statistics
    //----------------------------------------------------------------------

    logic [PACKET_WIDTH-1:0] tx_packets;
    logic [PACKET_WIDTH-1:0] rx_packets;
    logic [PACKET_WIDTH-1:0] lost_packets;

    //----------------------------------------------------------------------
    // Latency Statistics
    //----------------------------------------------------------------------

    logic [LATENCY_WIDTH-1:0] current_latency;
    logic [LATENCY_WIDTH-1:0] max_latency;
    logic [LATENCY_WIDTH-1:0] avg_latency;

    //----------------------------------------------------------------------
    // Channel Quality
    //----------------------------------------------------------------------

    logic [SNR_WIDTH-1:0] snr_estimate;

    //----------------------------------------------------------------------
    // CRC Statistics
    //----------------------------------------------------------------------

    logic crc_pass;
    logic crc_fail;

    //----------------------------------------------------------------------
    // Receiver Health
    //----------------------------------------------------------------------

    logic fifo_overflow;
    logic fifo_underflow;

    logic sync_loss;
    logic frame_loss;

    //----------------------------------------------------------------------
    // Link Information
    //----------------------------------------------------------------------

    logic [1:0] modulation_mode;

    logic tx_busy;
    logic rx_busy;

    //----------------------------------------------------------------------
    // Overall Status
    //----------------------------------------------------------------------

    logic perf_valid;

    //----------------------------------------------------------------------
    // Modports
    //----------------------------------------------------------------------

    // Producer (Performance Modules)

    modport producer(

        output bit_errors,
        output total_bits,
        output ber_value,

        output tx_packets,
        output rx_packets,
        output lost_packets,

        output current_latency,
        output max_latency,
        output avg_latency,

        output snr_estimate,

        output crc_pass,
        output crc_fail,

        output fifo_overflow,
        output fifo_underflow,

        output sync_loss,
        output frame_loss,

        output modulation_mode,

        output tx_busy,
        output rx_busy,

        output perf_valid

    );

    // Consumer (Performance Monitor / Status Register)

    modport consumer(

        input bit_errors,
        input total_bits,
        input ber_value,

        input tx_packets,
        input rx_packets,
        input lost_packets,

        input current_latency,
        input max_latency,
        input avg_latency,

        input snr_estimate,

        input crc_pass,
        input crc_fail,

        input fifo_overflow,
        input fifo_underflow,

        input sync_loss,
        input frame_loss,

        input modulation_mode,

        input tx_busy,
        input rx_busy,

        input perf_valid

    );

endinterface