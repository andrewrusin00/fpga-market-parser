`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 03:52:27 PM
// Design Name: 
// Module Name: feed_ingress
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
import market_pkg::*;

module feed_ingress #(parameter int W = 8) (
    input logic clk,
    input logic rst_n,

    input logic [W-1:0]     s_tdata,
    input  logic            s_tvalid,
    output logic            s_tready,
    input  logic            s_tlast,    // not used here (source frames whole packets)

    // output stream: JUST the payload (header removed)
    output logic [W-1:0]    m_tdata,
    output logic            m_tvalid,
    input  logic            m_tready,
    output logic            m_tlast,

    // sideband: per-message info
    output logic [15:0]     o_seq,        // sequence of this message
    output logic            o_gap_pulse,  // 1-cycle pulse when seq != last+1 (after first)
    output logic            o_len_err     // length field != expected TRADE_BYTES
);


typedef enum logic [1:0] {HDR, PAYLOAD} state_e;
state_e state;

// Header assembly
logic [1:0]     hdr_idx;
logic [15:0]    hdr_seq;
logic [15:0]    hdr_len;

// payload countdown
logic [15:0]    remain;

// seqeunce tracking
logic [15:0]    last_seq;
logic           have_last;  // false for first message

// handshake helpers
wire xfer_in = s_tvalid && s_tready;
wire xfer_out = m_tvalid && m_tready;

always_comb begin
    m_tdata = '0;
    m_tvalid = 1'b0;
    m_tlast = 1'b0;

    unique case (state)
        HDR:        s_tready = 1'b1;
        PAYLOAD:    s_tready = m_tready;
        default:    s_tready = 1'b0;
    endcase

    if (state == PAYLOAD) begin
        // pass the payload through
        m_tdata = s_tdata;
        m_tvalid = s_tvalid;

        m_tlast = (remain == 16'd1) && s_tvalid;
    end
end

// assemble header, check seq/len, forward payload
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state       <= HDR;
        hdr_idx     <= '0;
        hdr_seq     <= '0;
        hdr_len     <= '0;
        remain      <= '0;
        last_seq    <= '0;
        have_last   <= 1'b0;
        o_seq       <= '0;
        o_gap_pulse <= 1'b0;
        o_len_err   <= 1'b0;
    end else begin
        // default 1-cycle pulses low
        o_gap_pulse <= 1'b0;
        o_len_err   <= 1'b0;

        unique case (state)
            HDR: begin
                if (xfer_in) begin
                     unique case (hdr_idx)
                        2'd0: begin 
                            hdr_seq[15:8]   <= s_tdata;
                            hdr_idx         <= 2'd1;
                        end
                        2'd1: begin 
                            hdr_seq[7:0]    <= s_tdata;
                            hdr_idx         <= 2'd2;
                        end
                        2'd2: begin
                            hdr_len[15:8]   <= s_tdata;
                            hdr_idx         <= 2'd3;
                        end
                        2'd3: begin
                            logic [15:0] new_len;
                            new_len         = {hdr_len[15:8], s_tdata};
                            hdr_len[7:0]    <= s_tdata;

                            // header complete on this byte
                            o_seq           <= hdr_seq;
                            if (have_last && (hdr_seq != last_seq + 16'd1))
                                o_gap_pulse <= 1'b1;

                            if (new_len != TRADE_BYTES)
                                o_len_err   <= 1'b1;   

                            // start forwarding payload next
                            remain    <= new_len;
                            state     <= PAYLOAD;
                            hdr_idx   <= 1'd0;
                            last_seq  <= hdr_seq;
                            have_last <= 1'b1;
                        end
                    endcase
                end
            end

            PAYLOAD: begin
                if (xfer_out) begin
                    remain <= remain - 16'd1;
                    if (remain == 16'd1) begin
                        state <= HDR;
                    end
                end
            end
        endcase
    end
end

endmodule
