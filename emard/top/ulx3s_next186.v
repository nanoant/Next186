module ulx3s_next186
(
//    -- System clock and reset
    input clk_25mhz, // main clock input from external clock source
    input [6:0] btn, // BTN0=RESET, BTN1=NMI
//    -- On-board user buttons and status LEDs
    output [7:0] led,
    output [3:0] audio_l,
    output [3:0] audio_r,
//    -- User GPIO (18 I/O pins) Header
    inout [27:2] gp, gn,  // GPIO Header pins available as one data block
//    -- USB-serial FT231x interface 
    input  ftdi_txd,
    output ftdi_rxd,
//	-- SDRAM interface (For use with 16Mx16bit or 32Mx16bit SDR DRAM, depending on version)
    output sdram_clk,	// clock to SDRAM
    output sdram_cke,	// clock to SDRAM	
    output sdram_rasn,	// SDRAM RAS
    output sdram_casn,	// SDRAM CAS
    output sdram_wen,	// SDRAM write-enable
    output  [1:0] sdram_ba,	// SDRAM bank-address
    output [12:0] sdram_a,	// SDRAM address bus
    inout  [15:0] sdram_d,	// data bus to/from SDRAM	
    output  [1:0] sdram_dqm,
    output sdram_csn,
//	-- DVI interface
    output [3:0] gpdi_dp, //gpdi_dn,
//    inout gpdi_sda,
//    inout gpdi_scl,
//	-- SD/MMC Interface (Support either SPI or nibble-mode)
    output sd_clk,    // clk
    output sd_cmd,    // mosi
    inout [3:0] sd_d, // d0=miso d3=csn
//	-- PS2 interface
    output usb_fpga_pu_dp, usb_fpga_pu_dn,
    inout  usb_fpga_bd_dp, usb_fpga_bd_dn,
    output wifi_gpio0
);
    parameter C_ddr = 1'b1; // 0:SDR 1:DDR
    parameter C_loudness = 0; // 0-3 but
    // 2 and 3 produce unbootable bitstream
    // 1 boots but is unstable, occassional illegal istruction
    // 0 works most stable, only the sound is very quiet
    // design is overcrowded and works by LUCK

    assign wifi_gpio0 = btn[0]; // for ULX3S with ESP32 firmware

    // enable pull ups for PS/2 on both D+ and D-
    assign usb_fpga_pu_dp = 1'b1; 
    assign usb_fpga_pu_dn = 1'b1;

    assign gp[22] = 1'b1; // US3 PULLUP
    assign gn[22] = 1'b1; // US3 PULLUP

    assign sdram_cke = 1'b1; 	// -- DRAM clock enable

    wire [5:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, vga_blank;

    wire clk_25, clk_125, clk_125p, clk_50, clk_11;
    clk_system
    clk_system_inst
    (
	.clk_in(clk_25mhz),
	.clk_25(clk_25),
	.clk_125(clk_125),
	.clk_125p(clk_125p)
    );

    clk_aux
    clk_aux_inst
    (
	.clk_in(clk_25mhz),
	.clk_11(clk_11),
	.clk_50(clk_50)
    );

    wire clk_shift, clk_pixel;
    wire clk_cpu, clk_sdr, clk_audio, clk_beep, clk_dsp, clk_uart;
    assign clk_cpu   = clk_50;   // 50-75 MHz
    assign clk_sdr   = clk_125;  // 125-166 MHz
    assign sdram_clk = clk_125p; // 125-166 MHz, must be =clk_sdr phase shifted 60-225 deg
    assign clk_pixel = clk_25;   // should be 25 MHz
    assign clk_shift = clk_125;  // should be 125 MHz, must be clk_pixel*5
    assign clk_dsp   = clk_50;   // should be 80 MHz, must be >= clk_cpu/2
    assign clk_audio = clk_11;   // should be 11.2896 MHz
    assign clk_beep  = clk_25;   // should be 25 MHz
    assign clk_uart  = clk_25;   // should be 29.4912 MHz

    system sys_inst
    ( 
      .clk_cpu(clk_cpu),           //  50-75 MHz x186 CPU
      .clk_pixel(clk_pixel),       //  25 MHz VIDEO
      .clk_sdr(clk_sdr),           // 125-166 MHz SDRAM
      .clk_dsp(clk_dsp),           //  25-80 MHz (>=clk_cpu/2) 32-bit
      .clk_audio(clk_audio),       //  11.2896 MHz (44100*256)
      .clk_beep(clk_beep),         //  25 MHz beep timer
      .clk_uart(clk_uart),         //  29.4912 MHz

      .vga_r(vga_r),
      .vga_g(vga_g),
      .vga_b(vga_b),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_blank(vga_blank),

      .sdr_n_CS_WE_RAS_CAS({sdram_csn, sdram_wen, sdram_rasn, sdram_casn}),
      .sdr_BA(sdram_ba),
      .sdr_ADDR(sdram_a),
      .sdr_DATA(sdram_d),
      .sdr_DQM({sdram_dqm[1], sdram_dqm[0]}),
      .LED(led[3:0]),
      .BTN_RESET(!btn[0]),
      .BTN_NMI(btn[1]),
      .RS232_DCE_RXD(ftdi_txd),
      .RS232_DCE_TXD(ftdi_rxd),
      .SD_n_CS(sd_d[3]),
      .SD_DI(sd_cmd),
      .SD_CK(sd_clk),
      .SD_DO(sd_d[0]),
		
      .AUD_L(audio_l[C_loudness]),
      .AUD_R(audio_r[C_loudness]),

      // Keyboard
      .PS2_CLK1(usb_fpga_bd_dp),
      .PS2_DATA1(usb_fpga_bd_dn),
      // Mouse
      .PS2_CLK2(gn[21]),   // mouse clock US3, flat cable on pins up
      .PS2_DATA2(gp[21]), // mouse data US3, flat cable on pins up

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
    /*
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
    */
    // vendor-specific modules for DDR differential GPDI output
    generate
      wire [3:0] ddr_d;
      genvar i;
      for(i = 0; i < 4; i++)
      begin
        ODDRX1F tmds2ddr (.D0(tmds[i][0]), .D1(tmds[i][1]), .Q(ddr_d[i]), .SCLK(clk_shift), .RST(0));
        OLVDS   ddr2gpdi (.A(ddr_d[i]), .Z(gpdi_dp[i]) /*, .ZN(gpdi_dn[i]) */);
      end
    endgenerate
endmodule
