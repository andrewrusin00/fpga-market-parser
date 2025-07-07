`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Andrew Rusin
// 
// Create Date: 07/07/2025 05:55:52 PM
// Design Name: 
// Module Name: parser
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


module parser(
    input logic         clk,
    input logic         rst,
    input logic [31:0]  dataIn,
    input logic         validIn,
    
    output logic [15:0] tradeId,
    output logic [31:0] price,
    output logic [15:0] volume,
    output logic        side,       // 1 = buy, 0 = sell
    output logic        validOut    // pulses high for 1 clk when a trade is ready
    );
    
// FSM States
typedef enum logic [1:0] {
    ST_IDLE,        // Waiting for header
    ST_WORD1,       // Got header, wating for data word #1
    ST_WORD2,       // Got word 2, waiting for word 2
    ST_DONE         // One-cycle output pulse
}state_t;

state_t state, nextState;
logic [31:0] headerWord;

// State Reg
always_ff @(posedge clk or negedge rst) begin
    if(!rst)
        state <= ST_IDLE;
   else
        state <= nextState;
end

// Next state + datapath
always_ff @(posedge clk) begin 
    // Default
    validOut <= 1'b0;
    nextState <= state;
    
    case (state)
        ST_IDLE: begin
            if (validIn && dataIn[31:24] == 8'h01) begin 
                headerWord <= dataIn;
                side <= dataIn[23];
                nextState <= ST_WORD1;
            end         
        end
    
        ST_WORD1: begin
            if (validIn) begin
                tradeId <= dataIn[31:16];
                volume <= dataIn[15:0];
                nextState <= ST_WORD2;
            end
        end
        
        ST_WORD2: begin
            if (validIn) begin
                price <= dataIn;
                validOut <= 1'b1;
                nextState <= ST_IDLE;
            end      
        end
        
        default: nextState <= ST_IDLE;
    endcase
end    
             
endmodule
