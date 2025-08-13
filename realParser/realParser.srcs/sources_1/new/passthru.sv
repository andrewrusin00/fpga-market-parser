//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2025 04:54:48 PM
// Design Name: 
// Module Name: passthru
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
`timescale 1ns/1ps

module passthru #(parameter int W = 8) (
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

wire xfer = s_tvalid && s_tready;

logic [1:0] beat_cnt;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)                 beat_cnt <= 2'd0;
    else if (xfer) begin
        if (beat_cnt == 2'd2)   beat_cnt <= 2'd0;
        else                    beat_cnt <= beat_cnt + 2'd1;
    end
end

assign m_tlast = (beat_cnt == 2'd2) && s_tvalid;
       
endmodule
