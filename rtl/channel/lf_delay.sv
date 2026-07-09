   module lf_delay #(
       parameter DATA_WIDTH = 16
   )(
       input  logic                   lf_clk_i,
       input  logic                   lf_rst_n_i,
       input  logic [3:0]             delay_cfg_i, // 0 to 15 cycles delay

       input  logic [DATA_WIDTH-1:0]  lf_data_i,
       input  logic                   lf_valid_i,
       output logic                   lf_ready_o,

       output logic [DATA_WIDTH-1:0]  lf_data_o,
       output logic                   lf_valid_o,
       input  logic                   lf_ready_i
   );

       logic [DATA_WIDTH-1:0] pipe_data [0:15];
       logic                  pipe_valid [0:15];

       // Ready if downstream is ready or pipeline is empty
       assign lf_ready_o = lf_ready_i || !pipe_valid[delay_cfg_i];

       always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
           if (!lf_rst_n_i) begin
               for (int i = 0; i < 16; i++) begin
                   pipe_data[i]  <= '0;
                   pipe_valid[i] <= 1'b0;
               end
           end else if (lf_ready_o && lf_valid_i) begin
               pipe_data[0]  <= lf_data_i;
               pipe_valid[0] <= 1'b1;
               for (int i = 1; i < 16; i++) begin
                   pipe_data[i]  <= pipe_data[i-1];
                   pipe_valid[i] <= pipe_valid[i-1];
               end
           end
       end

       assign lf_data_o  = pipe_data[delay_cfg_i];
       assign lf_valid_o = pipe_valid[delay_cfg_i];

   endmodule
