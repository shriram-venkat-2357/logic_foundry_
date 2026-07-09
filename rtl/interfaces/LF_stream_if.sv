`ifndef LF_STREAM_IF_SV
`define LF_STREAM_IF_SV

interface LF_stream_if
#(
    parameter DATA_WIDTH = 16
)
(
    input logic clk,
    input logic rst_n
);

    //------------------------------------------------------------
    // Stream Signals
    //------------------------------------------------------------

    logic [DATA_WIDTH-1:0] data;

    logic                  valid;
    logic                  ready;

    logic                  sop;      // Start of Packet
    logic                  eop;      // End of Packet

    logic                  last;

    logic                  error;

    //------------------------------------------------------------
    // Producer (TX Source)
    //------------------------------------------------------------

    modport master
    (
        input  ready,

        output data,
        output valid,
        output sop,
        output eop,
        output last,
        output error
    );

    //------------------------------------------------------------
    // Consumer (TX Destination)
    //------------------------------------------------------------

    modport slave
    (
        output ready,

        input data,
        input valid,
        input sop,
        input eop,
        input last,
        input error
    );

endinterface

`endif