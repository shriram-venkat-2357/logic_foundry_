`timescale 1ns/1ps

module LF_EDGE_DETECT
(
    input  logic clk,
    input  logic rst_n,
    input  logic signal_in,

    output logic rising_edge,
    output logic falling_edge
);

logic signal_d;

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        signal_d <= 1'b0;
    else
        signal_d <= signal_in;
end

assign rising_edge  =  signal_in & ~signal_d;
assign falling_edge = ~signal_in &  signal_d;

endmodule