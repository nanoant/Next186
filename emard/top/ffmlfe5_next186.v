module ffmlfe5_next186
(
    input  clk_100mhz_p,  // core should use only positive when in differential mode
    output [3:0] vid_d_p, // core should use only positive when in differential mode
    // RS232
    output uart3_txd,
    input  uart3_rxd,
    // FFM Module IO
    inout  [7:0] fioa,   // PS/2, AUDIO, LEDs
    inout  [31:20] fiob, // DB9 JOY1,2
    output [2:0] led,
    // SD card (SPI)
    output sd_f_clk, sd_f_cmd,
    inout  [3:0] sd_f_d, 
    //input  sd_f_cdet,
    //  SDRAM interface (For use with 16Mx16bit or 32Mx16bit SDR DRAM, depending on version)
    output dr_cs_n,       // chip select
    output dr_clk,        // clock to SDRAM
    output dr_cke,        // clock enable to SDRAM
    output dr_ras_n,      // SDRAM RAS
    output dr_cas_n,      // SDRAM CAS
    output dr_we_n,       // SDRAM write-enable
    output [12:0] dr_a,   // SDRAM address bus
    output [1:0] dr_ba,   // SDRAM bank-address
    output [3:0] dr_dqm,  // byte select
    inout  [31:0] dr_d    // data bus to/from SDRAM
);
    parameter C_ddr = 1'b1; // 0:SDR 1:DDR

/*
  n_joy1(3)<= fiob(20) ; -- up
  n_joy1(2)<= fiob(21) ; -- down
  n_joy1(1)<= fiob(22) ; -- left
  n_joy1(0)<= fiob(23) ; -- right
  n_joy1(4)<= fiob(24) ; -- fire
  n_joy1(5)<= fiob(25) ; -- fire2

  n_joy2(3)<= fiob(26) ; -- up
  n_joy2(2)<= fiob(27) ; -- down
  n_joy2(1)<= fiob(28) ; -- left 
  n_joy2(0)<= fiob(29) ; -- right  
  n_joy2(4)<= fiob(30) ; -- fire
  n_joy2(5)<= fiob(31) ; -- fire2 
*/

    wire [5:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, vga_blank;

    wire clk_25, clk_125, clk_125p, clk_50, clk_11;
    clk_system
    clk_system_inst
    (
      .clk_in(clk_100mhz_p),
      .clk_25(clk_25),
      .clk_125(clk_125),
      .clk_125p(clk_125p)
    );

    clk_aux
    clk_aux_inst
    (
      .clk_in(clk_100mhz_p),
      .clk_11(clk_11),
      .clk_50(clk_50)
    );

    wire clk_shift, clk_pixel;
    wire clk_cpu, clk_sdr, clk_audio, clk_beep, clk_dsp, clk_uart;
    assign clk_cpu   = clk_50;   // 50-75 MHz
    assign clk_sdr   = clk_125;  // 125-166 MHz
    assign dr_clk    = clk_125p; // 125-166 MHz 90 deg, must be =clk_sdr phase shifted 0-200 deg
    assign clk_pixel = clk_25;   // should be 25 MHz
    assign clk_shift = clk_125;  // should be 125 MHz, must be clk_pixel*5
    assign clk_dsp   = clk_50;   // should be 80 MHz, must be >= clk_cpu/2
    assign clk_audio = clk_11;   // should be 11.2896 MHz
    assign clk_beep  = clk_25;   // should be 25 MHz
    assign clk_uart  = clk_25;   // should be 18.432 MHz

    assign sd_f_d[1] = 1'b1;
    assign sd_f_d[2] = 1'b1;

    assign dr_cke = 1'b1;
    assign dr_dqm[2] = 1'b1;
    assign dr_dqm[3] = 1'b1;
    assign dr_d[31:16] = 16'hzzzz;

    wire [3:0] sysled;
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

      .sdr_n_CS_WE_RAS_CAS({dr_cs_n, dr_we_n, dr_ras_n, dr_cas_n}),
      .sdr_BA(dr_ba),
      .sdr_ADDR(dr_a),
      .sdr_DATA(dr_d[15:0]),
      .sdr_DQM({dr_dqm[1], dr_dqm[0]}),
      .LED(sysled),
      .BTN_RESET(~fiob[31]), // JOY2 fire1
      .BTN_NMI(~fiob[30]), // JOY2 fore2
      .RS232_DCE_RXD(uart3_rxd),
      .RS232_DCE_TXD(uart3_txd),
      .SD_n_CS(sd_f_d[3]),
      .SD_DI(sd_f_cmd),
      .SD_CK(sd_f_clk),
      .SD_DO(sd_f_d[0]),

      .AUD_L(fioa[2]),
      .AUD_R(fioa[0]),

      // Keyboard
      .PS2_CLK1(fioa[6]),
      .PS2_DATA1(fioa[4]),
      // Mouse
      .PS2_CLK2(fioa[3]),
      .PS2_DATA2(fioa[1]),

      .RS232_HOST_RXD(),
      .RS232_HOST_TXD(),
      .RS232_HOST_RST(),
      .RS232_EXT_RXD(), // PIN36
      .RS232_EXT_TXD() // PIN32
      //.GPIO({GPIO[7], GPIO[8], GPIO[25], GPIO[24], GPIO[23], GPIO[18], GPIO[15], GPIO[14]})
    );

    assign led[2:0] = sysled[2:0];

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
      .out_p(vid_d_p),
      .out_n()
    );
endmodule
