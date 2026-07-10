// channel/lf_channel_top.sv
module lf_channel_top #(
    parameter DATA_WIDTH = 16
)(
    input  logic                   lf_clk_i,
    input  logic                   lf_rst_n_i,

    // Configuration
    input  logic [7:0]             noise_level_i,
    input  logic [3:0]             delay_cfg_i,
    input  logic [7:0]             freq_offset_cfg_i,
    input  logic [7:0]             drift_cfg_i,

    // TX Side (from LF_TX_FIFO)
    input  logic [DATA_WIDTH-1:0]  lf_tx_data_i,
    input  logic                   lf_tx_valid_i,
    output logic                   lf_tx_ready_o,

    // RX Side (to LF_RX_FIFO)
    output logic [DATA_WIDTH-1:0]  lf_rx_data_o,
    output logic                   lf_rx_valid_o,
    input  logic                   lf_rx_ready_i
);

    // Internal wires
    logic [DATA_WIDTH-1:0] after_delay_data;
    logic                  after_delay_valid;
    logic                  after_delay_ready;

    logic [DATA_WIDTH-1:0] after_awgn_data;
    logic                  after_awgn_valid;
    logic                  after_awgn_ready;

    logic [DATA_WIDTH-1:0] after_freq_data;
    logic                  after_freq_valid;
    logic                  after_freq_ready;

    // Chain: DELAY -> AWGN -> FREQ_OFFSET -> CLOCK_DRIFT
    lf_delay #(.DATA_WIDTH(DATA_WIDTH)) u_delay (
        .lf_clk_i, .lf_rst_n_i,
        .delay_cfg_i(delay_cfg_i),
        .lf_data_i(lf_tx_data_i),   .lf_valid_i(lf_tx_valid_i), .lf_ready_o(lf_tx_ready_o),
        .lf_data_o(after_delay_data), .lf_valid_o(after_delay_valid), .lf_ready_i(after_delay_ready)
    );

    lf_awgn #(.DATA_WIDTH(DATA_WIDTH)) u_awgn (
        .lf_clk_i, .lf_rst_n_i,
        .noise_level_i(noise_level_i),
        .lf_data_i(after_delay_data),   .lf_valid_i(after_delay_valid), .lf_ready_o(after_delay_ready),
        .lf_data_o(after_awgn_data), .lf_valid_o(after_awgn_valid), .lf_ready_i(after_awgn_ready)
    );

    lf_freq_offset #(.DATA_WIDTH(DATA_WIDTH)) u_freq (
        .lf_clk_i, .lf_rst_n_i,
        .freq_offset_cfg_i(freq_offset_cfg_i),
        .lf_data_i(after_awgn_data),   .lf_valid_i(after_awgn_valid), .lf_ready_o(after_awgn_ready),
        .lf_data_o(after_freq_data), .lf_valid_o(after_freq_valid), .lf_ready_i(after_freq_ready)
    );

    // Clock drift applied as final stage
    lf_clock_drift #(.DATA_WIDTH(DATA_WIDTH)) u_drift (
        .lf_clk_i, .lf_rst_n_i,
        .drift_cfg_i(drift_cfg_i),
        .lf_data_i(after_freq_data),   .lf_valid_i(after_freq_valid), .lf_ready_o(after_freq_ready),
        .lf_data_o(lf_rx_data_o),   .lf_valid_o(lf_rx_valid_o), .lf_ready_i(lf_rx_ready_i)
    );

endmodule
