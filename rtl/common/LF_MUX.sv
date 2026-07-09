`timescale 1ns/1ps

module LF_MUX
#(
    parameter WIDTH = 16
)
(
    input  logic             sel,
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] y
);

always_comb
begin
    if(sel)
        y = b;
    else
        y = a;
end

endmodule