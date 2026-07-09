`timescale 1ns/1ps
`ifndef LF_PACKET_DECODER_SV
`define LF_PACKET_DECODER_SV

import LF_pkg::*;

//==============================================================================
// Module  : lf_packet_decoder
//------------------------------------------------------------------------------
// Strips packet header, forwards payload, signals packet_done.
//
// Packet format (word-based):
//   Word 0 : Header  [15:8]=Packet ID, [7:0]=Payload Length (words)
//   Word 1..N : Payload
//   Word N+1 : CRC (handled by upstream CRC_CHECK)
//==============================================================================

module lf_packet_decoder #(
    parameter DATA_WIDTH  = 16,
    parameter MAX_PAYLOAD = 256
)(
    input  logic                     lf_clk_i,
    input  logic                     lf_rst_n_i,

    // Input stream (from CRC_CHECK output)
    input  logic [DATA_WIDTH-1:0]    lf_data_i,
    input  logic                     lf_valid_i,
    input  logic                     lf_sop_i,
    input  logic                     lf_eop_i,

    // Output stream (payload only, no header)
    output logic [DATA_WIDTH-1:0]    lf_data_o,
    output logic                     lf_valid_o,
    output logic                     lf_sop_o,
    output logic                     lf_eop_o,

    // Packet status
    output logic                     lf_packet_done_o,
    output logic [7:0]               lf_packet_id_o,
    output logic [7:0]               lf_payload_len_o
);

    //------------------------------------------------------------
    // FSM States
    //------------------------------------------------------------

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_HEADER,
        ST_PAYLOAD
    } state_t;

    state_t state;

    //------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------

    logic [7:0] packet_id;
    logic [7:0] payload_len;
    logic [15:0] word_count;

    //------------------------------------------------------------
    // State Machine
    //------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin
        if (!lf_rst_n_i) begin
            state            <= ST_IDLE;
            lf_data_o        <= '0;
            lf_valid_o       <= 1'b0;
            lf_sop_o         <= 1'b0;
            lf_eop_o         <= 1'b0;
            lf_packet_done_o <= 1'b0;
            lf_packet_id_o   <= '0;
            lf_payload_len_o <= '0;
            packet_id        <= '0;
            payload_len      <= '0;
            word_count       <= '0;
        end
        else begin
            // Default outputs
            lf_valid_o       <= 1'b0;
            lf_sop_o         <= 1'b0;
            lf_eop_o         <= 1'b0;
            lf_packet_done_o <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (lf_valid_i && lf_sop_i) begin
                        // Capture header
                        packet_id   <= lf_data_i[15:8];
                        payload_len <= lf_data_i[7:0];
                        word_count  <= '0;
                        state       <= ST_PAYLOAD;
                    end
                end

                ST_PAYLOAD: begin
                    if (lf_valid_i) begin
                        // Forward payload word
                        lf_data_o  <= lf_data_i;
                        lf_valid_o <= 1'b1;
                        lf_sop_o   <= (word_count == '0);  // First payload word = SOP
                        lf_eop_o   <= (word_count == {8'd0, payload_len} - 1) || lf_eop_i;

                        word_count <= word_count + 1'b1;

                        // End of packet
                        if (lf_eop_i || word_count == {8'd0, payload_len} - 1) begin
                            lf_packet_done_o <= 1'b1;
                            lf_packet_id_o   <= packet_id;
                            lf_payload_len_o <= payload_len;
                            state <= ST_IDLE;
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule

`endif