`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 06:38:29 PM
// Design Name: 
// Module Name: seg7_mux4
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

module seg7_mux4 #(
    parameter int CLK_HZ     = 100_000_000, // Basys3 = 100 MHz
    parameter bit ACTIVE_LOW = 1            // Basys3 an/seg are active-low
)(
    input  logic        clk,
    input  logic        rst_n,

    // left .. right digit chars
    input  logic [7:0]  ch3, ch2, ch1, ch0,
    // per-digit decimal point (1 = dot ON)
    input  logic [3:0]  dp_mask,

    // to board
    output logic [3:0]  an,    // anode selects (one-hot scanned)
    output logic [6:0]  seg,   // {a,b,c,d,e,f,g}
    output logic        dp
);
// === refresh ~1 kHz/digit (4 kHz frame) ===
localparam int REFRESH_HZ = 1000;
localparam int TICKS_PER_DIGIT = CLK_HZ / (REFRESH_HZ * 4);

logic [$clog2(TICKS_PER_DIGIT)-1:0] tick;
logic [1:0] di; // 0..3 (0 = rightmost)

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin tick <= '0; di <= 2'd0; end
    else if (tick == TICKS_PER_DIGIT-1) begin tick <= '0; di <= di + 2'd1; end
    else tick <= tick + 1'b1;
end

// pick current char + dot
logic [7:0] ch; logic dot_on;
always_comb begin
    unique case (di)
        2'd0: begin ch = ch0; dot_on = dp_mask[0]; end
        2'd1: begin ch = ch1; dot_on = dp_mask[1]; end
        2'd2: begin ch = ch2; dot_on = dp_mask[2]; end
        default: begin ch = ch3; dot_on = dp_mask[3]; end
    endcase
end

  // ASCII-ish encoder → active-HIGH segments
function automatic logic [6:0] enc (input logic [7:0] c);
    unique case (c)
        "0": enc = 7'b1111110;
        "1": enc = 7'b0110000;
        "2": enc = 7'b1101101;
        "3": enc = 7'b1111001;
        "4": enc = 7'b0110011;
        "5": enc = 7'b1011011;
        "6": enc = 7'b1011111;
        "7": enc = 7'b1110000;
        "8": enc = 7'b1111111;
        "9": enc = 7'b1111011;

        "A": enc = 7'b1110111;
        "F": enc = 7'b1000111;
        "I": enc = 7'b0110000; // I ≈ 1
        "N": enc = 7'b0110111;
        "P": enc = 7'b1110011;
        "S": enc = 7'b1011011;
        "T": enc = 7'b0001111;

        " ": enc = 7'b0000000;
        default: enc = 7'b0000001; // dash-ish (g only)
    endcase
endfunction

logic [6:0] seg_ah = enc(ch);
logic       dp_ah  = dot_on;

// active-HIGH anode one-hot (di=0 -> rightmost)
logic [3:0] an_ah; always_comb an_ah = 4'b0001 << di;

// adapt polarity for board
always_comb begin
if (ACTIVE_LOW) begin
    seg = ~seg_ah; dp = ~dp_ah; an = ~an_ah;
end else begin
    seg =  seg_ah; dp =  dp_ah; an =  an_ah;
end
end
endmodule
