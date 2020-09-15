/*
*  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
*  Copyright (C) 2020  Till Mahlburg
*
*  Permission to use, copy, modify, and/or distribute this software for any
*  purpose with or without fee is hereby granted, provided that the above
*  copyright notice and this permission notice appear in all copies.
*
*  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
*  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
*  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
*  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
*  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
*  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
*  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*
*/

`timescale 1ns / 1ps

`define SIMULATION

module basys3_tb;
	reg clk = 1'b0;
	always #5 clk <= ~clk;

	localparam ser_half_period = 53;
	event ser_sample;

	initial begin
		$dumpfile("basys3_tb.vcd");
		$dumpvars(0, basys3_tb);

		repeat (6) begin
			repeat (50000) @(posedge clk);
			$display("+50000 cycles");
		end
		$finish;
	end

	integer cycle_cnt = 0;

	always @(posedge clk) begin
		cycle_cnt <= cycle_cnt + 1;
	end

	wire [15:0] led;

	wire ser_rx;
	wire ser_tx;

	wire flash_csb;
	wire flash_clk;
	wire [3:0] flash_io;

	always @(led) begin
		#1 $display("%b", led);
	end

	basys3 dut (
		.clk(clk),
		.led(led),
		.RsRx(ser_rx),
		.RsTx(ser_tx),
		.QspiCSn(flash_csb),
		.QspiCLK(flash_clk),
		.QspiDB(flash_io)
	);

	spiflash spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io[0]),
		.io1(flash_io[1]),
		.io2(flash_io[2]),
		.io3(flash_io[3])
	);

	reg [7:0] buffer;

	always begin
		@(negedge ser_tx);

		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // start bit

		repeat (8) begin
			repeat (ser_half_period) @(posedge clk);
			repeat (ser_half_period) @(posedge clk);
			buffer = {ser_tx, buffer[7:1]};
			-> ser_sample; // data bit
		end

		repeat (ser_half_period) @(posedge clk);
		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // stop bit

		if (buffer < 32 || buffer >= 127)
			$display("Serial data: %d", buffer);
		else
			$display("Serial data: '%c'", buffer);
	end
endmodule
