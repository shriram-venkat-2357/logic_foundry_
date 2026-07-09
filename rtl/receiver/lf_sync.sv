//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_sync
//------------------------------------------------------------------------------
// Description:
// OFDM Symbol Synchronization
//
// Generates synchronization pulses for downstream blocks.
//
// Industry Style:
// - Parameterized Symbol Length
// - Registered Outputs
// - Counter Based Timing
//==============================================================================

module lf_sync #(

    parameter int SYMBOL_LEN = 16

)(

    input  logic lf_clk_i,
    input  logic lf_rst_n_i,

    input  logic lf_frame_detect_i,

    output logic lf_sync_o,
    output logic lf_symbol_start_o

);

    //----------------------------------------------------------
    // Counter
    //----------------------------------------------------------

    logic [$clog2(SYMBOL_LEN):0] symbol_count;

    //----------------------------------------------------------
    // Sequential Logic
    //----------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            symbol_count      <= '0;
            lf_sync_o         <= 1'b0;
            lf_symbol_start_o <= 1'b0;

        end

        else
        begin

            //--------------------------------------------------
            // Defaults
            //--------------------------------------------------

            lf_sync_o         <= 1'b0;
            lf_symbol_start_o <= 1'b0;

            //--------------------------------------------------
            // New Frame
            //--------------------------------------------------

            if(lf_frame_detect_i)
            begin

                symbol_count      <= 0;
                lf_sync_o         <= 1'b1;
                lf_symbol_start_o <= 1'b1;

            end

            //--------------------------------------------------
            // Symbol Tracking
            //--------------------------------------------------

            else
            begin

                if(symbol_count == SYMBOL_LEN-1)
                begin

                    symbol_count      <= 0;
                    lf_symbol_start_o <= 1'b1;

                end

                else
                begin

                    symbol_count <= symbol_count + 1'b1;

                end

            end

        end

    end

endmodule
