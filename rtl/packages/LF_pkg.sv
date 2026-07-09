`timescale 1ns/1ps
`ifndef LF_PKG_SV
`define LF_PKG_SV

package LF_pkg;

  //------------------------------------------------------------
  // Modulation Types
  //------------------------------------------------------------
  typedef enum logic [2:0] {
    MOD_BPSK = 3'b000,
    MOD_QPSK = 3'b001,
    MOD_16QAM = 3'b010
  } modulation_type_e;

  //------------------------------------------------------------
  // FFT/IFFT Sizes
  //------------------------------------------------------------
  typedef enum logic [3:0] {
    FFT_SIZE_64   = 4'b0110,   // log2(64) = 6
    FFT_SIZE_128  = 4'b0111,   // log2(128) = 7
    FFT_SIZE_256  = 4'b1000    // log2(256) = 8
  } fft_size_e;

  //------------------------------------------------------------
  // Status Codes
  //------------------------------------------------------------
  typedef enum logic [3:0] {
    STATUS_IDLE      = 4'h0,
    STATUS_TX_ACTIVE = 4'h1,
    STATUS_RX_ACTIVE = 4'h2,
    STATUS_ERROR     = 4'hF
  } status_code_e;

  //------------------------------------------------------------
  // Configuration Structure
  //------------------------------------------------------------
  typedef struct packed {
    logic [2:0]  modulation;       // modulation_type_e
    logic [3:0]  fft_size;         // fft_size_e
    logic [15:0] packet_length;
    logic        crc_enable;
    logic        scrambler_enable;
    logic        interleaver_enable;
  } lf_config_t;

  //------------------------------------------------------------
  // Status Structure
  //------------------------------------------------------------
  typedef struct packed {
    logic [3:0]  state;            // status_code_e
    logic [15:0] error_flags;
    logic [31:0] packet_count;
  } lf_status_t;

endpackage : LF_pkg

`endif
