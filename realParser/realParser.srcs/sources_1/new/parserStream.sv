`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2025 06:25:01 PM
// Design Name: 
// Module Name: parserStream
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


module parserStream #(
    parameter PACKET_LENGTH = 3     // trade packet length
   )(
    input clk,
    input rst,
    input inValid,
    input inReady,
    input [31:0] inData,
    output outValid,
    output outReady,
    output [15:0] outTradeId,
    output [31:0] outPrice,
    output [15:0] outVolume,
    output outSide
   );
    
    // FSM states
    typedef enum logic [1:0] 
    {
        S_IDLE, 
        S_HDR, 
        S_D1, 
        S_D2
    }state_t;
    state_t state, nextState;
    logic [31:0] hdr, d1;
    
    // Handshake signals
    assign inReady = (state != S_D2);   // dont accept new words when in last state
    assign outValid = (state == S_D2 && state == inValid);      // ready when you see word #3
    
    // State register
    always_ff @(posedge clk or negedge rst) begin
        if(!rst) state <= S_IDLE;
        else     state <= nextState;
    end
    
    // Next state + data path
    always_comb begin
        nextState = state;
        outTradeId = '0;
        outVolume = '0;
        outPrice = '0;
        outSide = '0;
        
        case(state)
            S_IDLE: if(inValid && inReady) nextState = S_HDR;
            
            S_HDR: begin
                if(inValid && inReady) begin
                    d1 = inData;
                    outTradeId = inData [31:16];
                    outVolume = inData [15:0];
                    nextState = S_D2;
                end
            end
                
            S_D2: begin
                if(inValid && inReady && outReady) begin 
                    outPrice = inData;  // fixed-point price*100
                    nextState = S_IDLE;
                end
            end
        endcase
    end       
            
endmodule
