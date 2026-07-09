`timescale 1ns/1ps
`ifndef LF_BPSK_MOD_SV
`define LF_BPSK_MOD_SV

import LF_pkg::*;

module LF_BPSK_MOD
#(
    parameter DATA_WIDTH = 16,
    parameter IQ_WIDTH   = 16
)
(
    input  logic clk,
    input  logic rst_n,

    //------------------------------------------------------------
    // Input Stream
    //------------------------------------------------------------
    input logic [DATA_WIDTH-1:0] data_in,
    input logic                  valid_in,
    input logic                  sop_in,
    input logic                  eop_in,

    //------------------------------------------------------------
    // Output IQ
    //------------------------------------------------------------
    output logic signed [IQ_WIDTH-1:0] i_out,
    output logic signed [IQ_WIDTH-1:0] q_out,

    output logic valid_out,
    output logic sop_out,
    output logic eop_out
);

    //------------------------------------------------------------
    // BPSK Amplitude
    //------------------------------------------------------------

    localparam signed [IQ_WIDTH-1:0] POS_LEVEL = 16'sd16384;
    localparam signed [IQ_WIDTH-1:0] NEG_LEVEL = -16'sd16384;

    //------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------

    logic signed [IQ_WIDTH-1:0] i_symbol;
    logic signed [IQ_WIDTH-1:0] q_symbol;

    logic valid_reg;
    logic sop_reg;
    logic eop_reg;

    //------------------------------------------------------------
    // BPSK Mapping
    //------------------------------------------------------------

    always_comb
    begin

        //--------------------------------------------------------
        // Default
        //--------------------------------------------------------

        i_symbol = NEG_LEVEL;
        q_symbol = '0;

        //--------------------------------------------------------
        // MSB Used For Mapping
        //--------------------------------------------------------

        if(data_in[DATA_WIDTH-1])
            i_symbol = POS_LEVEL;
        else
            i_symbol = NEG_LEVEL;

    end
        //------------------------------------------------------------
    // Output Register
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            i_out     <= '0;
            q_out     <= '0;

            valid_out <= 1'b0;

            sop_out   <= 1'b0;
            eop_out   <= 1'b0;

            valid_reg <= 1'b0;
            sop_reg   <= 1'b0;
            eop_reg   <= 1'b0;

        end

        else
        begin

            //----------------------------------------------------
            // Register Control Signals
            //----------------------------------------------------

            valid_reg <= valid_in;
            sop_reg   <= sop_in;
            eop_reg   <= eop_in;

            //----------------------------------------------------
            // Register IQ Symbols
            //----------------------------------------------------

            if(valid_in)
            begin

                i_out <= i_symbol;
                q_out <= q_symbol;

            end

            else
            begin

                i_out <= '0;
                q_out <= '0;

            end

            //----------------------------------------------------
            // Output Controls
            //----------------------------------------------------

            valid_out <= valid_reg;
            sop_out   <= sop_reg;
            eop_out   <= eop_reg;

        end

    end

    //------------------------------------------------------------
    // Optional Simulation Assertions
    //------------------------------------------------------------

`ifdef SIMULATION

    always_ff @(posedge clk)
    begin

        if(valid_in)
        begin

            assert((i_symbol == POS_LEVEL) ||
                   (i_symbol == NEG_LEVEL))
            else
                $error("LF_BPSK_MOD : Invalid constellation point.");
        end

    end

`endif

endmodule

`endif
