`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 05:57:18 PM
// Design Name: 
// Module Name: msg_player
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


module msg_player #(parameter int W = 8) (
    input logic clk,
    input logic rst_n,

    // to feed_ingress
    output logic [W-1:0]    m_tdata,
    output logic            m_tvalid,
    input logic             m_tready
);

// --- NOTES ---
// - Streams a single message forever: [4B header][12B payload], then repeats.
// - Header = seq(0x0001), len(12). You can edit bytes below any time.


// Helper: bytes for one message (edit NAME here)
localparam byte NAME0 = "A";  // instrument_id[23:16]
localparam byte NAME1 = "N";  // instrument_id[15:8]
localparam byte NAME2 = "A";  // instrument_id[7:0]

// build ROM: header, payload
localparam int N = 4 + 12;
localparam byte ROM [0:N-1] = '{
    8'h00, 8'h01, 8'h00, 8'd12,            // seq=1, len=12
    8'h01,                               // type = TRADE
    NAME0, NAME1, NAME2,                 // instrument_id as ASCII
    8'hFF,8'hFF,8'hFF,8'hFF,             // price = sentinel (INF)
    8'h00,8'h00,8'h00,8'h01              // size  = 1
};

// slow to human speed for visability (1 byte every 1ms)
localparam int GAP = 100_000;
logic [$clog2(GAP)-1:0] pace;
wire can_tx = (pace == 0);
always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) pace <= '0;
    else if (m_tvalid && m_tready) pace <= GAP-1;
    else if (pace != 0) pace <= pace - 1;


// stream FSM
logic [$clog2(N)-1:0] idx;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idx         <= 0;
        m_tvalid    <= 1'b0;
        m_tdata     <= '0;
    end else begin
        // keep current byte when stalled
        if (!m_tvalid) m_tdata <= ROM[idx];

        if (!m_tvalid && can_tx) m_tvalid <= 1'b1;          // present a byte

        if (m_tvalid && m_tready) begin                     // accepted
        idx      <= (idx == N-1) ? '0 : (idx + 1);
        m_tdata  <= ROM[(idx == N-1) ? 0 : (idx + 1)];
        // no explicit TLAST here—feed_ingress derives length→TLAST
        end
        // Deassert valid between bytes if you want a gap:
        if (m_tvalid && m_tready) m_tvalid <= 1'b0;
    end
end

endmodule
