`timescale 1ns/1ps
`ifndef LF_REFERENCE_MODEL_SV
`define LF_REFERENCE_MODEL_SV

import LF_pkg::*;

//==============================================================================
// Module  : lf_reference_model
//------------------------------------------------------------------------------
// Behavioral reference model for SDR TX->Channel->RX path.
// Computes expected received bits from transmitted bits using simple
// channel model (BER-based).
//
// This is a verification aid — NOT synthesizable.
//==============================================================================

class lf_reference_model;

    //----------------------------------------------------------
    // Transaction Storage
    //----------------------------------------------------------

    logic [DATA_WIDTH-1:0] tx_queue [$];
    logic [DATA_WIDTH-1:0] rx_queue [$];

    //----------------------------------------------------------
    // TX Side: Record transmitted packet
    //----------------------------------------------------------

    function void record_tx(input logic [DATA_WIDTH-1:0] data, input logic valid);
        if (valid)
            tx_queue.push_back(data);
    endfunction

    //----------------------------------------------------------
    // RX Side: Compare received against expected
    //----------------------------------------------------------

    function void check_rx(input logic [DATA_WIDTH-1:0] data, input logic valid, output logic match);
        if (valid && tx_queue.size() > 0) begin
            logic [DATA_WIDTH-1:0] expected;
            expected = tx_queue.pop_front();
            match = (data == expected);
            rx_queue.push_back(data);
        end else begin
            match = 1'b0;
        end
    endfunction

    //----------------------------------------------------------
    // Statistics
    //----------------------------------------------------------

    function int get_tx_count();
        return tx_queue.size();
    endfunction

    function void reset();
        tx_queue.delete();
        rx_queue.delete();
    endfunction

endclass

`endif