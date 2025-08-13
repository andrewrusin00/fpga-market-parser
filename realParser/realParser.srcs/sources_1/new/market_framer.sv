`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2025 06:03:10 PM
// Design Name: 
// Module Name: market_framer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module market_framer#(
    parameter int W         = 8,
    parameter int FRAME_N   = 3
) (
    input logic clk,
    input logic rst_n,
    
    // INPUT stream (from previous stage)
    input logic [W-1:0] s_tdata,
    input logic         s_tvalid,
    output logic        s_tready,
    input logic         s_tlast,
    
    //OUTPUT stream (to next stage)
    output logic [W-1:0]m_tdata,
    output logic        m_tvalid,
    input logic         m_tready,
    output logic        m_tlast
);

assign s_tready = m_tready;
assign m_tvalid = s_tvalid;
assign m_tdata = s_tdata;

// transfer happened if valid && ready
wire xfer = s_tvalid && s_tready;

localparam int C_W = (FRAME_N <= 1) ? 1 : $clog2(FRAME_N);
logic [C_W-1:0] beat_cnt;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        beat_cnt <= 2'd0;
    end else if (xfer) begin
        if (beat_cnt == FRAME_N-1)  beat_cnt <= '0;
        else                        beat_cnt <= beat_cnt + 1'b1;
    end
end

assign m_tlast = (beat_cnt == FRAME_N-1) && s_tvalid;

endmodule
