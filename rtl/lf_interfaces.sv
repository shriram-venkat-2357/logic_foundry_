// rtl/lf_interfaces.sv
// SHARED INTERFACE DEFINITIONS - ALL MEMBERS USE THIS FILE

// --- Data Stream Interface (Used by TX, RX, Channel, TB) ---
interface lf_stream_if #(parameter DATA_WIDTH = 16);
    logic [DATA_WIDTH-1:0] data;
    logic                  valid;
    logic                  ready;

    modport master (output data, valid, input  ready);
    modport slave  (input  data, valid, output ready);
endinterface

// --- Configuration Interface ---
interface lf_cfg_if;
    logic [2:0]  modulation_type;   // 0=BPSK, 1=QPSK, 2=16QAM
    logic [3:0]  fft_size;          // Log2: 6=64, 7=128, 8=256
    logic [15:0] packet_length;
    logic        crc_enable;
    logic        scrambler_enable;
    logic        interleaver_enable;
    logic        adaptive_mode_en;
    logic        power_save_en;
endinterface

// --- Status Interface ---
interface lf_status_if;
    logic        tx_busy;
    logic        rx_busy;
    logic [2:0]  current_modulation;
    logic [3:0]  current_fft_size;
    logic [31:0] packet_count;
    logic [31:0] error_count;
    logic [15:0] ber;               // Scaled BER (x10000)
    logic [15:0] snr;               // Estimated SNR (x100)
endinterface

// --- Performance Interface ---
interface lf_perf_if;
    logic [31:0] total_bits;
    logic [31:0] bit_errors;
    logic [31:0] packets_sent;
    logic [31:0] packets_received;
    logic [31:0] crc_failures;
    logic [31:0] retry_count;
    logic [31:0] total_latency;
    logic [15:0] throughput;
endinterface

// --- Health Monitor Interface ---
interface lf_health_if;
    logic fifo_overflow;
    logic fifo_underflow;
    logic sync_loss;
    logic frame_loss;
    logic crc_failure;
    logic invalid_packet;
endinterface

// --- Channel Interface ---
interface lf_channel_if #(parameter DATA_WIDTH = 16);
    logic [DATA_WIDTH-1:0] tx_data;
    logic                  tx_valid;
    logic                  tx_ready;
    logic [DATA_WIDTH-1:0] rx_data;
    logic                  rx_valid;
    logic                  rx_ready;
endinterface
