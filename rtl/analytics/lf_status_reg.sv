//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_status_reg
//------------------------------------------------------------------------------
// Description:
// Status Register Bank
//
// Captures performance statistics from the Performance Interface
// and stores them in internal registers for software/debug access.
//
// Synthesizable : YES
//==============================================================================

module lf_status_reg #

(
    parameter REG_WIDTH = 32
)

(

    input  logic lf_clk_i,
    input  logic lf_rst_n_i,

    // Performance Interface
    lf_perf_if.consumer perf_if,

    // Status Register Outputs
    output logic [REG_WIDTH-1:0] ber_o,
    output logic [REG_WIDTH-1:0] snr_o,

    output logic [REG_WIDTH-1:0] tx_packets_o,
    output logic [REG_WIDTH-1:0] rx_packets_o,
    output logic [REG_WIDTH-1:0] lost_packets_o,

    output logic [REG_WIDTH-1:0] current_latency_o,
    output logic [REG_WIDTH-1:0] max_latency_o,
    output logic [REG_WIDTH-1:0] avg_latency_o,

    output logic [REG_WIDTH-1:0] status_o

);

    //----------------------------------------------------------------------
    // Status Register Bank
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            ber_o              <= '0;
            snr_o              <= '0;

            tx_packets_o       <= '0;
            rx_packets_o       <= '0;
            lost_packets_o     <= '0;

            current_latency_o  <= '0;
            max_latency_o      <= '0;
            avg_latency_o      <= '0;

            status_o           <= '0;

        end

        else if(perf_if.perf_valid)
        begin

            //----------------------------------------------------------
            // Performance Metrics
            //----------------------------------------------------------

            ber_o             <= perf_if.ber_value;

            snr_o             <= perf_if.snr_estimate;

            tx_packets_o      <= perf_if.tx_packets;
            rx_packets_o      <= perf_if.rx_packets;
            lost_packets_o    <= perf_if.lost_packets;

            current_latency_o <= perf_if.current_latency;
            max_latency_o     <= perf_if.max_latency;
            avg_latency_o     <= perf_if.avg_latency;

            //----------------------------------------------------------
            // Status Register
            //----------------------------------------------------------

            status_o[0] <= perf_if.crc_fail;
            status_o[1] <= perf_if.sync_loss;
            status_o[2] <= perf_if.fifo_overflow;
            status_o[3] <= perf_if.fifo_underflow;
            status_o[4] <= perf_if.frame_loss;
            status_o[5] <= perf_if.rx_busy;
            status_o[6] <= perf_if.tx_busy;
            status_o[8:7] <= perf_if.modulation_mode;
            status_o[31:9] <= '0;

        end

    end

endmodule