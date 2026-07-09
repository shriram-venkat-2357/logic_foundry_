//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_demod_ctrl
//------------------------------------------------------------------------------
// Description:
// Selects the active demodulator output.
//
// mod_sel
// 00 -> BPSK
// 01 -> QPSK
// 10 -> 16QAM
//==============================================================================

module lf_demod_ctrl(

    input  logic         lf_clk_i,
    input  logic         lf_rst_n_i,

    // Control
    input  logic [1:0]   mod_sel_i,

    // BPSK Input
    input  logic [0:0]   bpsk_bits_i,
    input  logic         bpsk_valid_i,

    // QPSK Input
    input  logic [1:0]   qpsk_bits_i,
    input  logic         qpsk_valid_i,

    // 16-QAM Input
    input  logic [3:0]   qam16_bits_i,
    input  logic         qam16_valid_i,

    // Selected Output
    output logic [3:0]   demod_bits_o,
    output logic         demod_valid_o

);

    //------------------------------------------------------------
    // Internal Combinational Signals
    //------------------------------------------------------------

    logic [3:0] demod_bits_next;
    logic       demod_valid_next;

    //------------------------------------------------------------
    // Combinational Selection Logic
    //------------------------------------------------------------

    always_comb
    begin

        demod_bits_next  = 4'b0000;
        demod_valid_next = 1'b0;

        unique case(mod_sel_i)

            //--------------------------------------------------
            // BPSK
            //--------------------------------------------------

            2'b00:
            begin
                demod_bits_next  = {3'b000,bpsk_bits_i};
                demod_valid_next = bpsk_valid_i;
            end

            //--------------------------------------------------
            // QPSK
            //--------------------------------------------------

            2'b01:
            begin
                demod_bits_next  = {2'b00,qpsk_bits_i};
                demod_valid_next = qpsk_valid_i;
            end

            //--------------------------------------------------
            // 16QAM
            //--------------------------------------------------

            2'b10:
            begin
                demod_bits_next  = qam16_bits_i;
                demod_valid_next = qam16_valid_i;
            end

            //--------------------------------------------------
            // Reserved
            //--------------------------------------------------

            default:
            begin
                demod_bits_next  = 4'b0000;
                demod_valid_next = 1'b0;
            end

        endcase

    end

    //------------------------------------------------------------
    // Output Registers
    //------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            demod_bits_o  <= 4'b0000;
            demod_valid_o <= 1'b0;

        end

        else
        begin

            demod_bits_o  <= demod_bits_next;
            demod_valid_o <= demod_valid_next;

        end

    end

endmodule
