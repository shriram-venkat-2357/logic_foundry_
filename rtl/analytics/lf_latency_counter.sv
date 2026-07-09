//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_latency_counter
//------------------------------------------------------------------------------
// Description:
// Measures packet latency in clock cycles.
//
// Current Latency : Cycles from TX Start to RX Done
// Maximum Latency : Highest observed latency
// Average Latency : Running average over all completed packets
//
// Synthesizable : YES
//==============================================================================

module lf_latency_counter #

(
    parameter COUNTER_WIDTH = 32
)

(

    input  logic lf_clk_i,
    input  logic lf_rst_n_i,

    // Start of packet transmission
    input  logic tx_start_i,

    // Packet successfully received
    input  logic rx_done_i,

    // Performance Interface
    lf_perf_if.producer perf_if

);

    //----------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------

    logic [COUNTER_WIDTH-1:0] cycle_counter;
    logic [COUNTER_WIDTH-1:0] current_latency;
    logic [COUNTER_WIDTH-1:0] max_latency;

    logic [COUNTER_WIDTH-1:0] latency_sum;
    logic [COUNTER_WIDTH-1:0] packet_count;

    logic measuring;

    //----------------------------------------------------------------------
    // Latency Measurement
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            cycle_counter   <= '0;
            current_latency <= '0;
            max_latency     <= '0;

            latency_sum     <= '0;
            packet_count    <= '0;

            measuring       <= 1'b0;

        end

        else
        begin

            //--------------------------------------------------------------
            // Start Measurement
            //--------------------------------------------------------------

            if(tx_start_i)
            begin

                measuring     <= 1'b1;
                cycle_counter <= '0;

            end

            //--------------------------------------------------------------
            // Count Cycles
            //--------------------------------------------------------------

            else if(measuring)
            begin

                cycle_counter <= cycle_counter + 1'b1;

            end

            //--------------------------------------------------------------
            // End Measurement
            //--------------------------------------------------------------

            if(measuring && rx_done_i)
            begin

                measuring       <= 1'b0;

                current_latency <= cycle_counter;

                latency_sum     <= latency_sum + cycle_counter;

                packet_count    <= packet_count + 1'b1;

                if(cycle_counter > max_latency)
                    max_latency <= cycle_counter;

            end

        end

    end

    //----------------------------------------------------------------------
    // Average Latency
    //----------------------------------------------------------------------

    wire [COUNTER_WIDTH-1:0] avg_latency;

    assign avg_latency =
        (packet_count != 0) ?
        (latency_sum / packet_count) :
        '0;

    //----------------------------------------------------------------------
    // Performance Interface
    //----------------------------------------------------------------------

    assign perf_if.current_latency = current_latency;

    assign perf_if.max_latency     = max_latency;

    assign perf_if.avg_latency     = avg_latency;

endmodule
