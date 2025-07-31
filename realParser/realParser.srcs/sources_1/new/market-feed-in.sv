`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2025 06:03:53 PM
// Design Name: 
// Module Name: market-feed-in
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


module market_feed_in #(
    parameter DATA_WIDTH = 8,
    parameter FEED_LENGTH = 32
)(
    input logic                     clk,
    input logic                     rst_n,
    output logic [DATA_WIDTH-1:0]   data_out,
    output logic                    valid
);

    logic [DATA_WIDTH-1:0] packet_stream [0:FEED_LENGTH-1];
    logic [$clog2(FEED_LENGTH):0]idx;
    
    initial begin 
        packet_stream[0]  = 8'hAA; // SYNC_BYTE
        packet_stream[1]  = "A";   // SYMBOL[0]
        packet_stream[2]  = "P";
        packet_stream[3]  = "P";
        packet_stream[4]  = "L";
        packet_stream[5]  = "E";
        packet_stream[6]  = "X";   // SYMBOL[5]
        packet_stream[7]  = 8'h12; // PRICE byte 0
        packet_stream[8]  = 8'h34;
        packet_stream[9]  = 8'h56;
        packet_stream[10] = 8'h78; // PRICE byte 3
        packet_stream[11] = 8'h9A; // TIMESTAMP byte 0
        packet_stream[12] = 8'hBC;
        packet_stream[13] = 8'hDE;
        packet_stream[14] = 8'hF0; // TIMESTAMP byte 3
        packet_stream[15] = 8'h55; // END_BYTE

        for (int i = 16; i < FEED_LENGTH; i++) begin
            packet_stream[i] = 8'h00;
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx <= 0;
            data_out <= 0;
            valid <= 0;
        end else begin
            data_out <= packet_stream[idx];
            valid <= 1;
            idx <= (idx < FEED_LENGTH - 1) ? idx + 1 : idx;
        end
    end     
                 
endmodule
