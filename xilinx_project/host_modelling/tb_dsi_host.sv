`timescale 1ns/1ps

import axi_vip_pkg::*;
import axi4_slave_vip_pkg::*;

module tb_dsi_host;

wire                 clk_in                  ;
wire                 rst_n_in                ;
    /* DDR */
wire [16-1:0]        mcb3_dram_dq            ;
wire [14-1:0]        mcb3_dram_a             ;
wire [3-1:0]         mcb3_dram_ba            ;
wire                 mcb3_dram_ras_n         ;
wire                 mcb3_dram_cas_n         ;
wire                 mcb3_dram_we_n          ;
wire                 mcb3_dram_odt           ;
wire                 mcb3_dram_reset_n       ;
wire                 mcb3_dram_cke           ;
wire                 mcb3_dram_dm            ;
wire                 mcb3_dram_udqs          ;
wire                 mcb3_dram_udqs_n        ;
wire                 mcb3_rzq                ;
wire                 mcb3_zio                ;
wire                 mcb3_dram_udm           ;

wire                 mcb3_dram_dqs           ;
wire                 mcb3_dram_dqs_n         ;
wire                 mcb3_dram_ck            ;
wire                 mcb3_dram_ck_n          ;
    /* DPHY */
wire [3:0]      dphy_data_hs_out_p      ;
wire [3:0]      dphy_data_hs_out_n      ;
wire [3:0]      dphy_data_lp_out_p      ;
wire [3:0]      dphy_data_lp_out_n      ;
wire            dphy_clk_hs_out_p       ;
wire            dphy_clk_hs_out_n       ;
wire            dphy_clk_lp_out_p       ;
wire            dphy_clk_lp_out_n       ;
    /* HDMI parallel */
wire [24-1:0]   hdmi_data               ;
wire            hdmi_hs                 ;
wire            hdmi_vs                 ;
wire            hdmi_de                 ;
wire            hdmi_clk                ;

    /* I2C ADV */
    /* I2C EEPROM */
    /* LED */
    /* UART */
wire             rxd                     ;
wire             txd                     ;

reg r_clk_25;
reg r_rst_n;

assign clk_in       = r_clk_25;
assign rst_n_in     = r_rst_n;

initial
begin
r_clk_25 = 0;
#500
forever
begin
    #20 r_clk_25 = ~r_clk_25;
end
end


initial
begin
r_rst_n = 0;

repeat(1000) @(posedge r_clk_25);

r_rst_n = 1;


end

dsi_host_top dsi_host_top_0(
    /* CLK */
    .clk_in                  (clk_in                ),
    .rst_n_in                (rst_n_in              ),

    .mcb3_dram_dq            (mcb3_dram_dq          ),
    .mcb3_dram_a             (mcb3_dram_a           ),
    .mcb3_dram_ba            (mcb3_dram_ba          ),
    .mcb3_dram_ras_n         (mcb3_dram_ras_n       ),
    .mcb3_dram_cas_n         (mcb3_dram_cas_n       ),
    .mcb3_dram_we_n          (mcb3_dram_we_n        ),
    .mcb3_dram_odt           (mcb3_dram_odt         ),
    .mcb3_dram_reset_n       (mcb3_dram_reset_n     ),
    .mcb3_dram_cke           (mcb3_dram_cke         ),
    .mcb3_dram_dm            (mcb3_dram_dm          ),
    .mcb3_dram_udqs          (mcb3_dram_udqs        ),
    .mcb3_dram_udqs_n        (mcb3_dram_udqs_n      ),
    .mcb3_rzq                (mcb3_rzq              ),
    .mcb3_zio                (mcb3_zio              ),
    .mcb3_dram_udm           (mcb3_dram_udm         ),
    .mcb3_dram_dqs           (mcb3_dram_dqs         ),
    .mcb3_dram_dqs_n         (mcb3_dram_dqs_n       ),
    .mcb3_dram_ck            (mcb3_dram_ck          ),
    .mcb3_dram_ck_n          (mcb3_dram_ck_n        ),
    .rzq3                     (1'b0                 ),
    .zio3                     (1'b0                 ),
    /* DPHY */
    .dphy_data_hs_out_p      (dphy_data_hs_out_p    ),
    .dphy_data_hs_out_n      (dphy_data_hs_out_n    ),
    .dphy_data_lp_out_p      (dphy_data_lp_out_p    ),
    .dphy_data_lp_out_n      (dphy_data_lp_out_n    ),
    .dphy_clk_hs_out_p       (dphy_clk_hs_out_p     ),
    .dphy_clk_hs_out_n       (dphy_clk_hs_out_n     ),
    .dphy_clk_lp_out_p       (dphy_clk_lp_out_p     ),
    .dphy_clk_lp_out_n       (dphy_clk_lp_out_n     ),
    /* HDMI parallel */
    .hdmi_data               (hdmi_data             ),
    .hdmi_hs                 (hdmi_hs               ),
    .hdmi_vs                 (hdmi_vs               ),
    .hdmi_de                 (hdmi_de               ),
    .hdmi_clk                (hdmi_clk              ),

    /* I2C ADV */
    /* I2C EEPROM */
    /* LED */
    /* UART */
    .rxd                     (rxd                   ),
    .txd                     (txd                   )
    /* BUTTON */
    );

integer debug_symbol;

always @(negedge dsi_host_top_0.picorv32_core.clk) begin
    if(dsi_host_top_0.picorv32_core.bus_write) begin
        if(dsi_host_top_0.picorv32_core.bus_addr == 32'h1000_0000) begin
            debug_symbol = dsi_host_top_0.picorv32_core.bus_writedata;
            $display("\nDATA ON DEBUG PORT = %h", debug_symbol);
        end
    end
end


reg req_ADDR    [31:0];
reg req_LEN     [7:0];
reg req_SIZE    [31:0];
reg req_BURST   [31:0];
reg req_LOCK    [31:0];
reg req_CACHE   [31:0];
reg req_PROT    [31:0];
reg req_REGION  [31:0];
reg req_QOS     [31:0];
reg req_ARUSER  [31:0];
reg req_IDTAG   [31:0];
integer res;

axi4_slave_vip_slv_t slave_agent;

localparam RAM_MEM_DEPTH = 2**(18-2);

logic [31:0] ram_memory [RAM_MEM_DEPTH-1:0];
integer ind;

initial
begin
    for(ind = 0; ind < RAM_MEM_DEPTH; ind++)
    begin
        ram_memory[ind] = 0;
    end
end

initial
begin

slave_agent = new("axi4_slave_vip", dsi_host_top_0.slave_ram.inst.IF);
slave_agent_pix_rd = new("axi4_slave_vip", dsi_host_top_0.slave_ro.inst.IF);
slave_agent_pix_wr = new("axi4_slave_vip", dsi_host_top_0.slave_wo.inst.IF);
slave_agent.start_slave();
slave_agent_pix_rd.start_slave();
slave_agent_pix_wr.start_slave();

fork
    wr_response();
    rd_response();
join_none

end

task wr_response();
    // Declare a handle for write response
    axi_transaction                    wr_reactive;
    integer trans_len;
    integer trans_addr;
    integer trans_data;

    forever begin
        // Block till write transaction occurs
        slave_agent.wr_driver.get_wr_reactive (wr_reactive);
        trans_len = wr_reactive.get_len();
        trans_addr = wr_reactive.get_addr();
        trans_data = wr_reactive.get_data_beat(0);
        $display("\n/********* AXI WRITE TRANSACTION ********/\n");
        $display("Len = %d\n", trans_len);
        $display("Addr = %h\n", trans_addr);
        $display("Data = %h\n", trans_data);
        $display("/****************************************/\n");

        ram_memory[trans_addr/4] = trans_data;

        // User fill in write response
        fill_wr_reactive                (wr_reactive);

        // Write driver send response to VIP interface
        slave_agent.wr_driver.send            (wr_reactive);
    end
endtask

task rd_response();
    // Declare a handle for write response
    axi_transaction                    rd_reactive;
    integer trans_len;
    integer trans_addr;
    logic [7:0] trans_data[3:0];
    integer i;

    forever begin
        // Block till write transaction occurs
        slave_agent.rd_driver.get_rd_reactive (rd_reactive);

        trans_len = rd_reactive.get_len();
        trans_addr = rd_reactive.get_addr();

        for(i = 0; i < 4; i++) begin
            trans_data[i] = ram_memory[trans_addr/4][i*8+:8];
        end

        $display("\n/********* AXI READ TRANSACTION ********/\n");
        $display("Len = %d\n", trans_len);
        $display("Addr = %h\n", trans_addr);
        $display("Read data = %h\n", ram_memory[trans_addr/4]);
        $display("/****************************************/\n");

        rd_reactive.set_data_beat_unpacked(rd_reactive.get_beat_index(),trans_data);
        rd_reactive.clr_beat_index();

        rd_reactive.set_beat_delay(0,$urandom_range(0,10));

        // rd_reactive.set_data_beat(0, trans_data, 1, 4'h1111);
        // Write driver send response to VIP interface
        slave_agent.rd_driver.send            (rd_reactive);
    end
endtask

function automatic void fill_wr_reactive(inout axi_transaction t);
    t.set_bresp(XIL_AXI_RESP_OKAY);
    t.set_beat_delay(0,$urandom_range(0,10));
endfunction: fill_wr_reactive

task wr_pix_response();
    // Declare a handle for write response
    axi_transaction                    wr_reactive;
    integer trans_len;
    integer trans_addr;
    integer trans_data;

    forever begin
        // Block till write transaction occurs
        slave_agent_pix_wr.wr_driver.get_wr_reactive (wr_reactive);
        trans_len = wr_reactive.get_len();
        trans_addr = wr_reactive.get_addr();
        trans_data = wr_reactive.get_data_beat(0);
        $display("\n/********* AXI WRITE TRANSACTION ********/\n");
        $display("Len = %d\n", trans_len);
        $display("Addr = %h\n", trans_addr);
        $display("Data = %h\n", trans_data);
        $display("/****************************************/\n");

        ram_memory[trans_addr/4] = trans_data;

        // User fill in write response
        fill_wr_reactive                (wr_reactive);

        // Write driver send response to VIP interface
        slave_agent_pix_wr.wr_driver.send            (wr_reactive);
    end
endtask

task rd_pix_response();
    // Declare a handle for write response
    axi_transaction                    rd_reactive;
    integer trans_len;
    integer trans_addr;
    logic [7:0] trans_data[3:0];
    integer i;

    forever begin
        // Block till write transaction occurs
        slave_agent_pix_rd.rd_driver.get_rd_reactive (rd_reactive);

        trans_len = rd_reactive.get_len();
        trans_addr = rd_reactive.get_addr();

        for(i = 0; i < 4; i++) begin
            trans_data[i] = ram_memory[trans_addr/4][i*8+:8];
        end

        $display("\n/********* AXI READ TRANSACTION ********/\n");
        $display("Len = %d\n", trans_len);
        $display("Addr = %h\n", trans_addr);
        $display("Read data = %h\n", ram_memory[trans_addr/4]);
        $display("/****************************************/\n");

        rd_reactive.set_data_beat_unpacked(rd_reactive.get_beat_index(),trans_data);
        rd_reactive.clr_beat_index();

        rd_reactive.set_beat_delay(0,$urandom_range(0,10));

        // rd_reactive.set_data_beat(0, trans_data, 1, 4'h1111);
        // Write driver send response to VIP interface
        slave_agent_pix_rd.rd_driver.send            (rd_reactive);
    end
endtask

endmodule