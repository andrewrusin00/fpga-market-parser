`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 05:58:11 PM
// Design Name: 
// Module Name: top_basys3_demo
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


module top_basys3_demo(
    input  logic clk,        // 100 MHz
    input  logic btn_rst,    // active-high reset (BTN)
    output logic [3:0] an,   // to 7-seg AN3..AN0 (active-low on Basys3)
    output logic [6:0] seg,  // to 7-seg segments (active-low)
    output logic       dp    // to 7-seg decimal point (active-low)
);

logic rst_n = ~btn_rst;

// Stream wires
logic [7:0] s_tdata, par_tdata;
logic       s_tvalid, s_tready;
logic       par_tvalid, par_tready, par_tlast;

// Sideband
logic [15:0] seq;
logic        gap, len_err;

// Source: ROM player (header+payload bytes)
msg_player UPLAY (
    .clk(clk), .rst_n(rst_n),
    .m_tdata(s_tdata), .m_tvalid(s_tvalid), .m_tready(s_tready)
);


// INGRESS: strip header, produce TLAST, detect gaps/len
feed_ingress UIN (
    .clk(clk), .rst_n(rst_n),
    .s_tdata(s_tdata), .s_tvalid(s_tvalid), .s_tready(s_tready), .s_tlast(1'b0), // not used
    .m_tdata(par_tdata), .m_tvalid(par_tvalid), .m_tready(par_tready), .m_tlast(par_tlast),
    .o_seq(seq), .o_gap_pulse(gap), .o_len_err(len_err)
);

// Parser
logic        p_valid;
logic [7:0]  p_type;
logic [23:0] p_id;
logic [31:0] p_price, p_size;

market_parser UPAR (
    .clk(clk), .rst_n(rst_n),
    .s_tdata(par_tdata), .s_tvalid(par_tvalid), .s_tready(par_tready), .s_tlast(par_tlast),
    .m_tdata(), .m_tvalid(), .m_tready(1'b1), .m_tlast(),       // sink not used on hardware
    .p_valid(p_valid), .p_msg_type(p_type), .p_instr_id(p_id), .p_price(p_price), .p_size(p_size)
);

// Formatter → 7-seg
logic [7:0] ch3,ch2,ch1,ch0; logic [3:0] dp_mask;
fmt_sevseg UFMT (
    .clk(clk), .rst_n(rst_n),
    .p_valid(p_valid), .p_msg_type(p_type), .p_instr_id(p_id), .p_price(p_price), .p_size(p_size),
    .ch3(ch3), .ch2(ch2), .ch1(ch1), .ch0(ch0), .dp_mask(dp_mask)
);

seg7_mux4 #(.CLK_HZ(100_000_000), .ACTIVE_LOW(1)) U7 (
    .clk(clk), .rst_n(rst_n),
    .ch3(ch3), .ch2(ch2), .ch1(ch1), .ch0(ch0),
    .dp_mask(dp_mask),
    .an(an), .seg(seg), .dp(dp)
);

endmodule
