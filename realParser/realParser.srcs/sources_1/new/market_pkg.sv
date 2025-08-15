`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 03:47:46 PM
// Design Name: 
// Module Name: market_pkg
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


package market_pkg;
    // feed header format, which is 4 bytes total
    // [15:0] seq       : 16 bit sequence number, incremments by 1 per message
    // [15:0] length    : payload length in bytes (expect 12 for TRADE)
    
    localparam int FEED_HDR_BYTES   = 4;
    localparam int TRADE_BYTES      = 12;

    // message type constants
    localparam byte MSG_TRADE       = 8'h01;
endpackage
