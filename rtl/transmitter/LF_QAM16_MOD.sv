`timescale 1ns/1ps
`ifndef LF_QAM16_MOD_SV
`define LF_QAM16_MOD_SV

import LF_pkg::*;

module LF_QAM16_MOD
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
    // IQ Output
    //------------------------------------------------------------

    output logic signed [IQ_WIDTH-1:0] i_out,
    output logic signed [IQ_WIDTH-1:0] q_out,

    output logic valid_out,
    output logic sop_out,
    output logic eop_out
);

    //------------------------------------------------------------
    // Normalized Constellation Levels
    //------------------------------------------------------------

    localparam signed [IQ_WIDTH-1:0] LEVEL1_P = 16'sd8192;
    localparam signed [IQ_WIDTH-1:0] LEVEL3_P = 16'sd24576;

    localparam signed [IQ_WIDTH-1:0] LEVEL1_N = -16'sd8192;
    localparam signed [IQ_WIDTH-1:0] LEVEL3_N = -16'sd24576;

    //------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------

    logic signed [IQ_WIDTH-1:0] i_symbol;
    logic signed [IQ_WIDTH-1:0] q_symbol;

    logic valid_reg;
    logic sop_reg;
    logic eop_reg;

    logic [3:0] symbol_bits;

    //------------------------------------------------------------
    // Four Bits Per Symbol
    //------------------------------------------------------------

    assign symbol_bits = data_in[DATA_WIDTH-1 -: 4];

    //------------------------------------------------------------
    // Gray-Coded 16-QAM Mapping
    //------------------------------------------------------------

    always_comb
    begin

        //--------------------------------------------------------
        // I Channel
        //--------------------------------------------------------

        case(symbol_bits[3:2])

            2'b00 : i_symbol = LEVEL3_N;
            2'b01 : i_symbol = LEVEL1_N;
            2'b11 : i_symbol = LEVEL1_P;
            2'b10 : i_symbol = LEVEL3_P;

            default : i_symbol = '0;

        endcase

        //--------------------------------------------------------
        // Q Channel
        //--------------------------------------------------------

        case(symbol_bits[1:0])

            2'b00 : q_symbol = LEVEL3_N;
            2'b01 : q_symbol = LEVEL1_N;
            2'b11 : q_symbol = LEVEL1_P;
            2'b10 : q_symbol = LEVEL3_P;

            default : q_symbol = '0;

        endcase

    end
        //------------------------------------------------------------
    // Output Registers
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            i_out <= '0;
            q_out <= '0;

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
            // Pipeline Control
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
    // Simulation Assertions
    //------------------------------------------------------------

`ifdef SIMULATION

    always_ff @(posedge clk)
    begin

        if(valid_in)
        begin

            assert
            (
                (i_symbol == LEVEL3_N) ||
                (i_symbol == LEVEL1_N) ||
                (i_symbol == LEVEL1_P) ||
                (i_symbol == LEVEL3_P)
            )
            else
                $error("LF_QAM16_MOD : Invalid I Symbol");

            assert
            (
                (q_symbol == LEVEL3_N) ||
                (q_symbol == LEVEL1_N) ||
                (q_symbol == LEVEL1_P) ||
                (q_symbol == LEVEL3_P)
            )
            else
                $error("LF_QAM16_MOD : Invalid Q Symbol");

        end

    end

`endif

endmodule

`endif