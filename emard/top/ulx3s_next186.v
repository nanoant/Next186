module ulx3s_next186(
//    -- System clock and reset
	input clk_25mhz, // main clock input from external clock source
        input [6:0]btn, // main clock input from external RC reset circuit

//    -- On-board user buttons and status LEDs
	output [7:0]led,
	output [3:0] audio_l,
	output [3:0] audio_r,
//    -- User GPIO (18 I/O pins) Header
	inout [27:2]gn,  // GPIO Header pins available as one data block
	inout gpdi_sda,
	inout gpdi_scl,
	
// Unknown	output [3:0]AD_EOUT,
// Unknown	input [3:0]AD_FB,

//    -- USB Slave (FT230x) interface 
	input  ftdi_txd,
	output ftdi_rxd,
	 
//	-- SDRAM interface (For use with 16Mx16bit or 32Mx16bit SDR DRAM, depending on version)
	output sdram_clk,	// clock to SDRAM
	output sdram_cke,	// clock to SDRAM	
	output sdram_rasn,  // SDRAM RAS
	output sdram_casn,	// SDRAM CAS
	output sdram_wen,	// SDRAM write-enable
	output  [1:0] sdram_ba,	// SDRAM bank-address
	output [12:0] sdram_a,	// SDRAM address bus
	inout  [15:0] sdram_d,	// data bus to/from SDRAM	
	output  [1:0] sdram_dqm,
	output sdram_csn,
	  
//	-- DVI interface
	output [3:0] gpdi_dp, gpdi_dn,
	 
//	-- SD/MMC Interface (Support either SPI or nibble-mode)
	//mmc_dat1
        //mmc_dat2
	//mmc_n_cs
	inout [3:0] sd_d,
	output sd_clk,  // mmc_clk
	output sd_cmd  //mmc_mosiun
	//mmc_miso

//	-- PS2 interface (Both ports accessible via Y-splitter cable)
//	output led[7] //PS2_enable1,
//	inout led[6] //PS2_clk1,
//	inout led[5] //PS2_data1,
//	inout led[4] //PS2_clk2,
//	inout led[3] //PS2_data2 
    );

    parameter C_ddr = 1'b1; // 0:SDR 1:DDR
	
	assign sdram_cke = 1'b1; 	// -- DRAM clock enable
	assign wifi_gpio0 = 1'b1; 	// pull both USB ports D+ and D- to +3.3vcc through 15K resistors
	wire [3:0]LED;
	assign n_led1 = LED[1];

	wire [5:0] vga_r, vga_g, vga_b;
	wire vga_hsync, vga_vsync, vga_blank;
	wire clk_shift, clk_pixel;
	assign clk_pixel = clk_25mhz;

	system sys_inst
	( 
		.CLK_IN(clk_25mhz),
		//.TMDS({gpdi_dp[3], gpdi_dp[0], gpdi_dp[1], gpdi_dp[2]}),

		.clk_pixel_x5(clk_shift),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.vga_hsync(vga_hsync),
		.vga_vsync(vga_vsync),
		.vga_blank(vga_blank),

		.sdr_CLK_out(sdram_clk),
		.sdr_n_CS_WE_RAS_CAS({sdram_csn, sdram_wen, sdram_rasn, sdram_casn}),
		.sdr_BA(sdram_ba),
		.sdr_ADDR(sdram_a),
		.sdr_DATA(sdram_d),
		.sdr_DQM({sdram_dqm[1], sdram_dqm[0]}),
		.LED(LED),
		.BTN_RESET(btn[0]),
		.BTN_NMI(!btn[1]),	
		.RS232_DCE_RXD(ftdi_txd),
		.RS232_DCE_TXD(ftdi_rxd),
		.SD_n_CS(sd_d[3]),
		.SD_DI(sd_cmd),
		.SD_CK(sd_clk),
		.SD_DO(sd_d[0]),
		
		.AUD_L(audio_l[0]),
		.AUD_R(audio_r[0]),

		.PS2_CLK1(),
		.PS2_CLK2(),
		.PS2_DATA1(),
		.PS2_DATA2(),
		
		.RS232_HOST_RXD(),
		.RS232_HOST_TXD(),
		.RS232_HOST_RST(),
		.RS232_EXT_RXD(), // PIN36
		.RS232_EXT_TXD() // PIN32
		//.GPIO({GPIO[7], GPIO[8], GPIO[25], GPIO[24], GPIO[23], GPIO[18], GPIO[15], GPIO[14]})
	);

    // VGA to digital video converter
    wire [1:0] tmds[3:0];
    vga2dvid
    #(
      .C_ddr(C_ddr),
      .C_depth(6),
      .C_shift_clock_synchronizer(1'b1)
    )
    vga2dvid_instance
    (
      .clk_pixel(clk_pixel),
      .clk_shift(clk_shift),
      .in_red(vga_r),
      .in_green(vga_g),
      .in_blue(vga_b),
      .in_hsync(vga_hsync),
      .in_vsync(vga_vsync),
      .in_blank(vga_blank),
      .out_clock(tmds[3]),
      .out_red(tmds[2]),
      .out_green(tmds[1]),
      .out_blue(tmds[0])
    );

    // output TMDS SDR/DDR data to fake differential lanes
    fake_differential
    #(
      .C_ddr(C_ddr)
    )
    fake_differential_instance
    (
      .clk_shift(clk_shift),
      .in_clock(tmds[3]),
      .in_red(tmds[2]),
      .in_green(tmds[1]),
      .in_blue(tmds[0]),
      .out_p(gpdi_dp),
      .out_n(gpdi_dn)
    );


endmodule
