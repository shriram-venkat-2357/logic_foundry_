//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_snr_estimator
//------------------------------------------------------------------------------
// Description:
// Simplified SNR Estimator
//
// Estimates Signal-to-Noise Ratio using average signal and noise power.
//
// Estimated SNR = Avg Signal Power - Avg Noise Power
//
// NOTE:
// This is a simplified fixed-point estimator intended for RTL demonstration.
// It avoids logarithmic operations for ASIC synthesis.
//==============================================================================

module lf_snr_estimator # 

(
    parameter DATA_WIDTH    = 16,
    parameter COUNTER_WIDTH = 32,
    parameter SAMPLE_COUNT  = 256
)

(

    input  logic lf_clk_i,
    input  logic lf_rst_n_i,

    input  logic [DATA_WIDTH-1:0] signal_power_i,
    input  logic [DATA_WIDTH-1:0] noise_power_i,

    input  logic sample_valid_i,

    lf_perf_if.producer perf_if

);

    //----------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------

    logic [COUNTER_WIDTH-1:0] signal_sum;
    logic [COUNTER_WIDTH-1:0] noise_sum;

    logic [15:0] sample_counter;

    logic [DATA_WIDTH-1:0] avg_signal;
    logic [DATA_WIDTH-1:0] avg_noise;

    logic [DATA_WIDTH-1:0] snr_estimate;

    //----------------------------------------------------------------------
    // Accumulate Signal and Noise
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            signal_sum     <= '0;
            noise_sum      <= '0;
            sample_counter <= '0;

            avg_signal     <= '0;
            avg_noise      <= '0;

            snr_estimate   <= '0;

        end

        else
        begin

            if(sample_valid_i)
            begin

                signal_sum <= signal_sum + signal_power_i;
                noise_sum  <= noise_sum  + noise_power_i;

                sample_counter <= sample_counter + 1'b1;

                //----------------------------------------------------------
                // Compute Average Every SAMPLE_COUNT Samples
                //----------------------------------------------------------

                if(sample_counter == SAMPLE_COUNT-1)
                begin

                    // SAMPLE_COUNT=256, so >> 8 divides by 256
                    avg_signal <= signal_sum >> 8;
                    avg_noise  <= noise_sum  >> 8;

                    if(signal_sum > noise_sum)
                        snr_estimate <= (signal_sum >> 8) - (noise_sum >> 8);
                    else
                        snr_estimate <= '0;

                    signal_sum     <= '0;
                    noise_sum      <= '0;
                    sample_counter <= '0;

                end

            end

        end

    end

    //----------------------------------------------------------------------
    // Performance Interface
    //----------------------------------------------------------------------

    assign perf_if.snr_estimate = snr_estimate;

endmodule
