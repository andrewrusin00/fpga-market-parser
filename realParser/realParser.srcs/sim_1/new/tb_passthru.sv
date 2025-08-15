`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2025 04:21:55 PM
// Design Name: 
// Module Name: tb_passthru
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
module tb_passthru;

localparam int W = 8; // stream data width

// Match passthru.sv (signal declarations)
logic  clk;
logic rst_n;

logic [W-1:0]   s_tdata;
logic           s_tvalid;
logic           s_tready; // will be driven BY the DUT 
logic           s_tlast;

logic [W-1:0]   mid_tdata;
logic           mid_tvalid;
logic           mid_tready;
logic           mid_tlast;

// stream between framer and parser
logic [W-1:0]   par_tdata;
logic           par_tvalid;
logic           par_tready;
logic           par_tlast;

logic [W-1:0]   m_tdata;
logic           m_tvalid; // driven by DUT
logic           m_tready;
logic           m_tlast;

// tb only wires to print parsed result when p_valid pulse
logic           p_valid;
logic [7:0]     p_type;
logic [23:0]    p_id;
logic [31:0]    p_price;
logic [31:0]    p_size;

logic [15:0]    seq;
logic           gap, len_err;

logic [15:0]    last_seq_seen;
logic           have_seq;
integer         lat_cnt;

wire xfer_in = s_tvalid && s_tready;
wire xfer_out = m_tvalid && m_tready;

// payload handshakes at parser input
wire pay_xfer = par_tvalid && par_tready;

typedef enum logic [1:0] {IDLE, WAIT_PAY, COUNT} lat_state_e;
lat_state_e lat_state;

// DUT - device under test
// tb -> ingress
feed_ingress #(.W(W)) u_ingress (
    .clk(clk), 
    .rst_n(rst_n),
    
    .s_tdata(s_tdata), 
    .s_tvalid(s_tvalid), 
    .s_tready(s_tready), 
    .s_tlast(s_tlast), // TB drives header+payload
    
    .m_tdata(par_tdata), 
    .m_tvalid(par_tvalid), 
    .m_tready(par_tready), 
    .m_tlast(par_tlast), // payload out
    
    .o_seq(seq), 
    .o_gap_pulse(gap), 
    .o_len_err(len_err)
);

/*
// upstream: tb -> passthru -> mid_*
passthru #(.W(W)) u_passthru (
    .clk(clk),
    .rst_n(rst_n),

    // from tb
    .s_tdata(s_tdata),
    .s_tvalid(s_tvalid),
    .s_tready(s_tready),
    .s_tlast(s_tlast),
    
    // to framer
    .m_tdata(mid_tdata),
    .m_tvalid(mid_tvalid),
    .m_tready(mid_tready),
    .m_tlast(mid_tlast)
);  

middle: mid_* -> framer -> par_*
market_framer #(.W(W), .FRAME_N(12)) u_framer (
    .clk(clk),
    .rst_n(rst_n),

    // from passthru
    .s_tdata(mid_tdata),
    .s_tvalid(mid_tvalid),
    .s_tready(mid_tready),
    .s_tlast(mid_tlast),

    // to tb sink
    .m_tdata(par_tdata),
    .m_tvalid(par_tvalid),
    .m_tready(par_tready),
    .m_tlast(par_tlast)
);    
*/

// ingress -> parser -> tb sink
market_parser #(.W(W)) u_parser (
    .clk(clk), 
    .rst_n(rst_n),
    
    .s_tdata(par_tdata), 
    .s_tvalid(par_tvalid), 
    .s_tready(par_tready), 
    .s_tlast(par_tlast),
    
    .m_tdata(m_tdata), 
    .m_tvalid(m_tvalid),
    .m_tready(m_tready),
    .m_tlast(m_tlast),
    
    .p_valid(p_valid),
    .p_msg_type(p_type), 
    .p_instr_id(p_id), 
    .p_price(p_price), 
    .p_size(p_size)
);    
// 100Mhz clock: period = 10ns -> toggle every 5ns
initial clk = 1'b0;
always #5 clk = ~clk;

initial begin
    // default values at time 0
    rst_n       = 1'b0;
    m_tready    = 1'b0;
    s_tdata     = '0;
    s_tvalid    = 1'b0;
    s_tlast     = 1'b0;
    
    // wait for two rising edges
    repeat (2) @(posedge clk);
    
    // dessert reset (now the DUT when added will be "running"
    rst_n       = 1'b1;
    m_tready    = 1'b1;
    
    repeat (10) @(posedge clk);
end

always @(posedge clk) if (rst_n && gap)
  $display("[%0t] GAP DETECTED! seq jumped to %0d", $time, seq);

always @(posedge clk) if (rst_n && len_err)
  $error("[%0t] LENGTH ERROR! got payload length != 12", $time);

always_ff @(posedge clk) if (rst_n && p_valid) begin
    $display("PARSED TRADE type=0x%02h id=0x%06h price=%0d size=%0d",
    p_type, p_id, p_price, p_size);

    if ((p_type  == 8'h01) &&
        (p_id    == 24'h001234) &&
        (p_price == 32'h00002710) &&
        (p_size  == 32'd100))
        
        $display("PASS: Parsed trade matches expected");
    else
        $error("Mismatch! type=0x%02h id=0x%06h price=%0d size=%0d",
        p_type, p_id, p_price, p_size);
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lat_state       <= IDLE;
        last_seq_seen   <= '0;
        have_seq        <= 1'b0;
        lat_cnt         <= 0;
    end else begin
        case (lat_state)
            IDLE: begin
                // o_seq changes
                if (!have_seq || (seq != last_seq_seen)) begin
                    last_seq_seen   <= seq;
                    have_seq        <= 1'b1;
                    lat_state       <= WAIT_PAY;
                end
            end

            WAIT_PAY: begin
                if (pay_xfer) begin
                    lat_cnt     <= 0;
                    lat_state   <= COUNT;
                end
            end

            COUNT: begin
                if (!p_valid) lat_cnt <= lat_cnt + 1;
                else begin
                    // p_valid marks record ready, so report and go idle
                    $display("LATENCY: seq=%0d    cycles=%0d (first payload -> p_valid)", last_seq_seen, lat_cnt);
                    lat_state <= IDLE;
                end
            end
        endcase
    end
end
// send message gien seq and the 12B payload
task automatic send_msg(input [15:0] seq16,
                        input byte  p0, input byte p1, input byte p2, input byte p3,
                        input byte  p4, input byte p5, input byte p6, input byte p7,
                        input byte  p8, input byte p9, input byte pa, input byte pb);

    begin
        // header: seq_hi, seq_lo, len_hi, len_lo (len = 12)
        push_byte(seq16[15:8]);
        push_byte(seq16[7:0]);
        push_byte(8'd0);
        push_byte(8'd12);

        push_byte(p0);  push_byte(p1);  push_byte(p2);  push_byte(p3);
        push_byte(p4);  push_byte(p5);  push_byte(p6);  push_byte(p7);
        push_byte(p8);  push_byte(p9);  push_byte(pa);  push_byte(pb);

        // optional: drop valid between messages
        s_tvalid <= 1'b0;
    end
endtask

task automatic push_byte (input byte b);
    begin
        s_tdata     <= b;
        s_tvalid    <= 1'b1;

        do @(posedge clk); while (!s_tready);
    end
endtask


initial begin : two_messages_with_gap
    @(posedge rst_n);
    m_tready <= 1'b1;
      // TRADE payload = (type=01, id=00 12 34, price=00 00 27 10, size=00 00 00 64)
    send_msg(16'd100, 8'h01, 8'h00,8'h12,8'h34, 8'h00,8'h00,8'h27,8'h10, 8'h00,8'h00,8'h00,8'h64);

    @(posedge clk); m_tready <= 1'b0;
    @(posedge clk); m_tready <= 1'b1;

    // deliberate gap: next seq is 102 (skips 101)
    send_msg(16'd102, 8'h01, 8'h00,8'h12,8'h34, 8'h00,8'h00,8'h27,8'h10,  8'h00,8'h00,8'h00,8'h64);

    // stop driving
    @(posedge clk); s_tvalid <= 1'b0;
    repeat (8) @(posedge clk);
    $finish;
end
endmodule
