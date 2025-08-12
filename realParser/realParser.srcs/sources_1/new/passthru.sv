`timescale 1ns / 1ps
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


module passthru #(parameter int W = 8) (
    input logic clk,
    input logic rst_n,
    
    // input stream(from previous stage
    input logic [W-1:0] s_tdata,
    input logic         s_tvalid,
    output logic        s_tready,
    input logic         s_tlast,
    
    // output stream (to next stage)
    output logic [W-1:0]    m_tdata,
    output logic            m_tvalid,
    input logic             m_tready,
    output logic            m_tlast
);

    // combinational pass-through
    assign m_tdata = s_tdata;
    assign m_tvalid = s_tvalid;
    assign s_tready = m_tready;
    
    logix [1:0] cnt;
    wire xfer = m_tvalid && m_tready;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)      cnt <= 2'd0;
        else if (xfer)  cnt <= (cnt == 2'd2) ? 2'd0 : cnt +2'd1;
    end
    
assign m_tlast = (cnt == 2'd2) && m_tvalid;
        
endmodule
