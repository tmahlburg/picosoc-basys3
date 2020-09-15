`timescale 1ns / 1ps

/*
 * Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 * Copyright (C) 2020 Till Mahlburg
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

module basys3(
	input clk,

	output RsTx,
	input RsRx,

	output [15:0] led,

	// Qspi_CLK driven via STARTUPE2 primitive below
	output QspiCSn,
	inout [3:0] QspiDB);
	wire QspiCLK;

	// Driving QspiCLK pin using STARTUPE2
	STARTUPE2 STARTUPE2_inst (
		.USRCCLKO(QspiCLK),
		.USRCCLKTS(1'b0));

	wire [0:5] CLKOUT;
	wire CLKFB;
	wire LOCKED;
	// Use PLL to easily change clock speeds
	PLLE2_BASE #(
		.CLKFBOUT_MULT(8),
		.CLKFBOUT_PHASE(0.0),
		.CLKIN1_PERIOD(0.0),
		.CLKOUT0_DIVIDE(16),
		.CLKOUT1_DIVIDE(16),
		.CLKOUT2_DIVIDE(16),
		.CLKOUT3_DIVIDE(16),
		.CLKOUT4_DIVIDE(16),
		.CLKOUT5_DIVIDE(16),
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.DIVCLK_DIVIDE(1)
	) PLLE2_BASE_inst (
		.CLKOUT0(CLKOUT[0]),
		.CLKOUT1(CLKOUT[1]),
		.CLKOUT2(CLKOUT[2]),
		.CLKOUT3(CLKOUT[3]),
		.CLKOUT4(CLKOUT[4]),
		.CLKOUT5(CLKOUT[5]),
		.CLKFBOUT(CLKFB),
		.LOCKED(LOCKED),
		.CLKIN1(clk),
		.PWRDWN(1'b0),
		.RST(1'b0),
		.CLKFBIN(CLKFB)
	);


	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge CLKOUT[0]) begin
	reset_cnt <= reset_cnt + !resetn;
	end

	// Tri-state Qspi signals
	wire [3:0] QspiDB_oe;
	wire [3:0] QspiDB_do;
	wire [3:0] QspiDB_di;

	assign QspiDB[0] = QspiDB_oe[0] ? QspiDB_do[0] : 1'bz;
	assign QspiDB_di[0] = QspiDB[0];
	assign QspiDB[1] = QspiDB_oe[1] ? QspiDB_do[1] : 1'bz;
	assign QspiDB_di[1] = QspiDB[1];
	assign QspiDB[2] = QspiDB_oe[2] ? QspiDB_do[2] : 1'bz;
	assign QspiDB_di[2] = QspiDB[2];
	assign QspiDB[3] = QspiDB_oe[3] ? QspiDB_do[3] : 1'bz;
	assign QspiDB_di[3] = QspiDB[3];

	wire iomem_valid;
	reg iomem_ready;
	wire [3:0] iomem_wstrb;
	wire [31:0] iomem_addr;Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
	wire [31:0] iomem_wdata;
	reg [31:0] iomem_rdata;

	reg [31:0] gpio = 0;

	assign led = gpio

	always @(posedge CLKOUT[0]) begin
		if (!resetn) begin
			gpio <= 0;
		end else begin
			iomem_ready <= 0;
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h03) begin
				iomem_ready <= 1;
				iomem_rdata <= gpio;
				if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
					if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
					if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
					if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
			end
		end
	end

	picosoc #(
		.ENABLE_MULDIV(0),
		.ENABLE_COMPRESSED(0)
	) soc (
		.clk(CLKOUT[0]),
		.resetn(resetn),

		.ser_tx(RsTx),
		.ser_rx(RsRx),

		.flash_csb(QspiCSn),
		.flash_clk(QspiCLK),

		.flash_io0_oe(QspiDB_oe[0]),
		.flash_io1_oe(QspiDB_oe[1]),
		.flash_io2_oe(QspiDB_oe[2]),
		.flash_io3_oe(QspiDB_oe[3]),

		.flash_io0_do(QspiDB_do[0]),
		.flash_io1_do(QspiDB_do[1]),
		.flash_io2_do(QspiDB_do[2]),
		.flash_io3_do(QspiDB_do[3]),

		.flash_io0_di(QspiDB_di[0]),
		.flash_io1_di(QspiDB_di[1]),
		.flash_io2_di(QspiDB_di[2]),
		.flash_io3_di(QspiDB_di[3]),

		.irq_5(1'b0),
		.irq_6(1'b0),
		.irq_7(1'b0),

		.iomem_valid(iomem_valid),
		.iomem_ready(iomem_ready),
		.iomem_wstrb(iomem_wstrb),
		.iomem_addr(iomem_addr),
		.iomem_wdata(iomem_wdata),
		.iomem_rdata(iomem_rdata));
endmodule
