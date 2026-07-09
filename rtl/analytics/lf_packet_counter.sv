//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_packet_counter
//------------------------------------------------------------------------------
// Description:
// Packet Counter
//
// Counts:
//  - Transmitted Packets
//  - Successfully Received Packets
//  - Lost Packets (CRC Failures)
//
// Synthesizable : YES
//==============================================================================

module lf_packet_counter #

(
    parameter COUNTER_WIDTH = 32
)

(
    input  logic lf_clk_i,
    input  logic lf_rst_n_i,

    // Packet Events
    input  logic tx_packet_done_i,
    input  logic rx_packet_done_i,
    input  logic crc_fail_i,

    // Performance Interface
    lf_perf_if.producer perf_if

);

    //--------------------------------------------------------------------------
    // Internal Registers
    //--------------------------------------------------------------------------

    logic [COUNTER_WIDTH-1:0] tx_packet_cnt;
    logic [COUNTER_WIDTH-1:0] rx_packet_cnt;
    logic [COUNTER_WIDTH-1:0] lost_packet_cnt;

    //--------------------------------------------------------------------------
    // Packet Counters
    //--------------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if (!lf_rst_n_i)
        begin
            tx_packet_cnt   <= '0;
            rx_packet_cnt   <= '0;
            lost_packet_cnt <= '0;
        end

        else
        begin

            if (tx_packet_done_i)
                tx_packet_cnt <= tx_packet_cnt + 1'b1;

            if (rx_packet_done_i)
                rx_packet_cnt <= rx_packet_cnt + 1'b1;

            if (crc_fail_i)
                lost_packet_cnt <= lost_packet_cnt + 1'b1;

        end

    end

    //--------------------------------------------------------------------------
    // Performance Interface Outputs
    //--------------------------------------------------------------------------

    assign perf_if.tx_packets   = tx_packet_cnt;
    assign perf_if.rx_packets   = rx_packet_cnt;
    assign perf_if.lost_packets = lost_packet_cnt;

endmodule
