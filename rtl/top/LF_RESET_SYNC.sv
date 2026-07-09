`timescale 1ns/1ps

//==============================================================================
// Module: LF_RESET_SYNC
// Description: Clock Domain Crossing (CDC) safe reset synchronizer
//              Synchronizes asynchronous reset across clock domains
//==============================================================================

module LF_RESET_SYNC (
    input  logic clk,
    input  logic rst_n_in,
    output logic rst_n_out
);

  logic sync1, sync2;

  // Two-stage synchronizer for metastability protection
  always_ff @(posedge clk or negedge rst_n_in) begin
    if (!rst_n_in) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
    end else begin
      sync1 <= 1'b1;
      sync2 <= sync1;
    end
  end

  assign rst_n_out = sync2;

endmodule : LF_RESET_SYNC
