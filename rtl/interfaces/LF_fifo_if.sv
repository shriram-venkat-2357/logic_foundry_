`timescale 1ns/1ps
`ifndef LF_FIFO_IF_SV
`define LF_FIFO_IF_SV

interface LF_fifo_if
#(
    parameter DATA_WIDTH = 16,
    parameter DEPTH      = 256
)
(
    input logic clk,
    input logic rst_n
);

    //------------------------------------------------------------
    // Write Interface
    //------------------------------------------------------------

    logic [DATA_WIDTH-1:0] wr_data;
    logic                  wr_en;
    logic                  full;

    //------------------------------------------------------------
    // Read Interface
    //------------------------------------------------------------

    logic [DATA_WIDTH-1:0] rd_data;
    logic                  rd_en;
    logic                  empty;

    //------------------------------------------------------------
    // Status Signals
    //------------------------------------------------------------

    logic                  almost_full;
    logic                  almost_empty;

    logic [$clog2(DEPTH):0] level;

    //------------------------------------------------------------
    // Producer (Write Side)
    //------------------------------------------------------------

    modport producer
    (
        input  full,
        input  almost_full,
        input  level,

        output wr_data,
        output wr_en
    );

    //------------------------------------------------------------
    // Consumer (Read Side)
    //------------------------------------------------------------

    modport consumer
    (
        input  rd_data,
        input  empty,
        input  almost_empty,
        input  level,

        output rd_en
    );

    //------------------------------------------------------------
    // FIFO Core
    //------------------------------------------------------------

    modport fifo
    (
        input  wr_data,
        input  wr_en,
        input  rd_en,

        output rd_data,
        output full,
        output empty,
        output almost_full,
        output almost_empty,
        output level
    );

endinterface

`endif