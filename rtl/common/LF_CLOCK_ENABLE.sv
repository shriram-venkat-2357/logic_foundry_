`timescale 1ns/1ps

module LF_CLOCK_ENABLE
(
    input  logic clk,
    input  logic rst_n,
    input  logic clk_en,
    input  logic d,
    output logic q
);

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        q <= 1'b0;
    else if(clk_en)
        q <= d;
end

endmodule