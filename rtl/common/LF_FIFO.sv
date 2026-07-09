`timescale 1ns/1ps

module LF_FIFO
#(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)
(
    input  logic clk,
    input  logic rst_n,

    input  logic wr_en,
    input  logic rd_en,

    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data,

    output logic full,
    output logic empty
);

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

logic [ADDR_WIDTH:0] wr_ptr;
logic [ADDR_WIDTH:0] rd_ptr;

assign empty = (wr_ptr == rd_ptr);

assign full =
(
    (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
    (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0])
);

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        wr_ptr <= '0;
    end
    else if(wr_en && !full)
    begin
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
        wr_ptr <= wr_ptr + 1'b1;
    end
end

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rd_ptr <= '0;
        rd_data <= '0;
    end
    else if(rd_en && !empty)
    begin
        rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        rd_ptr <= rd_ptr + 1'b1;
    end
end

endmodule