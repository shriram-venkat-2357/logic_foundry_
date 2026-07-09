//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_perf_mon
//------------------------------------------------------------------------------
// Description:
// Performance Monitor
//
// Collects performance statistics from all monitoring modules
// and generates a consolidated system health/status.
//==============================================================================

module lf_perf_mon
(

    input logic lf_clk_i,
    input logic lf_rst_n_i,

    lf_perf_if.consumer perf_if,

    output logic [31:0] system_health_o

);

    logic [31:0] health_reg;

        always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            health_reg <= 32'd0;

        end

        else
        begin

            //----------------------------------------------------------
            // Bit 0 : CRC Failure
            //----------------------------------------------------------

            health_reg[0] <= perf_if.crc_fail;

            //----------------------------------------------------------
            // Bit 1 : Synchronization Loss
            //----------------------------------------------------------

            health_reg[1] <= perf_if.sync_loss;

            //----------------------------------------------------------
            // Bit 2 : FIFO Overflow
            //----------------------------------------------------------

            health_reg[2] <= perf_if.fifo_overflow;

            //----------------------------------------------------------
            // Bit 3 : FIFO Underflow
            //----------------------------------------------------------

            health_reg[3] <= perf_if.fifo_underflow;

            //----------------------------------------------------------
            // Bit 4 : Frame Loss
            //----------------------------------------------------------

            health_reg[4] <= perf_if.frame_loss;

            //----------------------------------------------------------
            // Bit 5 : Receiver Busy
            //----------------------------------------------------------

            health_reg[5] <= perf_if.rx_busy;

            //----------------------------------------------------------
            // Bit 6 : Transmitter Busy
            //----------------------------------------------------------

            health_reg[6] <= perf_if.tx_busy;

            //----------------------------------------------------------
            // Bit 8:7 Current Modulation
            //----------------------------------------------------------

            health_reg[8:7] <= perf_if.modulation_mode;

            //----------------------------------------------------------
            // Remaining bits reserved
            //----------------------------------------------------------

            health_reg[31:9] <= '0;

        end

    end
    assign system_health_o = health_reg;

endmodule
