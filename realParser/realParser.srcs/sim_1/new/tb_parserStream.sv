`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2025 06:45:29 PM
// Design Name: 
// Module Name: tb_parserStream
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


module tb_parserStream;
    logic clk = 0, rst;
    logic inValid;
    logic inReady;
    logic [31:0] inData;
    logic outvalid;
    logic outReady;
    logic [15:0] outTradeId;
    logic [31:0] outPrice;
    logic [15:0] outVolume;
    logic outSide;
   
    // Clock 
    always #5 clk = ~clk;
    
    // Instantiate
    parserStream U (
        .clk        (clk),
        .rst        (rst),
        .inReady    (inReady),
        .inData     (inData),
        .outValid   (outValid),
        .outReady   (outReady),
        .outTradeId (outTradeId),
        .outPrice   (outPrice),
        .outVolume  (outVolume),
        .outSide    (outSide)
    );
    
    initial begin
        // Reset
        rst = 0; inValid = 0; #20;
        rst = 1; #20;
    end
endmodule
