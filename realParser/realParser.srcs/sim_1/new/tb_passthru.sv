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

wire xfer_in = s_tvalid && s_tready;
wire xfer_out = m_tvalid && m_tready;

// DUT - device under test

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

// middle: mid_* -> framer -> par_*
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

// downstream: par_* -> parser -> tb sink (m_*)
market_parser #(.W(W)) u_parser (
    .clk(clk),
    .rst_n(rst_n),

    // from passthru
    .s_tdata(par_tdata),
    .s_tvalid(par_tvalid),
    .s_tready(par_tready),
    .s_tlast(par_tlast),

    // to tb sink
    .m_tdata(m_tdata),
    .m_tvalid(m_tvalid),
    .m_tready(m_tready),
    .m_tlast(m_tlast),

    // parsed fields
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
// Expect m_tlast = 1 on third transfer
// One TRADE message:
// type=0x01, instrument_id=0x001234, price=0x00002710 (decimal 10000), size=0x00000064 (100)
initial begin : stimulus_one_msg
    @(posedge rst_n);

    @(posedge clk); s_tdata <= 8'h01; s_tvalid <= 1'b1; // msg_type
    @(posedge clk); s_tdata <= 8'h00;                   // instrument_id [23:16]
    @(posedge clk); s_tdata <= 8'h12;                   // instrument_id [15:8]
    @(posedge clk); s_tdata <= 8'h34;                   // instrument_id [7:0]
    @(posedge clk); s_tdata <= 8'h00;                   // price [31:24]
    @(posedge clk); s_tdata <= 8'h00;                   // price [23:16]
    @(posedge clk); s_tdata <= 8'h27;                   // price [15:8]
    @(posedge clk); s_tdata <= 8'h10;                   // price [7:0]
    @(posedge clk); s_tdata <= 8'h00;                   // size [31:24]
    @(posedge clk); s_tdata <= 8'h00;                   // size [23:16]
    @(posedge clk); s_tdata <= 8'h00;                   // size [15:8]
    @(posedge clk); s_tdata <= 8'h64;                   // size [7:0]  <-- expect TLAST on this transfer

    @(posedge clk); s_tvalid <= 1'b0;                   // stop driving
    repeat (3) @(posedge clk);
    $finish;
end

endmodule
