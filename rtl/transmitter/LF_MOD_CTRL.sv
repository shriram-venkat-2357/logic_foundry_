`timescale 1ns/1ps
`ifndef LF_MOD_CTRL_SV
`define LF_MOD_CTRL_SV

import LF_pkg::*;

module LF_MOD_CTRL
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
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic                  valid_in,
    input  logic                  sop_in,
    input  logic                  eop_in,

    //------------------------------------------------------------
    // Modulation Selection
    //------------------------------------------------------------
    input mod_t modulation_sel,

    //------------------------------------------------------------
    // BPSK Inputs
    //------------------------------------------------------------
    input logic [IQ_WIDTH-1:0] bpsk_i,
    input logic [IQ_WIDTH-1:0] bpsk_q,
    input logic                bpsk_valid,

    //------------------------------------------------------------
    // QPSK Inputs
    //------------------------------------------------------------
    input logic [IQ_WIDTH-1:0] qpsk_i,
    input logic [IQ_WIDTH-1:0] qpsk_q,
    input logic                qpsk_valid,

    //------------------------------------------------------------
    // 16-QAM Inputs
    //------------------------------------------------------------
    input logic [IQ_WIDTH-1:0] qam16_i,
    input logic [IQ_WIDTH-1:0] qam16_q,
    input logic                qam16_valid,

    //------------------------------------------------------------
    // Outputs to Selected Modulator
    //------------------------------------------------------------
    output logic [DATA_WIDTH-1:0] mod_data,
    output logic                  mod_valid,
    output logic                  mod_sop,
    output logic                  mod_eop,

    //------------------------------------------------------------
    // IQ Output
    //------------------------------------------------------------
    output logic [IQ_WIDTH-1:0] i_out,
    output logic [IQ_WIDTH-1:0] q_out,
    output logic                iq_valid

);

    //------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------

    logic [IQ_WIDTH-1:0] i_reg;
    logic [IQ_WIDTH-1:0] q_reg;
    logic                valid_reg;
        //------------------------------------------------------------
    // Modulation Selection Logic
    //------------------------------------------------------------

    always_comb
    begin

        //--------------------------------------------------------
        // Default Outputs
        //--------------------------------------------------------

        mod_data  = data_in;
        mod_valid = valid_in;
        mod_sop   = sop_in;
        mod_eop   = eop_in;

        i_reg     = '0;
        q_reg     = '0;
        valid_reg = 1'b0;

        //--------------------------------------------------------
        // Select Modulator
        //--------------------------------------------------------

        case(modulation_sel)

            //----------------------------------------------------
            // BPSK
            //----------------------------------------------------

            MOD_BPSK:
            begin

                i_reg     = bpsk_i;
                q_reg     = bpsk_q;
                valid_reg = bpsk_valid;

            end

            //----------------------------------------------------
            // QPSK
            //----------------------------------------------------

            MOD_QPSK:
            begin

                i_reg     = qpsk_i;
                q_reg     = qpsk_q;
                valid_reg = qpsk_valid;

            end

            //----------------------------------------------------
            // 16-QAM
            //----------------------------------------------------

            MOD_QAM16:
            begin

                i_reg     = qam16_i;
                q_reg     = qam16_q;
                valid_reg = qam16_valid;

            end

            //----------------------------------------------------
            // Default
            //----------------------------------------------------

            default:
            begin

                i_reg     = '0;
                q_reg     = '0;
                valid_reg = 1'b0;

            end

        endcase

    end

    //------------------------------------------------------------
    // Registered Outputs
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            i_out    <= '0;
            q_out    <= '0;
            iq_valid <= 1'b0;

        end

        else
        begin

            i_out    <= i_reg;
            q_out    <= q_reg;
            iq_valid <= valid_reg;

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

            case(modulation_sel)

                MOD_BPSK,
                MOD_QPSK,
                MOD_QAM16:
                    ;

                default:
                    $error("LF_MOD_CTRL : Invalid Modulation Selected.");

            endcase

        end

    end

`endif

    //------------------------------------------------------------
    // Output Timing
    //------------------------------------------------------------

    // I/Q outputs are registered in the previous stage to
    // improve timing closure and simplify downstream DSP blocks.

endmodule

`endif