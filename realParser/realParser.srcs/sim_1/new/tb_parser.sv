`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2025 06:18:42 PM
// Design Name: 
// Module Name: tb_parser
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


module tb_parser;
  logic        clk = 0, rst;
  logic [31:0] dataIn;
  logic        validIn;
  logic [15:0] tradeId;
  logic [31:0] price;
  logic [15:0] volume;
  logic        side, validOut;

  // clock
  always #5 clk = ~clk;

  // instantiate
  parser U (
    .clk      (clk),
    .rst      (rst),
    .dataIn   (dataIn),
    .validIn  (validIn),
    .tradeId  (tradeId),
    .price    (price),
    .volume   (volume),
    .side     (side),
    .validOut (validOut)
  );

  initial begin
    // reset
    rst = 0; validIn = 0; #20;
    rst = 1; #20;

    // send a BUY @ id=100, vol=50, price=132.45
    send_word(32'h01 << 24 | 1 << 23);        // header (type=1, side=1)
    send_word(100 << 16 | 50);                // trade_id=100, volume=50
    send_word(32'd13245);                     // price_fixed

    // wait for valid_out
    wait(validOut);
    $display("Got trade: id=%0d side=%b vol=%0d price=%0f",
             tradeId, side, volume, price/100.0);

    #50 $finish;
  end

  task send_word(input logic [31:0] w);
    @(posedge clk);
    dataIn  <= w;
    validIn <= 1;
    @(posedge clk);
    validIn <= 0;
  endtask

endmodule
