`timescale 1ns / 1ps

`default_nettype none

`include "prj_defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    14:06:55 06/26/2020
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


//                                         +-----------------+
//                                         |                 |
//                                         |                 |                   +--------------+
//                                         |     Picorv5     |    +------------->+    PROG      +<---------->
//                                         |                 |    |              |    MEM       |
//                                         |                 |    |              +--------------+
//                                         +--------+--------+    |
//              +-------------+                     |         +---+
//        <-----+    GPIO     +<-----+              |         |                  +--------------+
//              |             |      |        +-----v-----+   |  +-------------->+    I2C       +<---------->
//              +-------------+      +--------+           <---+  |               |  EEPROM      |
//                                +---------->+   MUX     <------+               +--------------+
//              +-------------+   |           |           |---------------+
//              |             +<--+   +------->           +------------+  |      +--------------+
//        <----->    I2C      |       |       +-+--+----+-+            |  |      |    UART      +<--------->
//              |    HDMI     |       |         ^  |    |              |  +----->+              |
//              +-------------+       |         |  |    |              |         +--------------+
//                                    |         |  |    +-----------+  +-------------+
//                         +----------+         |  v                |                |
//                         |             +------+--+-----+       +--v-----+       +--v----------+
//              +----------v---+         |               |       |        |       |             |
//              |              |         |               |       |        |       |             |
//              |              |         |     DDR3 MCB  |       | DSI    +------>+   DSI HOST  +-------->
//  +---------->+   HDMI recv  +-------->+               +------>+ Reader |       |             |
//              |              |         |               |       |        |       |   DSI GPIO  |
//              |              |         |               |       |        |       |             |
//              +--------------+         +---------------+       +--------+       +-------------+

//////////////////////////////////////////////////////////////////////////////////
module dsi_host_top(
    /* CLK */
    input  wire             clk_in                  ,
    input  wire             rst_n_in                ,
    /* DDR */
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
    /* DPHY */
    output  wire [3:0]      dphy_data_hs_out_p      ,
    output  wire [3:0]      dphy_data_hs_out_n      ,
    output  wire [3:0]      dphy_data_lp_out_p      ,
    output  wire [3:0]      dphy_data_lp_out_n      ,
    output  wire            dphy_clk_hs_out_p       ,
    output  wire            dphy_clk_hs_out_n       ,
    output  wire            dphy_clk_lp_out_p       ,
    output  wire            dphy_clk_lp_out_n       ,
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
    output wire             led_out                 ,
    /* UART */
    input  wire             usart_rxd               ,
    output wire             usart_txd
    /* BUTTON */
    );

// assign led_out = 0;

localparam [ 0:0] ENABLE_COUNTERS = 1;
localparam [ 0:0] BARREL_SHIFTER = 0;
localparam [ 0:0] COMPRESSED_ISA = 0;
localparam [ 0:0] ENABLE_MUL = 0;
localparam [ 0:0] ENABLE_DIV = 0;
localparam [ 0:0] ENABLE_IRQ_QREGS = 1;
localparam [31:0] PROGADDR_RESET =32'h0100_0000;
localparam [31:0] PROGADDR_IRQ = 32'h0100_0010;
parameter integer MEM_WORDS = 8192;
// parameter [31:0] STACKADDR = 32'h0000_0000 + (4*MEM_WORDS);
parameter [31:0] STACKADDR = 32'h0100_0800;       // end of memory

wire c3_sys_rst_i;
wire sys_clk;
wire sys_rst_n;
wire clk_pre_pll;
wire sys_pll_locked;

wire dsi_phy_clk;
wire dsi_phy_rst_n;

wire dsi_io_clk;
wire dsi_io_clk_clk;
wire dsi_io_rst_n;
wire dsi_io_serdes_latch;
wire dsi_io_clk_serdes_latch;

wire hdmi_rst;
wire hdmi_clk_buf;

wire c3_clk0;
wire c3_rst0;
wire c3_sys_clk;
wire c3_calib_done;

wire rst_n_in_sync;
wire clk_in_sync;
wire clk_in_ddr;

wire [4 - 1:0]	                    mst_core_axi_awid;
wire [32 - 1:0]	                mst_core_axi_awaddr;
wire [7:0]	                        mst_core_axi_awlen;
wire [2:0]	                        mst_core_axi_awsize;
wire [1:0]	                        mst_core_axi_awburst;
wire [0:0]	                        mst_core_axi_awlock;
wire [3:0]	                        mst_core_axi_awcache;
wire [2:0]	                        mst_core_axi_awprot;
wire [3:0]	                        mst_core_axi_awqos;
wire   	                        mst_core_axi_awvalid;
wire   	                        mst_core_axi_awready;
wire [32 - 1:0]                    mst_core_axi_wdata;
wire [32/8 - 1:0]                  mst_core_axi_wstrb;
wire                               mst_core_axi_wlast;
wire                               mst_core_axi_wvalid;
wire  	                            mst_core_axi_wready;
wire [4 - 1:0]                     mst_core_axi_bid;
wire [4 - 1:0]                     mst_core_axi_wid;
wire [1:0]                         mst_core_axi_bresp;
wire                               mst_core_axi_bvalid;
wire                               mst_core_axi_bready;
wire [4 - 1:0]                     mst_core_axi_arid;
wire [32 - 1:0]                    mst_core_axi_araddr;
wire [7:0]                         mst_core_axi_arlen;
wire [2:0]                         mst_core_axi_arsize;
wire [1:0]                         mst_core_axi_arburst;
wire [0:0]                         mst_core_axi_arlock;
wire [3:0]                         mst_core_axi_arcache;
wire [2:0]                         mst_core_axi_arprot;
wire [3:0]                         mst_core_axi_arqos;
wire                               mst_core_axi_arvalid;
wire                               mst_core_axi_arready;
wire [4 - 1:0]                     mst_core_axi_rid;
wire [32 - 1:0]                    mst_core_axi_rdata;
wire [1:0]                         mst_core_axi_rresp;
wire                               mst_core_axi_rlast;
wire                               mst_core_axi_rvalid;
wire                               mst_core_axi_rready;

wire [4 - 1:0]                     pix_axi_arid;
wire [24 - 1:0]                    pix_axi_araddr;
wire [7:0]                         pix_axi_arlen;
wire [2:0]                         pix_axi_arsize;
wire [1:0]                         pix_axi_arburst;
wire [0:0]                         pix_axi_arlock;
wire [3:0]                         pix_axi_arcache;
wire [2:0]                         pix_axi_arprot;
wire [3:0]                         pix_axi_arqos;
wire                               pix_axi_arvalid;
wire                               pix_axi_arready;
wire [4 - 1:0]                     pix_axi_rid;
wire [32 - 1:0]                    pix_axi_rdata;
wire [1:0]                         pix_axi_rresp;
wire                               pix_axi_rlast;
wire                               pix_axi_rvalid;
wire                               pix_axi_rready;

wire [4 - 1:0]	                    hdmi_axi_awid;
wire [32 - 1:0]	                    hdmi_axi_awaddr;
wire [7:0]	                        hdmi_axi_awlen;
wire [2:0]	                        hdmi_axi_awsize;
wire [1:0]	                        hdmi_axi_awburst;
wire [0:0]	                        hdmi_axi_awlock;
wire [3:0]	                        hdmi_axi_awcache;
wire [2:0]	                        hdmi_axi_awprot;
wire [3:0]	                        hdmi_axi_awqos;
wire   	                            hdmi_axi_awvalid;
wire   	                            hdmi_axi_awready;
wire [32 - 1:0]                     hdmi_axi_wdata;
wire [32/8 - 1:0]                   hdmi_axi_wstrb;
wire                                hdmi_axi_wlast;
wire                                hdmi_axi_wvalid;
wire  	                            hdmi_axi_wready;
wire [4 - 1:0]                      hdmi_axi_bid;
wire [4 - 1:0]                      hdmi_axi_wid;
wire [1:0]                          hdmi_axi_bresp;
wire                                hdmi_axi_bvalid;
wire                                hdmi_axi_bready;

wire    [32 - 1:0]                  s0_bus_addr;
wire                                s0_bus_read;
wire    [32-1:0]                    s0_bus_readdata;
wire    [1:0]                       s0_bus_response;
wire                                s0_bus_write;
wire    [32-1:0]                    s0_bus_writedata;
wire    [3:0]                       s0_bus_byteenable;
wire                                s0_bus_waitrequest;

wire [31:0]                        st_data;
wire                               st_valid;
wire                               st_endofpacket;
wire                               st_startofpacket;
wire                               st_ready;

wire [31:0]                        st_gen_data;
wire                               st_gen_valid;
wire                               st_gen_endofpacket;
wire                               st_gen_startofpacket;
wire                               st_gen_ready;

wire                               ram_mem_read;
wire [31:0]                        ram_mem_readdata;
wire [1:0]                         ram_mem_response;
wire                               ram_mem_write;
wire [31:0]                        ram_mem_writedata;
wire [3:0]                         ram_mem_byteenable;
wire                               ram_mem_waitrequest;

wire                               ctrl_pix_reader_read;
wire [31:0]                        ctrl_pix_reader_readdata;
wire [1:0]                         ctrl_pix_reader_response;
wire                               ctrl_pix_reader_write;
wire [31:0]                        ctrl_pix_reader_writedata;
wire [3:0]                         ctrl_pix_reader_byteenable;
wire                               ctrl_pix_reader_waitrequest;

wire                               ctrl_dsi_read;
wire [31:0]                        ctrl_dsi_readdata;
wire [1:0]                         ctrl_dsi_response;
wire                               ctrl_dsi_write;
wire [31:0]                        ctrl_dsi_writedata;
wire [3:0]                         ctrl_dsi_byteenable;
wire                               ctrl_dsi_waitrequest;

wire                               ctrl_uart_read;
wire [31:0]                        ctrl_uart_readdata;
wire [1:0]                         ctrl_uart_response;
wire                               ctrl_uart_write;
wire [31:0]                        ctrl_uart_writedata;
wire [3:0]                         ctrl_uart_byteenable;
wire                               ctrl_uart_waitrequest;

wire                               ctrl_prog_mem_read;
wire [31:0]                        ctrl_prog_mem_readdata;
wire [1:0]                         ctrl_prog_mem_response;
wire                               ctrl_prog_mem_write;
wire [31:0]                        ctrl_prog_mem_writedata;
wire [3:0]                         ctrl_prog_mem_byteenable;
wire                               ctrl_prog_mem_waitrequest;

wire                               ctrl_hdmi_read;
wire [31:0]                        ctrl_hdmi_readdata;
wire [1:0]                         ctrl_hdmi_response;
wire                               ctrl_hdmi_write;
wire [31:0]                        ctrl_hdmi_writedata;
wire [3:0]                         ctrl_hdmi_byteenable;
wire                               ctrl_hdmi_waitrequest;

wire                               ctrl_pg_read;
wire [31:0]                        ctrl_pg_readdata;
wire [1:0]                         ctrl_pg_response;
wire                               ctrl_pg_write;
wire [31:0]                        ctrl_pg_writedata;
wire [3:0]                         ctrl_pg_byteenable;
wire                               ctrl_pg_waitrequest;

wire                               ctrl_i2c_read;
wire [31:0]                        ctrl_i2c_readdata;
wire [1:0]                         ctrl_i2c_response;
wire                               ctrl_i2c_write;
wire [31:0]                        ctrl_i2c_writedata;
wire [3:0]                         ctrl_i2c_byteenable;
wire                               ctrl_i2c_waitrequest;

wire                               ctrl_gpio_read;
wire [31:0]                        ctrl_gpio_readdata;
wire [1:0]                         ctrl_gpio_response;
wire                               ctrl_gpio_write;
wire [31:0]                        ctrl_gpio_writedata;
wire [3:0]                         ctrl_gpio_byteenable;
wire                               ctrl_gpio_waitrequest;

wire                               ctrl_sys_timer_read;
wire [31:0]                        ctrl_sys_timer_readdata;
wire [1:0]                         ctrl_sys_timer_response;
wire                               ctrl_sys_timer_write;
wire [31:0]                        ctrl_sys_timer_writedata;
wire [3:0]                         ctrl_sys_timer_byteenable;
wire                               ctrl_sys_timer_waitrequest;

wire [32-1:0] irq_vec;
wire          dsi_irq;
wire          usart_irq;
wire          i2c_1_irq;
wire          i2c_2_irq;

// assign  irq_vec = {28'b0, dsi_irq, usart_irq, i2c_1_irq, i2c_2_irq};
assign  irq_vec = 32'b0;

//* Reset Controller
`ifdef SPARTAN7
assign hdmi_clk_buf = hdmi_clk;
`else
IBUFG #(
      .IOSTANDARD("DEFAULT")
) IBUFG_hdmi_clk (
      .O(hdmi_clk_buf), // Clock buffer output
      .I(hdmi_clk)  // Clock buffer input (connect directly to top-level port)
   );
`endif

 por_controller#(
    .INP_RESYNC_SIZE(128)
)por_controller_0(
    .clk_input                   (clk_in_sync       ),
    .rst_n_input                 (rst_n_in          ),

    .rst_n_output                (rst_n_in_sync      ),

`ifdef SIMULATION
    .pll_1_locked                (sys_pll_locked    ), //
    .pll_2_locked                (1'b1    ), //
`else
    .pll_1_locked                (sys_pll_locked    ), //
    .pll_2_locked                (c3_calib_done    ), //
`endif

    .clk_1_in                    (sys_clk           ),
    .rst_1_out                   (sys_rst_n         ),

    // .clk_2_in                    (dsi_io_clk        ),
    // .rst_2_out                   (dsi_io_rst_n      ),

    .clk_3_in                    (dsi_phy_clk       ),
    .rst_3_out                   (dsi_phy_rst_n     ),

    .clk_4_in                    (hdmi_clk_buf      ),
    .rst_4_out                   (hdmi_rst          ),

    .clk_5_in                    (1'b0              ),
    .rst_5_out                   ()
);


//* RISC V core +
 picorv32_wrapper #(
    .STACKADDR(STACKADDR),
    .PROGADDR_RESET(PROGADDR_RESET),
    .PROGADDR_IRQ(32'h0000_0000),
    .BARREL_SHIFTER(0),
    .COMPRESSED_ISA(0),
    .ENABLE_MUL(1),
    .ENABLE_DIV(1),
    .ENABLE_IRQ_QREGS(0)
 ) picorv32_core (
    .clk                     (sys_clk               ),
    .rst_n                   (sys_rst_n             ),

    .bus_addr                (s0_bus_addr           ),
    .bus_read                (s0_bus_read           ),
    .bus_readdata            (s0_bus_readdata       ),
    .bus_response            (s0_bus_response       ),
    .bus_write               (s0_bus_write          ),
    .bus_writedata           (s0_bus_writedata      ),
    .bus_byteenable          (s0_bus_byteenable     ),
    .bus_waitrequest         (s0_bus_waitrequest    ),

    .irq                     (irq_vec               )
);

//* Interconnect (MUX) +
/*
Memory Map

BASE ADDR           MASK          SIZE         COMMENT
------------------------------------------------------------
0x0000_0000     0xFFFC_0000       2^18          DDR
0x0100_0000     0xFFFF_E000       2^12          PROG_MEM
0x0101_0000     0xFFFF_FF00       2^8           HDMI
0x0101_0100     0xFFFF_FF00       2^8           PATTERN GENERATOR
0x0101_0200     0xFFFF_FF00       2^8           PIX READER
0x0101_0300     0xFFFF_FF00       2^8           DSI
0x0101_0400     0xFFFF_FF00       2^8           USART
0x0101_0500     0xFFFF_FF00       2^8           I2C HDMI
0x0101_0600     0xFFFF_FF00       2^8           GPIO
0x0101_0700     0xFFFF_FF00       2^8           SYS_TIMER
*/

parameter M0_ADDR_WIDTH = 18;//$clog2(!(32'hFFFC_0000));
parameter M1_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));
parameter M2_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));
parameter M3_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));
parameter M4_ADDR_WIDTH = 13;//$clog2(!(32'hFFFF_E000));
parameter M5_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));
parameter M6_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));
parameter M7_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));
parameter M8_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));
parameter M9_ADDR_WIDTH = 8;//$clog2(!(32'hFFFF_FF00));

wire [M0_ADDR_WIDTH-1:0]                         ram_mem_address;
wire [M2_ADDR_WIDTH-1:0]                         ctrl_pix_reader_address;
wire [M3_ADDR_WIDTH-1:0]                         ctrl_dsi_address;
wire [M4_ADDR_WIDTH-1:0]                         ctrl_prog_mem_address;
wire [M5_ADDR_WIDTH-1:0]                         ctrl_uart_address;
wire [M1_ADDR_WIDTH-1:0]                         ctrl_hdmi_address;
wire [M9_ADDR_WIDTH-1:0]                         ctrl_pg_address;
wire [M6_ADDR_WIDTH-1:0]                         ctrl_i2c_address;
wire [M7_ADDR_WIDTH-1:0]                         ctrl_gpio_address;
wire [M8_ADDR_WIDTH-1:0]                         ctrl_sys_timer_address;

interconnect_mod #(
    .M0_BASE(32'h0000_0000),    //* DDR
    .M0_MASK(32'hFFFC_0000),    //* DDR
    .M0_ADDR_W(M0_ADDR_WIDTH),
    .M1_BASE(32'h0100_1000),    // HDMI
    .M1_MASK(32'hFFFF_FF00),    // HDMI
    .M1_ADDR_W(M1_ADDR_WIDTH),
    .M2_BASE(32'h0101_0200),    //* PIX READER
    .M2_MASK(32'hFFFF_FF00),    //* PIX READER
    .M2_ADDR_W(M2_ADDR_WIDTH),
    .M3_BASE(32'h0101_0300),    //* DSI
    .M3_MASK(32'hFFFF_FF00),    //* DSI
    .M3_ADDR_W(M3_ADDR_WIDTH),
    .M4_BASE(32'h0100_0000),    //* PROG MEM
    .M4_MASK(32'hFFFF_E000),    //* PROG MEM
    .M4_ADDR_W(M4_ADDR_WIDTH),
    .M5_BASE(32'h0101_0400),    //* UART
    .M5_MASK(32'hFFFF_FF00),    //* UART
    .M5_ADDR_W(M5_ADDR_WIDTH),
    .M6_BASE(32'h0101_0500),    //! I2C HDMI
    .M6_MASK(32'hFFFF_FF00),    //! I2C HDMI
    .M6_ADDR_W(M6_ADDR_WIDTH),
    .M7_BASE(32'h0101_0600),    //!  GPIO
    .M7_MASK(32'hFFFF_FF00),    //!  GPIO
    .M7_ADDR_W(M7_ADDR_WIDTH),
    .M8_BASE(32'h0101_0700),    //!  SYS_TIMER
    .M8_MASK(32'hFFFF_FF00),    //!  SYS_TIMER
    .M8_ADDR_W(M8_ADDR_WIDTH),
    .M9_BASE(32'h0101_0100),    //! PATTERN GENERATOR
    .M9_MASK(32'hFFFF_FF00),    //! PATTERN GENERATOR
    .M9_ADDR_W(M9_ADDR_WIDTH)
)interconnect_mod_0(
    // Slave port 0
    .s0_bus_addr                (s0_bus_addr            ),
    .s0_bus_read                (s0_bus_read            ),
    .s0_bus_readdata            (s0_bus_readdata        ),
    .s0_bus_response            (s0_bus_response        ),
    .s0_bus_write               (s0_bus_write           ),
    .s0_bus_writedata           (s0_bus_writedata       ),
    .s0_bus_byteenable          (s0_bus_byteenable      ),
    .s0_bus_waitrequest         (s0_bus_waitrequest     ),

    //* Master port 0
    .m0_bus_addr                (ram_mem_address        ),
    .m0_bus_read                (ram_mem_read           ),
    .m0_bus_readdata            (ram_mem_readdata       ),
    .m0_bus_response            (ram_mem_response       ),
    .m0_bus_write               (ram_mem_write          ),
    .m0_bus_writedata           (ram_mem_writedata      ),
    .m0_bus_byteenable          (ram_mem_byteenable     ),
    .m0_bus_waitrequest         (ram_mem_waitrequest    ),

    //* Master port 1
    .m1_bus_addr                (ctrl_hdmi_address              ),
    .m1_bus_read                (ctrl_hdmi_read                 ),
    .m1_bus_readdata            (ctrl_hdmi_readdata             ),
    .m1_bus_response            (ctrl_hdmi_response             ),
    .m1_bus_write               (ctrl_hdmi_write                ),
    .m1_bus_writedata           (ctrl_hdmi_writedata            ),
    .m1_bus_byteenable          (ctrl_hdmi_byteenable           ),
    .m1_bus_waitrequest         (ctrl_hdmi_waitrequest          ),

    //* Master port 2
    .m2_bus_addr                (ctrl_pix_reader_address       ),
    .m2_bus_read                (ctrl_pix_reader_read          ),
    .m2_bus_readdata            (ctrl_pix_reader_readdata      ),
    .m2_bus_response            (ctrl_pix_reader_response      ),
    .m2_bus_write               (ctrl_pix_reader_write         ),
    .m2_bus_writedata           (ctrl_pix_reader_writedata     ),
    .m2_bus_byteenable          (ctrl_pix_reader_byteenable    ),
    .m2_bus_waitrequest         (ctrl_pix_reader_waitrequest   ),

    //* Master port 3
    .m3_bus_addr                (ctrl_dsi_address        ),
    .m3_bus_read                (ctrl_dsi_read           ),
    .m3_bus_readdata            (ctrl_dsi_readdata       ),
    .m3_bus_response            (ctrl_dsi_response       ),
    .m3_bus_write               (ctrl_dsi_write          ),
    .m3_bus_writedata           (ctrl_dsi_writedata      ),
    .m3_bus_byteenable          (ctrl_dsi_byteenable     ),
    .m3_bus_waitrequest         (ctrl_dsi_waitrequest    ),

    //* Master port 4
    .m4_bus_addr                (ctrl_prog_mem_address          ),
    .m4_bus_read                (ctrl_prog_mem_read             ),
    .m4_bus_readdata            (ctrl_prog_mem_readdata         ),
    .m4_bus_response            (ctrl_prog_mem_response         ),
    .m4_bus_write               (ctrl_prog_mem_write            ),
    .m4_bus_writedata           (ctrl_prog_mem_writedata        ),
    .m4_bus_byteenable          (ctrl_prog_mem_byteenable       ),
    .m4_bus_waitrequest         (ctrl_prog_mem_waitrequest      ),

    //* Master port 5
    .m5_bus_addr                (ctrl_uart_address          ),
    .m5_bus_read                (ctrl_uart_read             ),
    .m5_bus_readdata            (ctrl_uart_readdata         ),
    .m5_bus_response            (ctrl_uart_response         ),
    .m5_bus_write               (ctrl_uart_write            ),
    .m5_bus_writedata           (ctrl_uart_writedata        ),
    .m5_bus_byteenable          (ctrl_uart_byteenable       ),
    .m5_bus_waitrequest         (ctrl_uart_waitrequest      ),

    //* Master port 6
    .m6_bus_addr                (ctrl_i2c_address           ),
    .m6_bus_read                (ctrl_i2c_read              ),
    .m6_bus_readdata            (ctrl_i2c_readdata          ),
    .m6_bus_response            (ctrl_i2c_response          ),
    .m6_bus_write               (ctrl_i2c_write             ),
    .m6_bus_writedata           (ctrl_i2c_writedata         ),
    .m6_bus_byteenable          (ctrl_i2c_byteenable        ),
    .m6_bus_waitrequest         (ctrl_i2c_waitrequest       ),

    //* Master port 7
    .m7_bus_addr                (ctrl_gpio_address      ),
    .m7_bus_read                (ctrl_gpio_read         ),
    .m7_bus_readdata            (ctrl_gpio_readdata     ),
    .m7_bus_response            (ctrl_gpio_response     ),
    .m7_bus_write               (ctrl_gpio_write        ),
    .m7_bus_writedata           (ctrl_gpio_writedata    ),
    .m7_bus_byteenable          (ctrl_gpio_byteenable   ),
    .m7_bus_waitrequest         (ctrl_gpio_waitrequest  ),

    //* Master port 8
    .m8_bus_addr                (ctrl_sys_timer_address     ),
    .m8_bus_read                (ctrl_sys_timer_read        ),
    .m8_bus_readdata            (ctrl_sys_timer_readdata    ),
    .m8_bus_response            (ctrl_sys_timer_response    ),
    .m8_bus_write               (ctrl_sys_timer_write       ),
    .m8_bus_writedata           (ctrl_sys_timer_writedata   ),
    .m8_bus_byteenable          (ctrl_sys_timer_byteenable  ),
    .m8_bus_waitrequest         (ctrl_sys_timer_waitrequest ),

    //* Master port 9
    .m9_bus_addr                (ctrl_pg_address        ),
    .m9_bus_read                (ctrl_pg_read           ),
    .m9_bus_readdata            (ctrl_pg_readdata       ),
    .m9_bus_response            (ctrl_pg_response       ),
    .m9_bus_write               (ctrl_pg_write          ),
    .m9_bus_writedata           (ctrl_pg_writedata      ),
    .m9_bus_byteenable          (ctrl_pg_byteenable     ),
    .m9_bus_waitrequest         (ctrl_pg_waitrequest    )
);

//* GPIO

reg [31:0] gpio_reg;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)              gpio_reg <= 'b0;
    else if(ctrl_gpio_write)    gpio_reg <= ctrl_gpio_writedata;
end

assign ctrl_gpio_waitrequest = 0;
assign ctrl_gpio_readdata = 0;
assign ctrl_gpio_response = 0;

assign led_out = gpio_reg[0];

reg [24:0] counter;
reg led_state;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)   begin
        counter <= 'b0;
        led_state <= 'b0;
    end
    else begin
        if(counter == 9280000) begin
            counter <= 0;
            led_state <= ~led_state;
        end
        else
            counter <= counter + 1;

    end
end

// assign led_out = led_state;
// assign led_out = sys_pll_locked;
// assign led_out = c3_calib_done;

//* Prosessor to AXI bridge
core_axi_bridge core_axi_bridge_0(

    .clk                     (sys_clk               ),
    .rst_n                   (sys_rst_n             ),

    .slv_bus_addr            ({{(32-M0_ADDR_WIDTH){1'b0}}, ram_mem_address}       ),
    .slv_bus_read            (ram_mem_read          ),
    .slv_bus_readdata        (ram_mem_readdata      ),
    .slv_bus_response        (ram_mem_response      ),
    .slv_bus_write           (ram_mem_write         ),
    .slv_bus_writedata       (ram_mem_writedata     ),
    .slv_bus_byteenable      (ram_mem_byteenable    ),
    .slv_bus_waitrequest     (ram_mem_waitrequest   ),

    .mst_axi_awid            (mst_core_axi_awid      ),
    .mst_axi_awaddr          (mst_core_axi_awaddr    ),
    .mst_axi_awlen           (mst_core_axi_awlen     ),
    .mst_axi_awsize          (mst_core_axi_awsize    ),
    .mst_axi_awburst         (mst_core_axi_awburst   ),
    .mst_axi_awlock          (mst_core_axi_awlock    ),
    .mst_axi_awcache         (mst_core_axi_awcache   ),
    .mst_axi_awprot          (mst_core_axi_awprot    ),
    .mst_axi_awqos           (mst_core_axi_awqos     ),
    .mst_axi_awvalid         (mst_core_axi_awvalid   ),
    .mst_axi_awready         (mst_core_axi_awready   ),

    .mst_axi_wdata           (mst_core_axi_wdata     ),
    .mst_axi_wstrb           (mst_core_axi_wstrb     ),
    .mst_axi_wlast           (mst_core_axi_wlast     ),
    .mst_axi_wvalid          (mst_core_axi_wvalid    ),
    .mst_axi_wready          (mst_core_axi_wready    ),

    .mst_axi_bid             (mst_core_axi_bid       ),
    .mst_axi_wid             (mst_core_axi_wid       ),
    .mst_axi_bresp           (mst_core_axi_bresp     ),
    .mst_axi_bvalid          (mst_core_axi_bvalid    ),
    .mst_axi_bready          (mst_core_axi_bready    ),

    .mst_axi_arid            (mst_core_axi_arid      ),
    .mst_axi_araddr          (mst_core_axi_araddr    ),
    .mst_axi_arlen           (mst_core_axi_arlen     ),
    .mst_axi_arsize          (mst_core_axi_arsize    ),
    .mst_axi_arburst         (mst_core_axi_arburst   ),
    .mst_axi_arlock          (mst_core_axi_arlock    ),
    .mst_axi_arcache         (mst_core_axi_arcache   ),
    .mst_axi_arprot          (mst_core_axi_arprot    ),
    .mst_axi_arqos           (mst_core_axi_arqos     ),
    .mst_axi_arvalid         (mst_core_axi_arvalid   ),
    .mst_axi_arready         (mst_core_axi_arready   ),

    .mst_axi_rid             (mst_core_axi_rid       ),
    .mst_axi_rdata           (mst_core_axi_rdata     ),
    .mst_axi_rresp           (mst_core_axi_rresp     ),
    .mst_axi_rlast           (mst_core_axi_rlast     ),
    .mst_axi_rvalid          (mst_core_axi_rvalid    ),
    .mst_axi_rready          (mst_core_axi_rready    )
);

`ifdef SIMULATION

`ifndef SPARTAN7

 ram_mem ram_mem_0(
  .s_aclk               (sys_clk                ),
  .s_aresetn            (sys_rst_n              ),
  .s_axi_awid           (mst_core_axi_awid      ),
  .s_axi_awaddr         (mst_core_axi_awaddr    ),
  .s_axi_awlen          (mst_core_axi_awlen     ),
  .s_axi_awsize         (mst_core_axi_awsize    ),
  .s_axi_awburst        (mst_core_axi_awburst   ),
  .s_axi_awvalid        (mst_core_axi_awvalid   ),
  .s_axi_awready        (mst_core_axi_awready   ),
  .s_axi_wdata          (mst_core_axi_wdata     ),
  .s_axi_wstrb          (mst_core_axi_wstrb     ),
  .s_axi_wlast          (mst_core_axi_wlast     ),
  .s_axi_wvalid         (mst_core_axi_wvalid    ),
  .s_axi_wready         (mst_core_axi_wready    ),
  .s_axi_bid            (mst_core_axi_bid       ),
  .s_axi_bresp          (mst_core_axi_bresp     ),
  .s_axi_bvalid         (mst_core_axi_bvalid    ),
  .s_axi_bready         (mst_core_axi_bready    ),
  .s_axi_arid           (mst_core_axi_arid      ),
  .s_axi_araddr         (mst_core_axi_araddr    ),
  .s_axi_arlen          (mst_core_axi_arlen     ),
  .s_axi_arsize         (mst_core_axi_arsize    ),
  .s_axi_arburst        (mst_core_axi_arburst   ),
  .s_axi_arvalid        (mst_core_axi_arvalid   ),
  .s_axi_arready        (mst_core_axi_arready   ),
  .s_axi_rid            (mst_core_axi_rid       ),
  .s_axi_rdata          (mst_core_axi_rdata     ),
  .s_axi_rresp          (mst_core_axi_rresp     ),
  .s_axi_rlast          (mst_core_axi_rlast     ),
  .s_axi_rvalid         (mst_core_axi_rvalid    ),
  .s_axi_rready         (mst_core_axi_rready    )
);

assign mst_core_axi_wid = 'b0;
`else

 axi4_slave_vip  slave_ram(
            .aclk               (sys_clk                ),
            .aresetn            (sys_rst_n              ),
            .s_axi_awaddr       (mst_core_axi_awaddr    ),
            .s_axi_awlen        (mst_core_axi_awlen     ),
            .s_axi_awsize       (mst_core_axi_awsize    ),
            .s_axi_awburst      (mst_core_axi_awburst   ),
            .s_axi_awlock       (mst_core_axi_awlock    ),
            .s_axi_awcache      (mst_core_axi_awcache   ),
            .s_axi_awprot       (mst_core_axi_awprot    ),
            .s_axi_awregion     (0),
            .s_axi_awqos        (mst_core_axi_awqos     ),
            .s_axi_awvalid      (mst_core_axi_awvalid   ),
            .s_axi_awready      (mst_core_axi_awready   ),
            .s_axi_wdata        (mst_core_axi_wdata     ),
            .s_axi_wstrb        (mst_core_axi_wstrb     ),
            .s_axi_wlast        (mst_core_axi_wlast     ),
            .s_axi_wvalid       (mst_core_axi_wvalid    ),
            .s_axi_wready       (mst_core_axi_wready    ),
            .s_axi_bresp        (mst_core_axi_bresp     ),
            .s_axi_bvalid       (mst_core_axi_bvalid    ),
            .s_axi_bready       (mst_core_axi_bready    ),
            .s_axi_araddr       (mst_core_axi_araddr    ),
            .s_axi_arlen        (mst_core_axi_arlen     ),
            .s_axi_arsize       (mst_core_axi_arsize    ),
            .s_axi_arburst      (mst_core_axi_arburst   ),
            .s_axi_arlock       (mst_core_axi_arlock    ),
            .s_axi_arcache      (mst_core_axi_arcache   ),
            .s_axi_arprot       (mst_core_axi_arprot    ),
            .s_axi_arregion     (0),
            .s_axi_arqos        (mst_core_axi_arqos     ),
            .s_axi_arvalid      (mst_core_axi_arvalid   ),
            .s_axi_arready      (mst_core_axi_arready   ),
            .s_axi_rdata        (mst_core_axi_rdata     ),
            .s_axi_rresp        (mst_core_axi_rresp     ),
            .s_axi_rlast        (mst_core_axi_rlast     ),
            .s_axi_rvalid       (mst_core_axi_rvalid    ),
            .s_axi_rready       (mst_core_axi_rready    )
            );

axi4_slave_vip  slave_wo(
            .aclk               (sys_clk                ),
            .aresetn            (sys_rst_n              ),
            .s_axi_awaddr       (hdmi_axi_awaddr        ),
            .s_axi_awlen        (hdmi_axi_awlen         ),
            .s_axi_awsize       (hdmi_axi_awsize        ),
            .s_axi_awburst      (hdmi_axi_awburst       ),
            .s_axi_awlock       (hdmi_axi_awlock        ),
            .s_axi_awcache      (hdmi_axi_awcache       ),
            .s_axi_awprot       (hdmi_axi_awprot        ),
            .s_axi_awregion     (0),
            .s_axi_awqos        (hdmi_axi_awqos         ),
            .s_axi_awvalid      (hdmi_axi_awvalid       ),
            .s_axi_awready      (hdmi_axi_awready       ),
            .s_axi_wdata        (hdmi_axi_wdata         ),
            .s_axi_wstrb        (hdmi_axi_wstrb         ),
            .s_axi_wlast        (hdmi_axi_wlast         ),
            .s_axi_wvalid       (hdmi_axi_wvalid        ),
            .s_axi_wready       (hdmi_axi_wready        ),
            .s_axi_bresp        (hdmi_axi_bresp         ),
            .s_axi_bvalid       (hdmi_axi_bvalid        ),
            .s_axi_bready       (hdmi_axi_bready        ),
            .s_axi_araddr       (0  ),
            .s_axi_arlen        (0  ),
            .s_axi_arsize       (0  ),
            .s_axi_arburst      (0  ),
            .s_axi_arlock       (0  ),
            .s_axi_arcache      (0  ),
            .s_axi_arprot       (0  ),
            .s_axi_arregion     (0),
            .s_axi_arqos        (0   ),
            .s_axi_arvalid      (0   ),
            .s_axi_arready      (   ),
            .s_axi_rdata        (     ),
            .s_axi_rresp        (     ),
            .s_axi_rlast        (     ),
            .s_axi_rvalid       (    ),
            .s_axi_rready       (1    )
            );

axi4_slave_vip  slave_ro(
            .aclk               (sys_clk                ),
            .aresetn            (sys_rst_n              ),
            .s_axi_awaddr       (0   ),
            .s_axi_awlen        (0   ),
            .s_axi_awsize       (0   ),
            .s_axi_awburst      (0   ),
            .s_axi_awlock       (0   ),
            .s_axi_awcache      (0   ),
            .s_axi_awprot       (0   ),
            .s_axi_awregion     (0),
            .s_axi_awqos        (0     ),
            .s_axi_awvalid      (0   ),
            .s_axi_awready      (   ),
            .s_axi_wdata        (0    ),
            .s_axi_wstrb        (0    ),
            .s_axi_wlast        (0    ),
            .s_axi_wvalid       (0    ),
            .s_axi_wready       (    ),
            .s_axi_bresp        (    ),
            .s_axi_bvalid       (    ),
            .s_axi_bready       (1    ),
            .s_axi_araddr       ({8'b0,pix_axi_araddr}  ),
            .s_axi_arlen        (pix_axi_arlen          ),
            .s_axi_arsize       (pix_axi_arsize         ),
            .s_axi_arburst      (pix_axi_arburst        ),
            .s_axi_arlock       (pix_axi_arlock         ),
            .s_axi_arcache      (pix_axi_arcache        ),
            .s_axi_arprot       (pix_axi_arprot         ),
            .s_axi_arregion     (0),
            .s_axi_arqos        (pix_axi_arqos          ),
            .s_axi_arvalid      (pix_axi_arvalid        ),
            .s_axi_arready      (pix_axi_arready        ),
            .s_axi_rdata        (pix_axi_rdata          ),
            .s_axi_rresp        (pix_axi_rresp          ),
            .s_axi_rlast        (pix_axi_rlast          ),
            .s_axi_rvalid       (pix_axi_rvalid         ),
            .s_axi_rready       (pix_axi_rready         )
            );

`endif

`else


//  ram_mem_2 ram_mem_2_inst(
//   .s_aclk           (sys_clk                ),
//   .s_aresetn        (sys_rst_n              ),
//   .s_axi_awid       (mst_core_axi_awid      ),
//   .s_axi_awaddr     (mst_core_axi_awaddr    ),
//   .s_axi_awlen      (mst_core_axi_awlen     ),
//   .s_axi_awsize     (mst_core_axi_awsize    ),
//   .s_axi_awburst    (mst_core_axi_awburst   ),
//   .s_axi_awvalid    (mst_core_axi_awvalid   ),
//   .s_axi_awready    (mst_core_axi_awready   ),
//   .s_axi_wdata      (mst_core_axi_wdata     ),
//   .s_axi_wstrb      (mst_core_axi_wstrb     ),
//   .s_axi_wlast      (mst_core_axi_wlast     ),
//   .s_axi_wvalid     (mst_core_axi_wvalid    ),
//   .s_axi_wready     (mst_core_axi_wready    ),
//   .s_axi_bid        (mst_core_axi_bid       ),
//   .s_axi_bresp      (mst_core_axi_bresp     ),
//   .s_axi_bvalid     (mst_core_axi_bvalid    ),
//   .s_axi_bready     (mst_core_axi_bready    ),
//   .s_axi_arid       (mst_core_axi_arid      ),
//   .s_axi_araddr     (mst_core_axi_araddr    ),
//   .s_axi_arlen      (mst_core_axi_arlen     ),
//   .s_axi_arsize     (mst_core_axi_arsize    ),
//   .s_axi_arburst    (mst_core_axi_arburst   ),
//   .s_axi_arvalid    (mst_core_axi_arvalid   ),
//   .s_axi_arready    (mst_core_axi_arready   ),
//   .s_axi_rid        (mst_core_axi_rid       ),
//   .s_axi_rdata      (mst_core_axi_rdata     ),
//   .s_axi_rresp      (mst_core_axi_rresp     ),
//   .s_axi_rlast      (mst_core_axi_rlast     ),
//   .s_axi_rvalid     (mst_core_axi_rvalid    ),
//   .s_axi_rready     (mst_core_axi_rready    )
// );

//* DDR3 controller
mig_ddr3 # (
    .C3_P0_MASK_SIZE(4),
    .C3_P0_DATA_PORT_SIZE(32),
    .C3_P1_MASK_SIZE(4),
    .C3_P1_DATA_PORT_SIZE(32),
    .DEBUG_EN(0),
    .C3_MEMCLK_PERIOD(3000),
    .C3_CALIB_SOFT_IP("TRUE"),
    .C3_SIMULATION("FALSE"),
    .C3_RST_ACT_LOW(0),
    .C3_INPUT_CLK_TYPE("SINGLE_ENDED"),
    .C3_MEM_ADDR_ORDER("BANK_ROW_COLUMN"),
    .C3_NUM_DQ_PINS(16),
    .C3_MEM_ADDR_WIDTH(14),
    .C3_MEM_BANKADDR_WIDTH(3),
    .C3_S0_AXI_STRICT_COHERENCY(0),
    .C3_S0_AXI_ENABLE_AP(0),
    .C3_S0_AXI_DATA_WIDTH(32),
    .C3_S0_AXI_SUPPORTS_NARROW_BURST(1),
    .C3_S0_AXI_ADDR_WIDTH(32),
    .C3_S0_AXI_ID_WIDTH(4),
    .C3_S2_AXI_STRICT_COHERENCY(0),
    .C3_S2_AXI_ENABLE_AP(0),
    .C3_S2_AXI_DATA_WIDTH(32),
    .C3_S2_AXI_SUPPORTS_NARROW_BURST(1),
    .C3_S2_AXI_ADDR_WIDTH(32),
    .C3_S2_AXI_ID_WIDTH(4),
    .C3_S3_AXI_STRICT_COHERENCY(0),
    .C3_S3_AXI_ENABLE_AP(0),
    .C3_S3_AXI_DATA_WIDTH(32),
    .C3_S3_AXI_SUPPORTS_NARROW_BURST(1),
    .C3_S3_AXI_ADDR_WIDTH(32),
    .C3_S3_AXI_ID_WIDTH(4)
)
u_mig_ddr3 (

    .c3_sys_clk             (clk_in_ddr ),
    .c3_sys_rst_i           (~rst_n_in_sync),

    .mcb3_dram_dq           (mcb3_dram_dq),
    .mcb3_dram_a            (mcb3_dram_a),
    .mcb3_dram_ba           (mcb3_dram_ba),
    .mcb3_dram_ras_n        (mcb3_dram_ras_n),
    .mcb3_dram_cas_n        (mcb3_dram_cas_n),
    .mcb3_dram_we_n         (mcb3_dram_we_n),
    .mcb3_dram_odt          (mcb3_dram_odt),
    .mcb3_dram_cke          (mcb3_dram_cke),
    .mcb3_dram_ck           (mcb3_dram_ck),
    .mcb3_dram_ck_n         (mcb3_dram_ck_n),
    .mcb3_dram_dqs          (mcb3_dram_dqs),
    .mcb3_dram_dqs_n        (mcb3_dram_dqs_n),
    .mcb3_dram_udqs         (mcb3_dram_udqs),    // for X16 parts
    .mcb3_dram_udqs_n       (mcb3_dram_udqs_n),  // for X16 parts
    .mcb3_dram_udm          (mcb3_dram_udm),     // for X16 parts
    .mcb3_dram_dm           (mcb3_dram_dm),
    .mcb3_dram_reset_n      (mcb3_dram_reset_n),
    .c3_clk0		        (c3_clk0),
    .c3_rst0		        (c3_rst0),

    .c3_calib_done          (c3_calib_done),
    .mcb3_rzq               (mcb3_rzq   ),   //(rzq3),
    .mcb3_zio               (mcb3_zio   ),   //(zio3),

   .c3_s0_axi_aclk                         (sys_clk                ),
   .c3_s0_axi_aresetn                      (sys_rst_n              ),
   .c3_s0_axi_awid                         (mst_core_axi_awid      ),
   .c3_s0_axi_awaddr                       (mst_core_axi_awaddr    ),
   .c3_s0_axi_awlen                        (mst_core_axi_awlen     ),
   .c3_s0_axi_awsize                       (mst_core_axi_awsize    ),
   .c3_s0_axi_awburst                      (mst_core_axi_awburst   ),
   .c3_s0_axi_awlock                       (mst_core_axi_awlock    ),
   .c3_s0_axi_awcache                      (mst_core_axi_awcache   ),
   .c3_s0_axi_awprot                       (mst_core_axi_awprot    ),
   .c3_s0_axi_awqos                        (mst_core_axi_awqos     ),
   .c3_s0_axi_awvalid                      (mst_core_axi_awvalid   ),
   .c3_s0_axi_awready                      (mst_core_axi_awready   ),
   .c3_s0_axi_wdata                        (mst_core_axi_wdata     ),
   .c3_s0_axi_wstrb                        (mst_core_axi_wstrb     ),
   .c3_s0_axi_wlast                        (mst_core_axi_wlast     ),
   .c3_s0_axi_wvalid                       (mst_core_axi_wvalid    ),
   .c3_s0_axi_wready                       (mst_core_axi_wready    ),
   .c3_s0_axi_bid                          (mst_core_axi_bid       ),
   .c3_s0_axi_wid                          (mst_core_axi_wid       ),
   .c3_s0_axi_bresp                        (mst_core_axi_bresp     ),
   .c3_s0_axi_bvalid                       (mst_core_axi_bvalid    ),
   .c3_s0_axi_bready                       (mst_core_axi_bready    ),
   .c3_s0_axi_arid                         (mst_core_axi_arid      ),
   .c3_s0_axi_araddr                       (mst_core_axi_araddr    ),
   .c3_s0_axi_arlen                        (mst_core_axi_arlen     ),
   .c3_s0_axi_arsize                       (mst_core_axi_arsize    ),
   .c3_s0_axi_arburst                      (mst_core_axi_arburst   ),
   .c3_s0_axi_arlock                       (mst_core_axi_arlock    ),
   .c3_s0_axi_arcache                      (mst_core_axi_arcache   ),
   .c3_s0_axi_arprot                       (mst_core_axi_arprot    ),
   .c3_s0_axi_arqos                        (mst_core_axi_arqos     ),
   .c3_s0_axi_arvalid                      (mst_core_axi_arvalid   ),
   .c3_s0_axi_arready                      (mst_core_axi_arready   ),
   .c3_s0_axi_rid                          (mst_core_axi_rid       ),
   .c3_s0_axi_rdata                        (mst_core_axi_rdata     ),
   .c3_s0_axi_rresp                        (mst_core_axi_rresp     ),
   .c3_s0_axi_rlast                        (mst_core_axi_rlast     ),
   .c3_s0_axi_rvalid                       (mst_core_axi_rvalid    ),
   .c3_s0_axi_rready                       (mst_core_axi_rready    ),

    //* Write only Port
    .c3_s2_axi_aclk                         (sys_clk            ),
    .c3_s2_axi_aresetn                      (sys_rst_n          ),
    .c3_s2_axi_awid                         (4'b0               ),
    .c3_s2_axi_awaddr                       (hdmi_axi_awaddr    ),
    .c3_s2_axi_awlen                        (hdmi_axi_awlen     ),
    .c3_s2_axi_awsize                       (hdmi_axi_awsize    ),
    .c3_s2_axi_awburst                      (hdmi_axi_awburst   ),
    .c3_s2_axi_awlock                       (hdmi_axi_awlock    ),
    .c3_s2_axi_awcache                      (hdmi_axi_awcache   ),
    .c3_s2_axi_awprot                       (hdmi_axi_awprot    ),
    .c3_s2_axi_awqos                        (hdmi_axi_awqos     ),
    .c3_s2_axi_awvalid                      (hdmi_axi_awvalid   ),
    .c3_s2_axi_awready                      (hdmi_axi_awready   ),
    .c3_s2_axi_wdata                        (hdmi_axi_wdata     ),
    .c3_s2_axi_wstrb                        (hdmi_axi_wstrb     ),
    .c3_s2_axi_wlast                        (hdmi_axi_wlast     ),
    .c3_s2_axi_wvalid                       (hdmi_axi_wvalid    ),
    .c3_s2_axi_wready                       (hdmi_axi_wready    ),
    .c3_s2_axi_bid                          (),
    .c3_s2_axi_wid                          (),
    .c3_s2_axi_bresp                        (hdmi_axi_bresp     ),
    .c3_s2_axi_bvalid                       (hdmi_axi_bvalid    ),
    .c3_s2_axi_bready                       (hdmi_axi_bready    ),
    .c3_s2_axi_arid                         (4'b0),
    .c3_s2_axi_araddr                       (32'b0),
    .c3_s2_axi_arlen                        (8'b0),
    .c3_s2_axi_arsize                       (3'b0),
    .c3_s2_axi_arburst                      (2'b0),
    .c3_s2_axi_arlock                       (1'b0),
    .c3_s2_axi_arcache                      (4'b0),
    .c3_s2_axi_arprot                       (3'b0),
    .c3_s2_axi_arqos                        (4'b0),
    .c3_s2_axi_arvalid                      (1'b0),
    .c3_s2_axi_arready                      (),
    .c3_s2_axi_rid                          (),
    .c3_s2_axi_rdata                        (),
    .c3_s2_axi_rresp                        (),
    .c3_s2_axi_rlast                        (),
    .c3_s2_axi_rvalid                       (),
    .c3_s2_axi_rready                       (1'b1),

    //* Read only Port
    .c3_s3_axi_aclk                         (sys_clk              ),
    .c3_s3_axi_aresetn                      (sys_rst_n            ),
    .c3_s3_axi_awid                         (4'b0),
    .c3_s3_axi_awaddr                       (32'b0),
    .c3_s3_axi_awlen                        (8'b0),
    .c3_s3_axi_awsize                       (3'b0),
    .c3_s3_axi_awburst                      (2'b0),
    .c3_s3_axi_awlock                       (1'b0),
    .c3_s3_axi_awcache                      (4'b0),
    .c3_s3_axi_awprot                       (3'b0),
    .c3_s3_axi_awqos                        (4'b0),
    .c3_s3_axi_awvalid                      (1'b0),
    .c3_s3_axi_awready                      (),
    .c3_s3_axi_wdata                        (32'b0),
    .c3_s3_axi_wstrb                        (1'b0),
    .c3_s3_axi_wlast                        (1'b0),
    .c3_s3_axi_wvalid                       (1'b0),
    .c3_s3_axi_wready                       (),
    .c3_s3_axi_bid                          (),
    .c3_s3_axi_wid                          (),
    .c3_s3_axi_bresp                        (),
    .c3_s3_axi_bvalid                       (),
    .c3_s3_axi_bready                       (1'b1),
    .c3_s3_axi_arid                         (pix_axi_arid       ),
    .c3_s3_axi_araddr                       (pix_axi_araddr     ),
    .c3_s3_axi_arlen                        (pix_axi_arlen      ),
    .c3_s3_axi_arsize                       (pix_axi_arsize     ),
    .c3_s3_axi_arburst                      (pix_axi_arburst    ),
    .c3_s3_axi_arlock                       (pix_axi_arlock     ),
    .c3_s3_axi_arcache                      (pix_axi_arcache    ),
    .c3_s3_axi_arprot                       (pix_axi_arprot     ),
    .c3_s3_axi_arqos                        (pix_axi_arqos      ),
    .c3_s3_axi_arvalid                      (pix_axi_arvalid    ),
    .c3_s3_axi_arready                      (pix_axi_arready    ),
    .c3_s3_axi_rid                          (pix_axi_rid        ),
    .c3_s3_axi_rdata                        (pix_axi_rdata      ),
    .c3_s3_axi_rresp                        (pix_axi_rresp      ),
    .c3_s3_axi_rlast                        (pix_axi_rlast      ),
    .c3_s3_axi_rvalid                       (pix_axi_rvalid     ),
    .c3_s3_axi_rready                       (pix_axi_rready     )
);

`endif

//* HDMI ADV Recv

hdmi_recv hdmi_recv_0(
    .hdmi_rst_n              (hdmi_rst                  ),
    .hdmi_clk                (hdmi_clk_buf              ),

    .hdmi_data               (hdmi_data                 ),
    .hdmi_hs                 (hdmi_hs                   ),
    .hdmi_vs                 (hdmi_vs                   ),
    .hdmi_de                 (hdmi_de                   ),

    /********* AXI write channels *********/
    .clk_sys                 (sys_clk                   ),
    .rst_sys_n               (sys_rst_n                 ),

    .mst_axi_awid            (hdmi_axi_awid             ),
    .mst_axi_awaddr          (hdmi_axi_awaddr           ),
    .mst_axi_awlen           (hdmi_axi_awlen            ),
    .mst_axi_awsize          (hdmi_axi_awsize           ),
    .mst_axi_awburst         (hdmi_axi_awburst          ),
    .mst_axi_awlock          (hdmi_axi_awlock           ),
    .mst_axi_awcache         (hdmi_axi_awcache          ),
    .mst_axi_awprot          (hdmi_axi_awprot           ),
    .mst_axi_awqos           (hdmi_axi_awqos            ),
    .mst_axi_awvalid         (hdmi_axi_awvalid          ),
    .mst_axi_awready         (hdmi_axi_awready          ),

    .mst_axi_wdata           (hdmi_axi_wdata            ),
    .mst_axi_wstrb           (hdmi_axi_wstrb            ),
    .mst_axi_wlast           (hdmi_axi_wlast            ),
    .mst_axi_wvalid          (hdmi_axi_wvalid           ),
    .mst_axi_wready          (hdmi_axi_wready           ),

    .mst_axi_bid             (hdmi_axi_bid              ),
    .mst_axi_wid             (hdmi_axi_wid              ),
    .mst_axi_bresp           (hdmi_axi_bresp            ),
    .mst_axi_bvalid          (hdmi_axi_bvalid           ),
    .mst_axi_bready          (hdmi_axi_bready           ),

    /********* MM iface *********/
    .ctrl_address            (ctrl_hdmi_address         ),
    .ctrl_read               (ctrl_hdmi_read            ),
    .ctrl_readdata           (ctrl_hdmi_readdata        ),
    .ctrl_response           (ctrl_hdmi_response        ),
    .ctrl_write              (ctrl_hdmi_write           ),
    .ctrl_writedata          (ctrl_hdmi_writedata       ),
    .ctrl_byteenable         (ctrl_hdmi_byteenable      ),
    .ctrl_waitrequest        (ctrl_hdmi_waitrequest     )
);

//* Pixel reader
axi_to_stream_dma #(
    .ADDR_WIDTH(24),
    .BURST_SIZE(128),
    .MAX_OUTSTANDING_TR(16)
)axi_to_stream_dma_0(
    .clk                            (sys_clk                ),
    .rst_n                          (sys_rst_n              ),

    /********* AXI read channels *********/
    .mst_axi_arid                   (pix_axi_arid           ),
    .mst_axi_araddr                 (pix_axi_araddr         ),
    .mst_axi_arlen                  (pix_axi_arlen          ),
    .mst_axi_arsize                 (pix_axi_arsize         ),
    .mst_axi_arburst                (pix_axi_arburst        ),
    .mst_axi_arlock                 (pix_axi_arlock         ),
    .mst_axi_arcache                (pix_axi_arcache        ),
    .mst_axi_arprot                 (pix_axi_arprot         ),
    .mst_axi_arqos                  (pix_axi_arqos          ),
    .mst_axi_arvalid                (pix_axi_arvalid        ),
    .mst_axi_arready                (pix_axi_arready        ),

    .mst_axi_rid                    (pix_axi_rid            ),
    .mst_axi_rdata                  (pix_axi_rdata          ),
    .mst_axi_rresp                  (pix_axi_rresp          ),
    .mst_axi_rlast                  (pix_axi_rlast          ),
    .mst_axi_rvalid                 (pix_axi_rvalid         ),
    .mst_axi_rready                 (pix_axi_rready         ),

    /*********  Stream out *********/
    .st_data                        (st_data                ),
    .st_valid                       (st_valid               ),
    .st_endofpacket                 (st_endofpacket         ),
    .st_startofpacket               (st_startofpacket       ),
    .st_ready                       (st_ready               ),

    /********* MM iface *********/
    .ctrl_address                   (ctrl_pix_reader_address        ),
    .ctrl_read                      (ctrl_pix_reader_read           ),
    .ctrl_readdata                  (ctrl_pix_reader_readdata       ),
    .ctrl_response                  (ctrl_pix_reader_response       ),
    .ctrl_write                     (ctrl_pix_reader_write          ),
    .ctrl_writedata                 (ctrl_pix_reader_writedata      ),
    .ctrl_byteenable                (ctrl_pix_reader_byteenable     ),
    .ctrl_waitrequest               (ctrl_pix_reader_waitrequest    )
);
//* DSI +
dsi_tx_top #(
    .LINE_WIDTH            (640),
    .BITS_PER_PIXEL        (24),
    .BLANK_TIME            (640 + 200),
    .BLANK_TIME_HBP_ACT    (70),
    .VSA_LINES_NUMBER      (2),
    .VBP_LINES_NUMBER      (4),
    .IMAGE_HEIGHT          (480),
    .VFP_LINES_NUMBER      (4)
    ) dsi_tx_top_0 (
    /********* System signals *********/
    .clk_sys                                (sys_clk                    ),
    .rst_sys_n                              (sys_rst_n                  ),

    .clk_phy                                (dsi_phy_clk                ),
    .rst_phy_n                              (dsi_phy_rst_n              ),

    .clk_hs_latch                           (dsi_io_serdes_latch        ),
    .clk_hs                                 (dsi_io_clk                 ),
    .clk_hs_clk                             (dsi_io_clk_clk             ),
    .clk_hs_clk_latch                       (dsi_io_clk_serdes_latch    ),

    .irq                                    (dsi_irq                    ),

    /********* Avalon-ST input *********/
    .in_avl_st_data                         (st_gen_data            ),
    .in_avl_st_valid                        (st_gen_valid           ),
    .in_avl_st_endofpacket                  (st_gen_endofpacket     ),
    .in_avl_st_startofpacket                (st_gen_startofpacket   ),
    .in_avl_st_ready                        (st_gen_ready           ),

    /********* Output interface *********/
    .dphy_data_hs_out_p                     (dphy_data_hs_out_p     ),  // active
    .dphy_data_hs_out_n                     (dphy_data_hs_out_n     ),  // unactive. do not connect
    .dphy_data_lp_out_p                     (dphy_data_lp_out_p     ),
    .dphy_data_lp_out_n                     (dphy_data_lp_out_n     ),

    .dphy_clk_hs_out_p                      (dphy_clk_hs_out_p      ),  // active
    .dphy_clk_hs_out_n                      (dphy_clk_hs_out_n      ),  // unactive. do not connect
    .dphy_clk_lp_out_p                      (dphy_clk_lp_out_p      ),
    .dphy_clk_lp_out_n                      (dphy_clk_lp_out_n      ),

    /********* Avalon-MM iface *********/
    .avl_mm_address                         (ctrl_dsi_address       ),
    .avl_mm_read                            (ctrl_dsi_read          ),
    .avl_mm_readdata                        (ctrl_dsi_readdata      ),
    .avl_mm_response                        (ctrl_dsi_response      ),
    .avl_mm_write                           (ctrl_dsi_write         ),
    .avl_mm_writedata                       (ctrl_dsi_writedata     ),
    .avl_mm_byteenable                      (ctrl_dsi_byteenable    ),
    .avl_mm_waitrequest                     (ctrl_dsi_waitrequest   )

);

//* I2C master ADV
i2c_master_wrapper i2c_master_wrapper_0(
    .clk                 (sys_clk              ),
    .rst_n               (sys_rst_n            ),

    .scl_io              (i2c_scl               ),
    .sda_io              (i2c_sda               ),

    .ctrl_address        (ctrl_i2c_address      ),
    .ctrl_read           (ctrl_i2c_read         ),
    .ctrl_readdata       (ctrl_i2c_readdata     ),
    .ctrl_response       (ctrl_i2c_response     ),
    .ctrl_write          (ctrl_i2c_write        ),
    .ctrl_writedata      (ctrl_i2c_writedata    ),
    .ctrl_byteenable     (ctrl_i2c_byteenable   ),
    .ctrl_waitrequest    (ctrl_i2c_waitrequest  )
    // .irq
);

//* HDMI Parallel receiver
//* Stream to AXI DMA

//* Usart RX/TX
uart_wrapper uart_wrapper_0(
    //* system signals
    .clk                    (sys_clk                ),
    .rst_n                  (sys_rst_n              ),

    //* external interface
    .rxd                    (usart_rxd             ),
    .txd                    (usart_txd             ),

    //* system interface
    .ctrl_address           (ctrl_uart_address      ),
    .ctrl_read              (ctrl_uart_read         ),
    .ctrl_readdata          (ctrl_uart_readdata     ),
    .ctrl_response          (ctrl_uart_response     ),
    .ctrl_write             (ctrl_uart_write        ),
    .ctrl_writedata         (ctrl_uart_writedata    ),
    .ctrl_byteenable        (ctrl_uart_byteenable   ),
    .ctrl_waitrequest       (ctrl_uart_waitrequest  ),

    .irq                    (usart_irq              )
);

//* Programm Mem
progmem_wrapper progmem_wrapper_0(
    //* system signals
    .clk                     (sys_clk              ),
    .rst_n                   (sys_rst_n            ),

    //* system interface
    .ctrl_address            (ctrl_prog_mem_address),
    .ctrl_read               (ctrl_prog_mem_read          ),
    .ctrl_readdata           (ctrl_prog_mem_readdata      ),
    .ctrl_response           (ctrl_prog_mem_response      ),
    .ctrl_write              (ctrl_prog_mem_write         ),
    .ctrl_writedata          (ctrl_prog_mem_writedata     ),
    .ctrl_byteenable         (ctrl_prog_mem_byteenable     ),
    .ctrl_waitrequest        (ctrl_prog_mem_waitrequest   )
);

//* SYS TIMER
 sys_timer sys_timer_0 (
    .clk                         (sys_clk              ),
    .rst_n                       (sys_rst_n            ),

    /********* MM iface *********/
    .ctrl_address                (ctrl_sys_timer_address       ),
    .ctrl_read                   (ctrl_sys_timer_read          ),
    .ctrl_readdata               (ctrl_sys_timer_readdata      ),
    .ctrl_response               (ctrl_sys_timer_response      ),
    .ctrl_write                  (ctrl_sys_timer_write         ),
    .ctrl_writedata              (ctrl_sys_timer_writedata     ),
    .ctrl_byteenable             (ctrl_sys_timer_byteenable    ),
    .ctrl_waitrequest            (ctrl_sys_timer_waitrequest   )
);

//* PAttern GENERATOR
pattern_generator  #(
    .IMG_HEIGH(24),
    .IMG_WIDTH(24)
)pattern_generator_0(
    .clk                        (sys_clk                ),
    .rst_n                      (sys_rst_n              ),

    .st_in_data                 (st_data                ),
    .st_in_valid                (st_valid               ),
    .st_in_endofpacket          (st_endofpacket         ),
    .st_in_startofpacket        (st_startofpacket       ),
    .st_in_ready                (st_ready               ),

    .st_out_data                (st_gen_data           ),
    .st_out_valid               (st_gen_valid          ),
    .st_out_endofpacket         (st_gen_endofpacket    ),
    .st_out_startofpacket       (st_gen_startofpacket  ),
    .st_out_ready               (st_gen_ready          ),

    .ctrl_address               (ctrl_pg_address       ),
    .ctrl_read                  (ctrl_pg_read          ),
    .ctrl_readdata              (ctrl_pg_readdata      ),
    .ctrl_response              (ctrl_pg_response      ),
    .ctrl_write                 (ctrl_pg_write         ),
    .ctrl_writedata             (ctrl_pg_writedata     ),
    .ctrl_byteenable            (ctrl_pg_byteenable    ),
    .ctrl_waitrequest           (ctrl_pg_waitrequest   )
);

//* Clocking
//* Main PLL (sys clock + dphy)
// 32 * 29 = 928
wire CLKFBOUT;
wire CLKFBIN;
wire CLKOUT0; //* 464 MHz   928/2
wire CLKOUT1; //* 464 with shift
wire CLKOUT2; //*  52MHz = CLKOUT0 / 8
wire CLKOUT3; //* 92.8 MHZ
wire CLKOUT4; //* 32 MHz
wire CLKOUT5; //* 333 MHz for DDR

`ifdef SPARTAN7
clk_wiz_0 main_pll(
    .clk_out1   (sys_clk),
    .clk_out2   (dsi_io_clk),
    .clk_out3   (dsi_io_clk_clk),
    .clk_out4   (dsi_phy_clk),
    .clk_out5   (clk_in_sync),
    .reset      (!rst_n_in),
    .locked     (sys_pll_locked     ),
    .clk_in1    (clk_in             )
    );

assign clk_pre_pll = clk_in;
`else
// assign clk_pre_pll = clk_in;
IBUFG #(
      .IOSTANDARD("DEFAULT")
   ) IBUFG_inst (
      .O(clk_pre_pll), // Clock buffer output
      .I(clk_in)  // Clock buffer input (connect directly to top-level port)
   );

PLL_BASE #(
    .BANDWIDTH("OPTIMIZED"),             // "HIGH", "LOW" or "OPTIMIZED"
    .CLKFBOUT_MULT(29),                   // Multiply value for all CLKOUT clock outputs (1-64)
    .CLKFBOUT_PHASE(0.0),                // Phase offset in degrees of the clock feedback output (0.0-360.0).
    .CLKIN_PERIOD(31.25),                  // Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                         // MHz).
    // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
    .CLKOUT0_DIVIDE(2),
    .CLKOUT1_DIVIDE(2),
    .CLKOUT2_DIVIDE(16),
    .CLKOUT3_DIVIDE(10),
    .CLKOUT4_DIVIDE(29),
    .CLKOUT5_DIVIDE(3),
    // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT5_DUTY_CYCLE(0.5),
    // CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
    .CLKOUT0_PHASE(0.0),
    .CLKOUT1_PHASE(180.0),
    .CLKOUT2_PHASE(0.0),
    .CLKOUT3_PHASE(0.0),
    .CLKOUT4_PHASE(0.0),
    .CLKOUT5_PHASE(0.0),
    .CLK_FEEDBACK("CLKFBOUT"),           // Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
    .COMPENSATION("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL"
    .DIVCLK_DIVIDE(1),                   // Division value for all output clocks (1-52)
    .REF_JITTER(0.1),                    // Reference Clock Jitter in UI (0.000-0.999).
    .RESET_ON_LOSS_OF_LOCK("FALSE")      // Must be set to FALSE
) PLL_main (
     .CLKFBOUT(CLKFBOUT), // 1-bit output: PLL_BASE feedback output
     // CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
     .CLKOUT0(CLKOUT0),
     .CLKOUT1(CLKOUT1),
     .CLKOUT2(CLKOUT2),
     .CLKOUT3(CLKOUT3),
     .CLKOUT4(CLKOUT4),
     .CLKOUT5(CLKOUT5),
     .LOCKED(sys_pll_locked),     // 1-bit output: PLL_BASE lock status output
     .CLKFBIN(CLKFBIN),   // 1-bit input: Feedback clock input
     .CLKIN(clk_pre_pll),       // 1-bit input: Clock input
     .RST(0)            // 1-bit input: Reset input
);

BUFG BUFG_feedback (
      .O(CLKFBIN), // Clock buffer output
      .I(CLKFBOUT)  // Clock buffer input (connect directly to top-level port)
   );

BUFGCE BUFG_sys_clock (
      .O(sys_clk), // Clock buffer output
      .I(CLKOUT3),  // Clock buffer input (connect directly to top-level port)
      .CE(sys_pll_locked)
   );

BUFGCE BUFG_dsi_main_clock (
      .O(dsi_phy_clk), // Clock buffer output
      .I(CLKOUT2),  // Clock buffer input (connect directly to top-level port)
      .CE(sys_pll_locked)
   );

BUFGCE BUFG_input_ddr_clock (
      .O(clk_in_ddr), // Clock buffer output
      .I(CLKOUT5),  // Clock buffer input (connect directly to top-level port)
      .CE(sys_pll_locked)
   );

BUFGCE BUFG_input_clock (
      .O(clk_in_sync), // Clock buffer output
      .I(CLKOUT4),  // Clock buffer input (connect directly to top-level port)
      .CE(sys_pll_locked)
   );

BUFPLL #(
      .DIVIDE(8),           // DIVCLK divider (1-8)
      .ENABLE_SYNC("TRUE")  // Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   BUFPLL_dphy_clk (
      .IOCLK(dsi_io_clk),               // 1-bit output: Output I/O clock
      .LOCK(),                 // 1-bit output: Synchronized LOCK output
      .SERDESSTROBE(dsi_io_serdes_latch), // 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      .GCLK(dsi_phy_clk),                 // 1-bit input: BUFG clock input
      .LOCKED(sys_pll_locked),             // 1-bit input: LOCKED input from PLL
      .PLLIN(CLKOUT0)                // 1-bit input: Clock input from PLL
   );

BUFPLL #(
      .DIVIDE(8),           // DIVCLK divider (1-8)
      .ENABLE_SYNC("TRUE")  // Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   BUFPLL_dphy_clk_clk (
      .IOCLK(dsi_io_clk_clk),               // 1-bit output: Output I/O clock
      .LOCK(),                 // 1-bit output: Synchronized LOCK output
      .SERDESSTROBE(dsi_io_clk_serdes_latch), // 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      .GCLK(dsi_phy_clk),                 // 1-bit input: BUFG clock input
      .LOCKED(sys_pll_locked),             // 1-bit input: LOCKED input from PLL
      .PLLIN(CLKOUT1)                // 1-bit input: Clock input from PLL
   );

`endif

endmodule

`default_nettype wire
