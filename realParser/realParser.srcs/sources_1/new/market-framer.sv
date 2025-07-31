`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2025 06:41:55 PM
// Design Name: 
// Module Name: market-framer
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


module market_framer #(
    parameter DATA_WIDTH = 8,
    parameter SYMBOL_LENGTH = 6,
    parameter PRICE_WIDTH = 32,
    parameter TIMESTAMP_WIDTH = 32
)(
    input logic                                 clk,
    input logic                                 rst_n,
    input logic [DATA_WIDTH-1:0]                data_in,
    input logic                                 valid_in,
    
    output logic                                packet_valid,
    output logic [SYMBOL_LENGTH*DATA_WIDTH-1:0] symbol,
    output logic [PRICE_WIDTH-1:0]              price,
    output logic [TIMESTAMP_WIDTH-1:0]          timestamp
);

typedef enum logic [1:0]
{
    IDLE,           // wait for data_in == 8'hAA
    CAPTURE,        // buffer incoming bytes until end byte is 8'h55 is recieved
    DONE            // assert packet_valid, extract symbol, price and timestamp
} state_t;
state_t current_state, next_state;

logic [DATA_WIDTH-1:0] packet_buffer [0:15];
logic [$clog2(16):0] byte_idx;

assign symbol    = {packet_buffer[1], packet_buffer[2], packet_buffer[3],
                    packet_buffer[4], packet_buffer[5], packet_buffer[6]};

assign price     = {packet_buffer[7], packet_buffer[8],
                    packet_buffer[9], packet_buffer[10]};

assign timestamp = {packet_buffer[11], packet_buffer[12],
                    packet_buffer[13], packet_buffer[14]};
endmodule
