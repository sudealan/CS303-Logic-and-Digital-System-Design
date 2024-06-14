`default_nettype none

module main
(
    input clk,
    input uart_rx,
    output uart_tx,
    output reg [5:0] led,
    input btn1,
    input btn2
);

wire [3:0] d7, d6, d5, d4, d3, d2, d1, d0;
reg [7:0] leds;

reg [4:0] clkdiv;
reg clklow;


wire [7:0] switches;
wire [7:0] buttons;
wire [4:0] keypad;
wire btn1d;
wire [3:0] t10;
wire [3:0] t1;

uart uart1(clk, uart_rx, uart_tx, switches, buttons, keypad, {leds, d7, d6, d5, d4, d3, d2, d1, d0});
calculator calc1(keypad[3:0], keypad[4], clklow, d0, d1, d2, d3, d4, d5, d6, d7); 

//assign clklow = clkdiv[4];

always @(posedge clk) begin
	if(clkdiv[4]) clklow <=1; else clklow <=0;
end

initial begin
	clkdiv = 5'b00000;
    leds = 8'b10101010;
end

always @(posedge clk) begin
	clkdiv <= clkdiv + 1;
end

always @(posedge clk) begin
	led <= ~switches[4:0];
end

endmodule
