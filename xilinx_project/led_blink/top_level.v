`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:54:04 04/12/2021 
// Design Name: 
// Module Name:    top_level 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dsi_host_top(
    /* CLK */
    input  wire             clk_in                  ,
    input  wire             rst_n_in                ,
    /* DDR */
	 /*
    inout  wire [16-1:0]         mcb3_dram_dq            ,
    output wire [14-1:0]         mcb3_dram_a             ,
    output wire [3-1:0]          mcb3_dram_ba            ,
    output wire                  mcb3_dram_ras_n         ,
    output wire                  mcb3_dram_cas_n         ,
    output wire                  mcb3_dram_we_n          ,
    output wire                  mcb3_dram_odt           ,
    output wire                  mcb3_dram_reset_n       ,
    output wire                  mcb3_dram_cke           ,
    output wire                  mcb3_dram_dm            ,
    inout  wire                  mcb3_dram_udqs          ,
    inout  wire                  mcb3_dram_udqs_n        ,
    inout  wire                  mcb3_rzq                ,
    inout  wire                  mcb3_zio                ,
    output wire                  mcb3_dram_udm           ,
	 
    // input                   c3_sys_clk              ,
    // input                   c3_sys_rst_i            ,
    // output  wire                c3_calib_done           ,
    // output                  c3_clk0                 ,
    // output                  c3_rst0                 ,
    inout  wire             mcb3_dram_dqs           ,
    inout  wire             mcb3_dram_dqs_n         ,
    output wire             mcb3_dram_ck            ,
    output wire             mcb3_dram_ck_n          ,
    // input  wire             rzq3                    ,
    // input  wire             zio3                    ,
	 */
	 
	 
    /* DPHY */
	 /*
    output  wire [3:0]      dphy_data_hs_out_p      ,
    output  wire [3:0]      dphy_data_hs_out_n      ,
    output  wire [3:0]      dphy_data_lp_out_p      ,
    output  wire [3:0]      dphy_data_lp_out_n      ,
    output  wire            dphy_clk_hs_out_p       ,
    output  wire            dphy_clk_hs_out_n       ,
    output  wire            dphy_clk_lp_out_p       ,
    output  wire            dphy_clk_lp_out_n       ,
	 */
    /* HDMI parallel */
    input   wire [24-1:0]   hdmi_data               ,
    input   wire            hdmi_hs                 ,
    input   wire            hdmi_vs                 ,
    input   wire            hdmi_de                 ,
    input   wire            hdmi_clk                ,

    /* I2C ADV */
    inout   wire            i2c_scl                 ,
    inout   wire            i2c_sda                 ,
    /* I2C EEPROM */
    /* LED */
	 output wire             led_out 					 ,
    /* UART */
    input  wire             usart_rxd               ,
    output wire             usart_txd
    /* BUTTON */
    );
	 
	 
	 reg [24:0] counter;
	 
	 always @(posedge clk_in) begin
			counter <= counter + 1;
	 end
	 
	 assign led_out = counter[24];
	 
	 endmodule
