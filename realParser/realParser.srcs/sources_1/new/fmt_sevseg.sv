`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 05:57:46 PM
// Design Name: 
// Module Name: fmt_sevseg
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


module fmt_sevseg(
    input  logic clk,
    input  logic rst_n,

    // parsed fields from market_parser
    input  logic        p_valid,
    input  logic [7:0]  p_msg_type,
    input  logic [23:0] p_instr_id,   // [23:16]=char0, [15:8]=char1, [7:0]=char2
    input  logic [31:0] p_price,
    input  logic [31:0] p_size,

    // to seg7_mux4
    output logic [7:0]  ch3, ch2, ch1, ch0,   // left..right
    output logic [3:0]  dp_mask
);

logic [7:0] sym0, sym1, sym2;
logic [31:0] price_q, size_q;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sym0    <= "A";
        sym1    <= "N";
        sym2    <= "A";

        price_q <= 32'hFFFF_FFFF;
        size_q  <= 32'd1;
    end else if (p_valid) begin
        sym0    <= p_instr_id[23:16];
        sym1    <= p_instr_id[15:8];
        sym2    <= p_instr_id[7:0];

        price_q <= p_price;
        size_q  <= p_size;
    end
end

// 1 Hz cycler
logic [26:0] secdiv;
logic [1:0] screen;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        secdiv <= '0;
        screen <= 2'd0;
    end else begin
        secdiv <= secdiv + 1;
        if (secdiv == 27'd100_000_000) begin
            secdiv <= '0;
            screen <= (screen == 2'd2) ? 2'd0 : screen + 1;
        end
    end
end

function automatic [7:0] digit_char(input int d);
    unique case (d)
        0: digit_char = "0";
        1: digit_char = "1";
        2: digit_char = "2";
        3: digit_char = "3";
        4: digit_char = "4";
        5: digit_char = "5";
        6: digit_char = "6";
        7: digit_char = "7";
        8: digit_char = "8";
        9: digit_char = "9";
        default: digit_char = " ";
    endcase
endfunction
/*
always_comb begin
    dp_mask = 4'b0000;
    unique case (screen)
        2'd0: begin
            //  T. <sym0><sym1><sym2>  (but only 3 chars total on our 4-digit: T . sym0 sym1, sym2 gets shown in next screen)
            ch3="T"; ch2=" "; ch1=sym0; ch0=sym1;
            dp_mask[3] = 1'b1; // dot after T
        end
        2'd1: begin
            //  show remaining letter (sym2) briefly with padding
            ch3=" "; ch2=" "; ch1=" "; ch0=sym2;
            dp_mask = 4'b0000;
        end
        2'd2: begin
            //  P. INF   (INF when price sentinel)
            ch3="P"; ch2=" "; dp_mask[3]=1'b1;
            if (price_q == 32'hFFFF_FFFF) begin
            ch1="I"; ch0="N"; // we'll flash F via time bit to hint INF
            end else begin
            // show last two digits of price for fun (ticks)
            ch1 = digit_char((price_q/10)%10);
            ch0 = digit_char(price_q%10);
            end
        end
        default: begin // 2'd3
            //  S. 001
            ch3="S"; ch2=" "; dp_mask[3]=1'b1;
            ch1 = digit_char((size_q/10)%10);
            ch0 = digit_char(size_q%10);
        end
    endcase
end
*/

always_comb begin
    dp_mask = 4'b0000;
    ch3 = sym0;
    ch2 = sym1;
    ch1 = sym2;
    ch0 = " ";
end


endmodule
