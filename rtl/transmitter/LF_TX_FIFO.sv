//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_tx_fifo
//------------------------------------------------------------------------------
// Description:
// Transmit FIFO Wrapper
//
// Receives OFDM samples from CP Inserter
// Buffers them before DAC / RF Front-End
//
// Wrapper around LF_FIFO
//==============================================================================

module lf_tx_fifo #

(
    parameter DATA_WIDTH = 16,
    parameter FIFO_DEPTH = 64
)

(

input logic lf_clk_i,
input logic lf_rst_n_i,

//------------------------------------------------------------
// Write Side (CP Inserter)
//------------------------------------------------------------

input logic signed [DATA_WIDTH-1:0] real_i,
input logic signed [DATA_WIDTH-1:0] imag_i,

input logic valid_i,

//------------------------------------------------------------
// Read Side (DAC)
//------------------------------------------------------------

input logic rd_en_i,

output logic signed [DATA_WIDTH-1:0] real_o,
output logic signed [DATA_WIDTH-1:0] imag_o,

output logic valid_o,

output logic full_o,
output logic empty_o

);

    //----------------------------------------------------------------------
    // FIFO Packing
    //----------------------------------------------------------------------

    logic [2*DATA_WIDTH-1:0] fifo_din;
    logic [2*DATA_WIDTH-1:0] fifo_dout;

    logic wr_en;

    //----------------------------------------------------------------------
    // Pack IQ
    //----------------------------------------------------------------------

    assign fifo_din =
    {
        real_i,
        imag_i
    };

    assign wr_en = valid_i;

    //----------------------------------------------------------------------
    // Common FIFO
    //----------------------------------------------------------------------

    LF_FIFO #

    (
        .DATA_WIDTH (2*DATA_WIDTH),
        .DEPTH      (FIFO_DEPTH)

    )

    u_tx_fifo

    (

        .clk      (lf_clk_i),
        .rst_n    (lf_rst_n_i),

        .wr_en    (wr_en),
        .rd_en    (rd_en_i),

        .wr_data  (fifo_din),
        .rd_data  (fifo_dout),

        .full     (full_o),
        .empty    (empty_o)

    );

    //----------------------------------------------------------------------
    // Unpack IQ
    //----------------------------------------------------------------------

    assign real_o = fifo_dout[2*DATA_WIDTH-1:DATA_WIDTH];

    assign imag_o = fifo_dout[DATA_WIDTH-1:0];

    assign valid_o = ~empty_o;

endmodule