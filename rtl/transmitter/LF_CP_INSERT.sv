//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_cp_insert
//------------------------------------------------------------------------------
// Description:
// Cyclic Prefix Inserter
//
// Copies the last CP_LENGTH samples of an OFDM symbol to the beginning.
//
// Example:
//
// Original
// --------------------------------
// S0 S1 S2 ... S61 S62 S63
//
// After CP
// --------------------------------
// S48...S63 S0 S1 ... S63
//
//==============================================================================

module lf_cp_insert #

(
    parameter DATA_WIDTH = 16,
    parameter FFT_SIZE   = 64,
    parameter CP_LENGTH  = 16
)

(

input logic lf_clk_i,
input logic lf_rst_n_i,

input logic signed [DATA_WIDTH-1:0] real_i,
input logic signed [DATA_WIDTH-1:0] imag_i,

input logic valid_i,

output logic signed [DATA_WIDTH-1:0] real_o,
output logic signed [DATA_WIDTH-1:0] imag_o,

output logic valid_o

);

    //----------------------------------------------------------------------
    // Buffer
    //----------------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0] real_mem [0:FFT_SIZE-1];
    logic signed [DATA_WIDTH-1:0] imag_mem [0:FFT_SIZE-1];

    //----------------------------------------------------------------------
    // Counters
    //----------------------------------------------------------------------

    logic [$clog2(FFT_SIZE)-1:0] wr_ptr;
    logic [$clog2(FFT_SIZE+CP_LENGTH)-1:0] rd_ptr;

    logic frame_ready;

    //----------------------------------------------------------------------
    // Store IFFT Output
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            wr_ptr      <= '0;
            frame_ready <= 1'b0;

        end

        else
        begin

            if(valid_i)
            begin

                real_mem[wr_ptr] <= real_i;
                imag_mem[wr_ptr] <= imag_i;

                if(wr_ptr == FFT_SIZE-1)
                begin
                    wr_ptr      <= '0;
                    frame_ready <= 1'b1;
                end
                else
                begin
                    wr_ptr <= wr_ptr + 1'b1;
                end

            end

        end

    end

    //----------------------------------------------------------------------
    // CP Insert Logic
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            rd_ptr  <= '0;

            real_o  <= '0;
            imag_o  <= '0;

            valid_o <= 1'b0;

        end

        else if(frame_ready)
        begin

            valid_o <= 1'b1;

            //----------------------------------------------------------
            // Cyclic Prefix
            //----------------------------------------------------------

            if(rd_ptr < CP_LENGTH)
            begin

                real_o <= real_mem[FFT_SIZE-CP_LENGTH+rd_ptr];
                imag_o <= imag_mem[FFT_SIZE-CP_LENGTH+rd_ptr];

            end

            //----------------------------------------------------------
            // Original OFDM Symbol
            //----------------------------------------------------------

            else
            begin

                real_o <= real_mem[rd_ptr-CP_LENGTH];
                imag_o <= imag_mem[rd_ptr-CP_LENGTH];

            end

            //----------------------------------------------------------
            // Counter
            //----------------------------------------------------------

            if(rd_ptr == FFT_SIZE+CP_LENGTH-1)
            begin

                rd_ptr      <= '0;
               

            end

            else
            begin

                rd_ptr <= rd_ptr + 1'b1;

            end

        end

        else
        begin

            valid_o <= 1'b0;

        end

    end

endmodule