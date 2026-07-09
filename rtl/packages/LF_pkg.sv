`ifndef LF_PKG_SV
`define LF_PKG_SV

package LF_pkg;

//============================================================
// Global Parameters
//============================================================

parameter int DATA_WIDTH      = 16;
parameter int IQ_WIDTH        = 16;
parameter int CRC_WIDTH       = 16;
parameter int ADDR_WIDTH      = 8;

parameter int FIFO_DEPTH      = 256;
parameter int FFT_SIZE        = 64;
parameter int CP_LENGTH       = 16;

parameter int MAX_PKT_SIZE    = 1500;
parameter int PILOT_INTERVAL  = 4;

parameter int BER_WIDTH       = 16;
parameter int SNR_WIDTH       = 16;

//============================================================
// Modulation Types
//============================================================

// FIX: Added MOD_QAM64 (architecture doc references 64QAM)
// Using 2-bit enum: value 3 = 2'd3 maps to QAM64
typedef enum logic [1:0]
{
    MOD_BPSK   = 2'd0,
    MOD_QPSK   = 2'd1,
    MOD_QAM16  = 2'd2,
    MOD_QAM64  = 2'd3
} mod_t;

//============================================================
// Main Controller States
//============================================================

typedef enum logic [2:0]
{
    ST_RESET,
    ST_IDLE,
    ST_CONFIG,
    ST_TX,
    ST_RX,
    ST_MONITOR,
    ST_ERROR
} main_state_t;

//============================================================
// Link Quality
//============================================================

typedef enum logic [1:0]
{
    LINK_GOOD,
    LINK_FAIR,
    LINK_POOR
} link_state_t;

//============================================================
// Power Modes
//============================================================

typedef enum logic [1:0]
{
    POWER_LOW,
    POWER_NORMAL,
    POWER_HIGH
} power_mode_t;

//============================================================
// Status Flags
//============================================================

typedef struct packed
{
    logic crc_ok;
    logic fifo_full;
    logic fifo_empty;
    logic sync_done;
    logic frame_detected;
    logic overflow;
    logic underflow;

} status_t;

//============================================================
// Stream Packet
//============================================================

typedef struct packed
{
    logic [DATA_WIDTH-1:0] data;
    logic                  valid;
    logic                  sop;
    logic                  eop;
    logic                  error;

} stream_t;

//============================================================
// Configuration Register Structure
//============================================================

typedef struct packed
{
    mod_t                  modulation;
    logic [7:0]            tx_power;
    logic [7:0]            channel;
    logic [15:0]           packet_length;

} cfg_t;

//============================================================
// Performance Structure
//============================================================

typedef struct packed
{
    logic [BER_WIDTH-1:0]      ber;
    logic [SNR_WIDTH-1:0]      snr;
    logic [31:0]               latency;
    logic [31:0]               packet_count;

} perf_t;

//============================================================
// Utility Function
//============================================================

function automatic int lf_clog2(input int value);

    int i;

    begin

        value = value - 1;

        for(i=0; value>0; i=i+1)
            value = value >> 1;

        return i;

    end

endfunction

endpackage

`endif