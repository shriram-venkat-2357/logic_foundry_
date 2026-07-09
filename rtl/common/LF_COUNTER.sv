`timescale 1ns/1ps

module LF_COUNTER
#(
    parameter WIDTH = 32
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    input  logic clr,
    output logic [WIDTH-1:0] count
);

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        count <= '0;
    else if(clr)
        count <= '0;
    else if(en)
        count <= count + 1'b1;
end

endmodule