module uart
#(
    parameter DELAY_FRAMES = 234 // 27,000,000 (27Mhz) / 115200 Baud rate
)
(
    input clk,
    input uart_rx,
    output uart_tx,
    output reg [7:0] switches,
    output reg [7:0] buttons,
    output reg [4:0] keypad,
    input [39:0] seven   
    //input btn1
);

localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [7:0] dataIn = 0;
reg [2:0] rxBitNumber = 0;
reg byteReady = 0;

reg [3:0] buffer = 0;

reg [20:0] xmitCNT = 0;	// 27e6/(2^21) = 12.9 Hz data XMIT frequency
reg startXMIT = 1;

localparam RX_STATE_IDLE = 0;
localparam RX_STATE_START_BIT = 1;
localparam RX_STATE_READ_WAIT = 2;
localparam RX_STATE_READ = 3;
localparam RX_STATE_STOP_BIT = 5;

always @(posedge clk) begin
	xmitCNT <= xmitCNT+1;
	startXMIT = (xmitCNT==0);
end

always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: begin
            if (uart_rx == 0) begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
                byteReady <= 0;
            end
        end 
        RX_STATE_START_BIT: begin
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ_WAIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_READ;
            end
        end
        RX_STATE_READ: begin
            rxCounter <= 1;
            dataIn <= {uart_rx, dataIn[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111)
                rxState <= RX_STATE_STOP_BIT;
            else
                rxState <= RX_STATE_READ_WAIT;
        end
        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_IDLE;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end
    endcase
end

wire byteReceived;
reg prevByteReady;
always @(posedge clk) begin
	prevByteReady <= byteReady;
end
assign byteReceived = (prevByteReady==0)&(byteReady==1);

wire [2:0] msgID;
assign msgID = dataIn[7:5];
	
always @(posedge clk) begin
	if (byteReceived) begin
	case (msgID)
	3'b111 : buffer   <= dataIn[3:0];
	3'b110 : switches <= {buffer, dataIn[3:0]};
	3'b101 : buffer   <= dataIn[3:0];
	3'b100 : buttons  <= {buffer, dataIn[3:0]};
	3'b000 : keypad   <= dataIn[4:0];
	endcase
	end
end

reg [3:0] txState = 0;
reg [24:0] txCounter = 0;
reg [7:0] dataOut = 0;
reg txPinRegister = 1;
reg [2:0] txBitNumber = 0;
reg [2:0] txByteCounter = 0;

assign uart_tx = txPinRegister;

localparam TX_STATE_IDLE = 0;
localparam TX_STATE_START_BIT = 1;
localparam TX_STATE_WRITE = 2;
localparam TX_STATE_STOP_BIT = 3;

always @(posedge clk) begin
    case (txState)
        TX_STATE_IDLE: begin
            if (startXMIT == 1) begin
            	//startXMIT <= 0;
                txState <= TX_STATE_START_BIT;
                txCounter <= 0;
                txByteCounter <= 0;
            end
            else begin
                txPinRegister <= 1;
            end
        end 
        TX_STATE_START_BIT: begin
            txPinRegister <= 0;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState <= TX_STATE_WRITE;
                //dataOut <= testMemory[txByteCounter];
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            //txPinRegister <= dataOut[txBitNumber];
            txPinRegister <=  seven[{txByteCounter, txBitNumber}];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    txState <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            txPinRegister <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                //if (txByteCounter == MEMORY_LENGTH - 1) begin   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                if (txByteCounter == 4) begin
                    //txState <= TX_STATE_DEBOUNCE;
                    txState <= TX_STATE_IDLE;
                end else begin
                    txByteCounter <= txByteCounter + 1;
                    txState <= TX_STATE_START_BIT;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
    endcase      
end
endmodule
