`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2025 11:44:27 PM
// Design Name: 
// Module Name: market_parser
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


module market_parser #(parameter int W = 8) (
    input logic clk,
    input logic rst_n,

    // frm framer
    input logic [W-1:0] s_tdata,
    input logic         s_tvalid,
    output logic        s_tready,
    input logic         s_tlast,

    // output to next stage/sink - just pass through at the moment
    output logic [W-1:0]    m_tdata,
    output logic            m_tvalid,
    input logic             m_tready,
    output logic            m_tlast,

    // parsed fields
    output logic            p_valid,    // one cycle pulse when a full message is parsed
    output logic [7:0]      p_msg_type,
    output logic [23:0]     p_instr_id,
    output logic [31:0]     p_price,
    output logic [31:0]     p_size     
);

// pass through, no parsing yet
assign s_tready = m_tready;
assign m_tvalid = s_tvalid;
assign m_tdata = s_tdata;
assign m_tlast = s_tlast;

wire xfer = s_tvalid && s_tready;

logic [3:0] byte_idx;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        byte_idx <= 4'd0;
    end else if (xfer) begin
        if (s_tlast)    byte_idx <= 4'd0;
        else            byte_idx <= byte_idx + 4'd1;
    end
end

// place holder outputs (to be replaced with real logic)
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_valid     <= 1'b0;
        p_msg_type  <= '0;
        p_instr_id  <= '0;
        p_price     <= '0;
        p_size      <= '0;
    end else begin
        p_valid     <= 1'b0;    // keep low until parsing is implemented
    end
end

endmodule
