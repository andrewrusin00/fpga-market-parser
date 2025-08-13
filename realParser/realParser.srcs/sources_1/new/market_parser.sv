`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2025 11:44:27 PM
// Design Name: 
// Module Name: market_parser
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


module market_parser #(parameter int W = 8) (
    input logic clk,
    input logic rst_n,

    // frm framer
    input logic [W-1:0] s_tdata,
    input logic         s_tvalid,
    output logic        s_tready,
    input logic         s_tlast,

    // output to next stage/sink - just pass through at the moment
    output logic [W-1:0]    m_tdata,
    output logic            m_tvalid,
    input logic             m_tready,
    output logic            m_tlast,

    // parsed fields
    output logic            p_valid,    // one cycle pulse when a full message is parsed
    output logic [7:0]      p_msg_type,
    output logic [23:0]     p_instr_id,
    output logic [31:0]     p_price,
    output logic [31:0]     p_size,     

    // parsed field regs
    logic [7:0]             r_type,
    logic [23:0]            r_id,    // 3 bytes: big-endian (the first byte of a multi-byte field goes to the high bits)
    logic [31:0]            r_price,
    logic [31:0]            r_size           
);

// pass through, no parsing yet
assign s_tready = m_tready;
assign m_tvalid = s_tvalid;
assign m_tdata = s_tdata;
assign m_tlast = s_tlast;

wire xfer = s_tvalid && s_tready;

logic [3:0] byte_idx;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        byte_idx <= 4'd0;
    end else if (xfer) begin
        if (s_tlast)    byte_idx <= 4'd0;
        else            byte_idx <= byte_idx + 4'd1;
    end
end

// assemble fields on accepted bytes
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_type  <= '0;
        r_id    <= '0;
        r_price <= '0;
        r_size  <= '0;
    end else if (xfer) begin
        unique case (byte_idx)
            4'd0:  r_type            <= s_tdata;        // msg_type
            // instrument_id (3 bytes, big-endian)
            4'd1:  r_id[23:16]       <= s_tdata;        // first ID byte  → high bits
            4'd2:  r_id[15:8]        <= s_tdata;        // middle ID byte
            4'd3:  r_id[7:0]         <= s_tdata;        // last  ID byte  → low bits
            // price (4 bytes, big-endian)
            4'd4:  r_price[31:24]    <= s_tdata;        // first price byte → high 8
            4'd5:  r_price[23:16]    <= s_tdata;
            4'd6:  r_price[15:8]     <= s_tdata;
            4'd7:  r_price[7:0]      <= s_tdata;        // last price byte  → low 8
            // size (4 bytes, big-endian)
            4'd8:  r_size[31:24]     <= s_tdata;
            4'd9:  r_size[23:16]     <= s_tdata;
            4'd10: r_size[15:8]      <= s_tdata;
            4'd11: r_size[7:0]       <= s_tdata;
            default: ; // no-op  
        endcase
    end
end

logic emit;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        emit        <= 1'b0;
        p_valid     <= 1'b0;
        p_msg_type  <= '0;
        p_instr_id  <= '0;
        p_price     <= '0;
        p_size      <= '0;
    end else begin

        emit        <= (xfer && s_tlast);
        p_valid     <= emit;
        
        if (emit) begin
        // continuously expose latest assembled values
            p_msg_type  <= r_type;
            p_instr_id  <= r_id;
            p_price     <= r_price;
            p_size      <= r_size;
        end
    end
end

endmodule
