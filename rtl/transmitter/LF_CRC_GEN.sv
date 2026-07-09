`timescale 1ns/1ps
`ifndef LF_CRC_GEN_SV
`define LF_CRC_GEN_SV

import LF_pkg::*;

module LF_CRC_GEN
#(
    parameter DATA_WIDTH = 16,
    parameter CRC_WIDTH  = 16,
    parameter CRC_POLY   = 16'h1021,
    parameter CRC_INIT   = 16'hFFFF
)
(
    input  logic clk,
    input  logic rst_n,

    //------------------------------------------------------------
    // Input Stream
    //------------------------------------------------------------
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic                  valid_in,
    input  logic                  sop_in,
    input  logic                  eop_in,

    //------------------------------------------------------------
    // Output Stream
    //------------------------------------------------------------
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  valid_out,
    output logic                  sop_out,
    output logic                  eop_out,

    //------------------------------------------------------------
    // CRC Output
    //------------------------------------------------------------
    output logic [CRC_WIDTH-1:0]  crc_out,
    output logic                  crc_valid
);

    //------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------

    logic [CRC_WIDTH-1:0] crc_reg;
    logic [CRC_WIDTH-1:0] crc_next;

    logic [DATA_WIDTH-1:0] data_reg;

    logic valid_reg;
    logic sop_reg;
    logic eop_reg;

    //------------------------------------------------------------
    // CRC Function (CRC-16-CCITT)
    //------------------------------------------------------------

    function automatic [CRC_WIDTH-1:0] next_crc16;

        input [CRC_WIDTH-1:0] crc;
        input [DATA_WIDTH-1:0] data;

        integer i;

        logic [CRC_WIDTH-1:0] c;

        begin

            c = crc;

            for(i = DATA_WIDTH-1; i >= 0; i = i - 1)
            begin

                if(c[CRC_WIDTH-1] ^ data[i])
                    c = (c << 1) ^ CRC_POLY;
                else
                    c = c << 1;

            end

            next_crc16 = c;

        end

    endfunction
        //------------------------------------------------------------
    // Sequential CRC Engine
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            crc_reg    <= CRC_INIT;

            data_reg   <= '0;

            valid_reg  <= 1'b0;
            sop_reg    <= 1'b0;
            eop_reg    <= 1'b0;

            crc_valid  <= 1'b0;
            crc_out    <= '0;

        end

        else
        begin

            //----------------------------------------------------
            // Default
            //----------------------------------------------------

            valid_reg <= 1'b0;
            sop_reg   <= 1'b0;
            eop_reg   <= 1'b0;

            crc_valid <= 1'b0;

            //----------------------------------------------------
            // Start Of Packet
            //----------------------------------------------------

            if(valid_in && sop_in)
            begin

                crc_reg <= CRC_INIT;

            end

            //----------------------------------------------------
            // Incoming Data
            //----------------------------------------------------

            if(valid_in)
            begin

                data_reg  <= data_in;

                valid_reg <= 1'b1;

                sop_reg   <= sop_in;
                eop_reg   <= eop_in;

                crc_reg   <= next_crc16(crc_reg, data_in);

            end

            //----------------------------------------------------
            // End Of Packet
            //----------------------------------------------------

            if(valid_in && eop_in)
            begin

                crc_out   <= next_crc16(crc_reg, data_in);

                crc_valid <= 1'b1;

            end

        end

    end

    //------------------------------------------------------------
    // Registered Outputs
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            data_out  <= '0;

            valid_out <= 1'b0;

            sop_out   <= 1'b0;
            eop_out   <= 1'b0;

        end

        else
        begin

            data_out  <= data_reg;

            valid_out <= valid_reg;

            sop_out   <= sop_reg;
            eop_out   <= eop_reg;

        end

    end
        //------------------------------------------------------------
    // Optional CRC Append Logic
    //
    // In the current architecture the CRC is generated here and
    // forwarded separately. The Packet Generator or Framer can
    // append it to the payload if required.
    //------------------------------------------------------------

    /*
    Example:

    Packet =
    ------------------------------------------------

    Payload

    CRC[15:0]

    ------------------------------------------------
    */

    //------------------------------------------------------------
    // Simulation Assertions
    //------------------------------------------------------------

`ifdef SIMULATION

    always_ff @(posedge clk)
    begin

        if(valid_in)
        begin

            assert(valid_out == 1'b1)
            else
                $error("LF_CRC_GEN : Output valid lost.");

        end

    end

`endif

endmodule

`endif
