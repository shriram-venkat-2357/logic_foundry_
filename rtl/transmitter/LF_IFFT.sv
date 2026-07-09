//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_ifft
//------------------------------------------------------------------------------
// Description:
// 5-Stage IFFT Wrapper
//
// Pipeline Stages
//   Stage-1 : Input Register
//   Stage-2 : Butterfly Placeholder
//   Stage-3 : Butterfly Placeholder
//   Stage-4 : Scaling Placeholder (1/N)
//   Stage-5 : Output Register
//
// Note:
// This is a pipelined wrapper for future IFFT IP integration.
//==============================================================================

module lf_ifft #

(
    parameter DATA_WIDTH = 16
)

(

input  logic                         lf_clk_i,
input  logic                         lf_rst_n_i,

input  logic signed [DATA_WIDTH-1:0] real_i,
input  logic signed [DATA_WIDTH-1:0] imag_i,
input  logic                         valid_i,

output logic signed [DATA_WIDTH-1:0] real_o,
output logic signed [DATA_WIDTH-1:0] imag_o,
output logic                         valid_o

);

    //----------------------------------------------------------------------
    // Stage-1 Registers
    //----------------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0] s1_real;
    logic signed [DATA_WIDTH-1:0] s1_imag;
    logic                         s1_valid;

    //----------------------------------------------------------------------
    // Stage-2 Registers
    //----------------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0] s2_real;
    logic signed [DATA_WIDTH-1:0] s2_imag;
    logic                         s2_valid;

    //----------------------------------------------------------------------
    // Stage-3 Registers
    //----------------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0] s3_real;
    logic signed [DATA_WIDTH-1:0] s3_imag;
    logic                         s3_valid;

    //----------------------------------------------------------------------
    // Stage-4 Registers (Scaling)
    //----------------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0] s4_real;
    logic signed [DATA_WIDTH-1:0] s4_imag;
    logic                         s4_valid;

    //----------------------------------------------------------------------
    // Stage-5 Registers
    //----------------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0] s5_real;
    logic signed [DATA_WIDTH-1:0] s5_imag;
    logic                         s5_valid;

    //----------------------------------------------------------------------
    // Pipeline
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            s1_real  <= '0;
            s1_imag  <= '0;
            s1_valid <= 1'b0;

            s2_real  <= '0;
            s2_imag  <= '0;
            s2_valid <= 1'b0;

            s3_real  <= '0;
            s3_imag  <= '0;
            s3_valid <= 1'b0;

            s4_real  <= '0;
            s4_imag  <= '0;
            s4_valid <= 1'b0;

            s5_real  <= '0;
            s5_imag  <= '0;
            s5_valid <= 1'b0;

        end

        else
        begin

            //------------------------------
            // Stage-1 : Input Register
            //------------------------------

            s1_real  <= real_i;
            s1_imag  <= imag_i;
            s1_valid <= valid_i;

            //------------------------------
            // Stage-2 : Butterfly-1
            //------------------------------

            s2_real  <= s1_real;
            s2_imag  <= s1_imag;
            s2_valid <= s1_valid;

            //------------------------------
            // Stage-3 : Butterfly-2
            //------------------------------

            s3_real  <= s2_real;
            s3_imag  <= s2_imag;
            s3_valid <= s2_valid;

            //------------------------------
            // Stage-4 : IFFT Scaling
            //------------------------------
            // Placeholder for 1/N scaling.
            // For now the data is passed through.
            // Replace with arithmetic right shift when
            // integrating the actual IFFT core.

            s4_real  <= s3_real;
            s4_imag  <= s3_imag;
            s4_valid <= s3_valid;

            //------------------------------
            // Stage-5 : Output Register
            //------------------------------

            s5_real  <= s4_real;
            s5_imag  <= s4_imag;
            s5_valid <= s4_valid;

        end

    end

    //----------------------------------------------------------------------
    // Outputs
    //----------------------------------------------------------------------

    assign real_o  = s5_real;
    assign imag_o  = s5_imag;
    assign valid_o = s5_valid;

endmodule