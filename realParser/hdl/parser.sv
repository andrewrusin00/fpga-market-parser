module parser (
    input logic             clk,
    input logic             rstn,
    input logic [127:0]     packetIn,
    input logic             packetInValid,
    output logic [15:0]     tradeID,
    output logic [31:0]     price,
    output logic [15:0]     quantity,
    output logic            parsedValid             
);

typedef enum logic [1:0] {IDLE, PARSE} state_t;
state_t state, nextState;

always_ff @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        state <= IDLE;
        tradeID <= 0;
        price <= 0;
        quantity <= 0;
        parsedValid <= 0;
    end else begin 
        state <= nextState;
    end
end

always_comb begin 
    // default assignments (stay idle, hold values)
    nextState = state;
    tradeID = tradeID;
    price = price;
    quantity = quantity;
    parsedValid = 0;
    
    case (state)
        IDLE: if (packetInValid) begin
            // Extract fields from packedIn:
            tradeID = packetIn[127:112];
            price = packetIn[111:80];
            quantity = packetIn[79:64];
            parsedValid = 1;
            nextState = PARSE;
        end
        PARSE: begin       
            // After one cycle go back
            nextState = IDLE;
        end      
    endcase
end
endmodule   
