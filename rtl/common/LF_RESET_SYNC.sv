`timescale 1ns/1ps

module LF_RESET_SYNC
(
    input  logic clk,
    input  logic arst_n,
    output logic srst_n
);

logic ff1;

always_ff @(posedge clk or negedge arst_n)
begin
    if(!arst_n)
    begin
        ff1    <= 1'b0;
        srst_n <= 1'b0;
    end
    else
    begin
        ff1    <= 1'b1;
        srst_n <= ff1;
    end
end

endmodule