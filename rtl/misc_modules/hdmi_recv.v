`default_nettype none

module hdmi_recv #(
    parameter BURST_SIZE = 128,
    parameter MAX_OUTSTANDING_TR = 1

)(
    input   wire            hdmi_rst_n              ,
    input   wire            hdmi_clk                ,

    input   wire [24-1:0]   hdmi_data               ,
    input   wire            hdmi_hs                 ,
    input   wire            hdmi_vs                 ,
    input   wire            hdmi_de                 ,

    /********* AXI write channels *********/
    input   wire            clk_sys                 ,
    input   wire            rst_sys_n               ,

    output wire [4 - 1:0]   mst_axi_awid            ,
    output wire [32 - 1:0]  mst_axi_awaddr          ,
    output wire [7:0]       mst_axi_awlen           ,
    output wire [2:0]       mst_axi_awsize          ,
    output wire [1:0]       mst_axi_awburst         ,
    output wire [0:0]       mst_axi_awlock          ,
    output wire [3:0]       mst_axi_awcache         ,
    output wire [2:0]       mst_axi_awprot          ,
    output wire [3:0]       mst_axi_awqos           ,
    output wire             mst_axi_awvalid         ,
    input  wire             mst_axi_awready         ,

    output wire [31:0]      mst_axi_wdata           ,
    output wire [3:0]       mst_axi_wstrb           ,
    output wire             mst_axi_wlast           ,
    output wire             mst_axi_wvalid          ,
    input  wire             mst_axi_wready          ,

    output wire [3:0]       mst_axi_bid             ,
    output wire [3:0]       mst_axi_wid             ,
    input  wire [1:0]       mst_axi_bresp           ,
    input  wire             mst_axi_bvalid          ,
    output wire             mst_axi_bready          ,

    /********* MM iface *********/
    input   wire [7:0]      ctrl_address            ,
    input   wire            ctrl_read               ,
    output  wire [31:0]     ctrl_readdata           ,
    output  wire [1:0]      ctrl_response           ,
    input   wire            ctrl_write              ,
    input   wire [31:0]     ctrl_writedata          ,
    input   wire [3:0]      ctrl_byteenable         ,
    output  wire            ctrl_waitrequest
);

assign mst_axi_awid     = 2'b00;
assign mst_axi_awsize   = 3'b010;
assign mst_axi_awburst  = 2'b01;
assign mst_axi_awlock   = 2'b00;
assign mst_axi_awcache  = 4'b0000;
assign mst_axi_awprot   = 3'b000;
assign mst_axi_awqos    = 4'b000;
assign mst_axi_bready   = 1'b1;
assign mst_axi_bid      = 4'h0;
assign mst_axi_wid      = 4'h0;

localparam REGISTERS_NUMBER     = 8;
localparam CTRL_ADDR_WIDTH      = 8;
localparam MEMORY_MAP           = {
                                    8'h1C,
                                    8'h18,
                                    8'h14,
                                    8'h10,
                                    8'h0C,
                                    8'h08,
                                    8'h04,
                                    8'h00
                                    };

wire [REGISTERS_NUMBER - 1 : 0] sys_read_req;
wire                            sys_read_ready;
wire [31:0]                     sys_read_data;
wire [1:0]                      sys_read_resp;
wire                            sys_write_ready;
wire [REGISTERS_NUMBER - 1 : 0] sys_write_req;
wire [3:0]                      sys_write_strb;
wire [31:0]                     sys_write_data;

avalon_mm_manager  #(
        .REGISTERS_NUMBER (REGISTERS_NUMBER     ),
        .ADDR_WIDTH       (CTRL_ADDR_WIDTH      ),
        .MEMORY_MAP       (MEMORY_MAP           )
    ) avalon_mm_manager_0 (

    .clk                     (clk_sys                           ),
    .rst_n                   (rst_sys_n                         ),

    /********* Avalon MM Slave iface *********/
    .avl_mm_addr             (ctrl_address                  ),

    .avl_mm_read             (ctrl_read                     ),
    .avl_mm_readdata         (ctrl_readdata                 ),
    .avl_mm_response         (ctrl_response                 ),

    .avl_mm_write            (ctrl_write                    ),
    .avl_mm_writedata        (ctrl_writedata                ),
    .avl_mm_byteenable       (ctrl_byteenable               ),

    .avl_mm_waitrequest      (ctrl_waitrequest              ),

    /********* sys iface *********/
    .sys_read_req            (sys_read_req                  ),
    .sys_read_ready          (sys_read_ready                ),
    .sys_read_data           (sys_read_data                 ),
    .sys_read_resp           (sys_read_resp                 ),

    .sys_write_ready         (sys_write_ready               ),
    .sys_write_req           (sys_write_req                 ),
    .sys_write_strb          (sys_write_strb                ),
    .sys_write_data          (sys_write_data                )
);

assign sys_read_resp = 2'b00;
assign sys_write_ready = 1'b1;

reg [24-1:0] start_addr;
reg dma_enable;
reg reg_fifo_full;
reg reg_write_start_addr;
wire [31:0] w_reg_sr;
reg reg_vs_recv;

reg [26-1:0] reg_pixel_number;
reg [27-1:0] reg_words_number;
reg [27-1:0] reg_words_cnt;
reg [32-1:0] reg_hs_cnt;
reg [32-1:0] reg_vs_cnt;
reg [32-1:0] reg_frames_cnt;
reg [32-1:0] reg_pix_cnt;

wire [32-1:0] w_hs_cnt;
wire [32-1:0] w_vs_cnt;
wire [32-1:0] w_frames_cnt;
wire [32-1:0] w_pix_cnt;
wire          w_vs_recv;
reg           w_vs_recv_del;

assign w_reg_sr = {31'b0, reg_vs_recv};

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)  begin
        reg_hs_cnt          <= 'b0;
        reg_vs_cnt          <= 'b0;
        reg_frames_cnt      <= 'b0;
        reg_pix_cnt         <= 'b0;
    end else begin
        reg_hs_cnt          <= w_hs_cnt;
        reg_vs_cnt          <= w_vs_cnt;
        reg_frames_cnt      <= w_frames_cnt;
        reg_pix_cnt         <= w_pix_cnt;
    end
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              start_addr <= 24'b0;
    else if(sys_write_req[0])   start_addr <= sys_write_data;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              w_vs_recv_del <= 1'b0;
    else                        w_vs_recv_del <= w_vs_recv;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              reg_write_start_addr <= 1'b0;
    else if(sys_write_req[0])   reg_write_start_addr <= 1'b1;
    else                        reg_write_start_addr <= 1'b0;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              dma_enable <= 1'b0;
    else if(sys_write_req[2])   dma_enable <= sys_write_data[0];
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              reg_pixel_number <= 1'b0;
    else if(sys_write_req[1])   reg_pixel_number <= sys_write_data[26-1:0];
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              reg_words_number <= 1'b0;
    else                        reg_words_number <= (reg_pixel_number*3) >> 2;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                              reg_vs_recv <= 'b0;
    else if((w_vs_recv^w_vs_recv_del)&w_vs_recv_del)            reg_vs_recv <= 1;
    else if(sys_read_req[7])                                    reg_vs_recv <= 0;
end

wire  [31:0]    reg_read;
reg  [31:0]     reg_read_reg;
reg             read_ack;

always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)      reg_read_reg <= 32'b0;
    else                reg_read_reg <= reg_read;

always @(posedge clk_sys or negedge rst_sys_n)
    if(!rst_sys_n)      read_ack <= 1'b0;
    else                read_ack <= |sys_read_req & (!read_ack);

assign sys_read_data    = reg_read_reg;
assign sys_read_ready   = read_ack;
assign sys_read_resp    = 2'b0;
assign reg_read         =   ({32{sys_read_req[0]}}          & {8'b0,start_addr          }   )          |
                            ({32{sys_read_req[1]}}          & {6'b0,reg_pixel_number    }   )          |
                            ({32{sys_read_req[2]}}          & {31'b0, dma_enable        }   )          |
                            ({32{sys_read_req[3]}}          & reg_hs_cnt                    )          |
                            ({32{sys_read_req[4]}}          & reg_vs_cnt                    )          |
                            ({32{sys_read_req[5]}}          & reg_frames_cnt                )          |
                            ({32{sys_read_req[6]}}          & reg_pix_cnt                   )          |
                            ({32{sys_read_req[7]}}          & w_reg_sr                      );

/* latching input data */
reg [23:0] data_line_resync [4:0];
reg [4:0] hs_line_resync;
reg [4:0] vs_line_resync;
reg [6:0] de_line_resync;

integer i;

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) begin
        for (i=0; i<5; i=i+1) begin
            data_line_resync[i] <= 'b0;
        end

        hs_line_resync <= 'b0;
        vs_line_resync <= 'b0;
        de_line_resync <= 'b0;
    end else
    begin
        data_line_resync[0] <= hdmi_data;
        hs_line_resync[0] <= hdmi_hs;
        vs_line_resync[0] <= hdmi_vs;
        de_line_resync[0] <= hdmi_de;

        for (i=1; i<5; i=i+1) begin
            data_line_resync[i] <= data_line_resync[i-1];
        end

        hs_line_resync[4:1] <= hs_line_resync[3:0];
        vs_line_resync[4:1] <= vs_line_resync[3:0];
        de_line_resync[6:1] <= de_line_resync[5:0];
    end
end
reg [47:0] hdmi_data_repack_0;
reg [47:0] hdmi_data_repack_1;
reg [31:0] hdmi_data_repack_2;
reg [1:0] byte_shift_0;
reg [2:0] byte_shift_1;
wire fifo_write;

/*    statistics part    */

wire cdc_ready_0;
wire cdc_ready_1;
wire cdc_ready_2;
wire cdc_ready_3;
wire cdc_ready_4;

reg [31:0] hs_cnt_presync;
reg [31:0] vs_cnt_presync;
reg [31:0] fps_cnt_presync;
reg [31:0] pix_cnt_presync;
reg [31:0] fps_cnt_curr;
reg [31:0] hs_cnt_curr;
reg [31:0] vs_cnt_curr;
reg [31:0] pix_cnt_curr;

feedback_cdc_sync #(
    .WIDTH(32)
) hs_counter_cdc (
    .clk_src           (hdmi_clk         ),    // Clock of source domain
    .rst_n_src         (hdmi_rst_n       ),    // reset of source domain
    .clk_dest          (clk_sys          ),    // Clock of destination domain
    .rst_n_dest        (rst_sys_n        ),    // reset of destination domain

    .src_data          (hs_cnt_presync   ),
    .src_write         (cdc_ready_0      ),
    .src_ready         (cdc_ready_0      ),

    .dest_data         (w_hs_cnt    )
);

feedback_cdc_sync #(
    .WIDTH(32)
) vs_counter_cdc (
    .clk_src           (hdmi_clk         ),    // Clock of source domain
    .rst_n_src         (hdmi_rst_n       ),    // reset of source domain
    .clk_dest          (clk_sys          ),    // Clock of destination domain
    .rst_n_dest        (rst_sys_n        ),    // reset of destination domain

    .src_data          (vs_cnt_presync   ),
    .src_write         (cdc_ready_1      ),
    .src_ready         (cdc_ready_1      ),

    .dest_data         (w_vs_cnt    )
);

feedback_cdc_sync #(
    .WIDTH(32)
) frames_counter_cdc (
    .clk_src           (hdmi_clk         ),    // Clock of source domain
    .rst_n_src         (hdmi_rst_n       ),    // reset of source domain
    .clk_dest          (clk_sys          ),    // Clock of destination domain
    .rst_n_dest        (rst_sys_n        ),    // reset of destination domain

    .src_data          (fps_cnt_presync  ),
    .src_write         (cdc_ready_2      ),
    .src_ready         (cdc_ready_2      ),

    .dest_data         (w_frames_cnt    )
);

feedback_cdc_sync #(
    .WIDTH(32)
) pix_counter_cdc (
    .clk_src           (hdmi_clk         ),    // Clock of source domain
    .rst_n_src         (hdmi_rst_n       ),    // reset of source domain
    .clk_dest          (clk_sys          ),    // Clock of destination domain
    .rst_n_dest        (rst_sys_n        ),    // reset of destination domain

    .src_data          (pix_cnt_presync  ),
    .src_write         (cdc_ready_3      ),
    .src_ready         (cdc_ready_3      ),

    .dest_data         (w_pix_cnt    )
);

reg reg_vs_recv_save;

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         reg_vs_recv_save <= 1'b0;
    else if((vs_line_resync[2] ^ vs_line_resync[3]) & vs_line_resync[3])    reg_vs_recv_save <= 1'b1;
    else if(cdc_ready_4)                                                    reg_vs_recv_save <= 1'b0;

end

feedback_cdc_sync #(
    .WIDTH(1)
) vs_strobe_cdc (
    .clk_src           (hdmi_clk         ),    // Clock of source domain
    .rst_n_src         (hdmi_rst_n       ),    // reset of source domain
    .clk_dest          (clk_sys          ),    // Clock of destination domain
    .rst_n_dest        (rst_sys_n        ),    // reset of destination domain

    .src_data          (reg_vs_recv_save ),
    .src_write         (cdc_ready_4      ),
    .src_ready         (cdc_ready_4      ),

    .dest_data         (w_vs_recv    )
);

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         hs_cnt_curr <= 'b0;
    else if((hs_line_resync[2] ^ hs_line_resync[3]) & hs_line_resync[2])    hs_cnt_curr <= 0;
    else if(de_line_resync[2])                                              hs_cnt_curr <= hs_cnt_curr + 1;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         vs_cnt_curr <= 'b0;
    else if((vs_line_resync[2] ^ vs_line_resync[3]) & vs_line_resync[2])    vs_cnt_curr <= 0;
    else if((hs_line_resync[2] ^ hs_line_resync[3]) & hs_line_resync[2])    vs_cnt_curr <= vs_cnt_curr + 1;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         pix_cnt_curr <= 'b0;
    else if((vs_line_resync[2] ^ vs_line_resync[3]) & vs_line_resync[2])    pix_cnt_curr <= 0;
    else if(de_line_resync[2])                                              pix_cnt_curr <= pix_cnt_curr + 1;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         hs_cnt_presync <= 'b0;
    else if((hs_line_resync[2] ^ hs_line_resync[3]) & hs_line_resync[2])    hs_cnt_presync <= hs_cnt_curr;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         vs_cnt_presync <= 'b0;
    else if((vs_line_resync[2] ^ vs_line_resync[3]) & vs_line_resync[2])    vs_cnt_presync <= vs_cnt_curr;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         pix_cnt_presync <= 'b0;
    else if((vs_line_resync[2] ^ vs_line_resync[3]) & vs_line_resync[2])    pix_cnt_presync <= pix_cnt_curr;
end

localparam ONE_SEC_HDMI_CLOCK_NUMBER = 100000000;
reg [31:0] hdmi_clock_counter;

wire reset_clock_counter;
assign reset_clock_counter = hdmi_clock_counter == ONE_SEC_HDMI_CLOCK_NUMBER-1;

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                         hdmi_clock_counter <= 'b0;
    else if(reset_clock_counter)            hdmi_clock_counter <= 0;
    else                                    hdmi_clock_counter <= hdmi_clock_counter + 1;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                         fps_cnt_presync <= 'b0;
    else if(reset_clock_counter)            fps_cnt_presync <= fps_cnt_curr;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                                                         fps_cnt_curr <= 'b0;
    else if(reset_clock_counter)                                            fps_cnt_curr <= 0;
    else if((vs_line_resync[2] ^ vs_line_resync[3]) & vs_line_resync[2])    fps_cnt_curr <= fps_cnt_curr + 1;
end

/*END*/

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                 byte_shift_0 <= 'b0;
    else if(de_line_resync[2])      byte_shift_0 <= byte_shift_0 - 1;
    else                            byte_shift_0 <= 0;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                 byte_shift_1 <= 'b0;
    else if(de_line_resync[3])      byte_shift_1 <= (byte_shift_0 == 0 ? 0 : 4);
    else                            byte_shift_1 <= 0;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) hdmi_data_repack_0 <= 'b0;
    else            hdmi_data_repack_0 <= (data_line_resync[2] << byte_shift_0*8) | {48{1'b0}};
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) hdmi_data_repack_1 <= 'b0;
    else            hdmi_data_repack_1 <= hdmi_data_repack_0 >> byte_shift_1*8;
end

wire [47:0] conv_repak;

assign conv_repak = hdmi_data_repack_0 | hdmi_data_repack_1;

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) hdmi_data_repack_2 <= 'b0;
    else            hdmi_data_repack_2 <= conv_repak[31:0];
end

assign fifo_write = (byte_shift_0 != 2'd2) && de_line_resync[5] && de_line_resync[4];

wire w_fifo_empty;
wire w_fifo_full;
wire w_fifo_read;
wire [31:0] w_fifo_data_out;
wire [9:0]  w_rd_data_count;
reg                     r_mst_axi_awvalid;

assign w_fifo_read = mst_axi_wready && mst_axi_wvalid;

`ifdef SPARTAN7
hdmi_data_fifo hdmi_data_fifo_0(
    .rst                (!rst_sys_n                             ),
    .wr_clk             (hdmi_clk                               ),
    .rd_clk             (clk_sys                                ),
    .din                (hdmi_data_repack_2                     ),
    .wr_en              (fifo_write                             ),
    .rd_en              (w_fifo_read                            ),
    .dout               (w_fifo_data_out                        ),
    .full               (w_fifo_full                            ),
    .empty              (w_fifo_empty                           ),
    .rd_data_count      (w_rd_data_count                        ),
    .wr_rst_busy        (),
    .rd_rst_busy        ()
   );
`else
hdmi_data_fifo_s6 hdmi_data_fifo_s6_0(
  .rst                  (!rst_sys_n                             ),
  .wr_clk               (hdmi_clk                               ),
  .rd_clk               (clk_sys                                ),
  .din                  (hdmi_data_repack_2                     ),
  .wr_en                (fifo_write                             ),
  .rd_en                (w_fifo_read                            ),
  .dout                 (w_fifo_data_out                        ),
  .full                 (w_fifo_full                            ),
  .empty                (w_fifo_empty                           ),
  .rd_data_count        (w_rd_data_count                        )
);
`endif

`ifdef SPARTAN7
localparam BW_TRANS_CNT = $clog2(MAX_OUTSTANDING_TR);
localparam BW_BURST_CNT = $clog2(BURST_SIZE);
`else
localparam BW_TRANS_CNT = clog2(MAX_OUTSTANDING_TR);
localparam BW_BURST_CNT = clog2(BURST_SIZE);
`endif

reg [24-1:0]            r_mst_axi_awaddr;

reg [BW_BURST_CNT-1:0]  r_burst_cnt;
reg [BW_TRANS_CNT-1:0]  r_transaction_counter;
wire                    reset_addr_pointer;
wire                    vs_front_received;
reg [3:0]               vs_line_sys_clock;
reg                     wvalid_enable;

assign vs_front_received    = (vs_line_sys_clock[3] ^ vs_line_sys_clock[2]) & vs_line_sys_clock[2];
assign reset_addr_pointer   = reg_write_start_addr || vs_front_received;
assign mst_axi_wdata        = w_fifo_data_out;
assign mst_axi_wstrb        = 4'b1111;
assign mst_axi_wlast        = (r_burst_cnt == BURST_SIZE-1);
assign mst_axi_wvalid       = !w_fifo_empty && wvalid_enable;

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)  vs_line_sys_clock <= 4'b0;
    else            vs_line_sys_clock <= {vs_line_sys_clock[2:0], vs_line_resync[4]};
end

wire send_aw_trans;

assign send_aw_trans = (r_transaction_counter < MAX_OUTSTANDING_TR) && (w_rd_data_count >= BURST_SIZE-2);

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                                                  r_transaction_counter <= 2'b0;
    else if(mst_axi_bvalid && mst_axi_bready)                                       r_transaction_counter <= r_transaction_counter - 2'd1;
    else if(dma_enable) begin
        if(send_aw_trans && mst_axi_awready && mst_axi_bvalid && mst_axi_bready)    r_transaction_counter <= r_transaction_counter;
        else if(send_aw_trans && mst_axi_awready)                                   r_transaction_counter <= r_transaction_counter + 2'd1;
    end

end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                                  wvalid_enable <= 1'b0;
    else if(mst_axi_awready && mst_axi_awvalid)                     wvalid_enable <= 1'b1;
    else if(mst_axi_wlast && mst_axi_wvalid && mst_axi_wready)      wvalid_enable <= 1'b0;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                      r_mst_axi_awvalid <= 1'b0;
    else if(send_aw_trans && dma_enable)                r_mst_axi_awvalid <= 1'b1;
    else if(mst_axi_awready && !send_aw_trans)          r_mst_axi_awvalid <= 1'b0;

end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                          r_mst_axi_awaddr <= 'b0;
    else if(reset_addr_pointer)                             r_mst_axi_awaddr <= start_addr;
    else if(dma_enable) begin
        if(r_mst_axi_awvalid && mst_axi_awready)            r_mst_axi_awaddr <= r_mst_axi_awaddr + BURST_SIZE*4;
    end
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                                  r_burst_cnt <= 'b0;
    else if(dma_enable) begin
        if(mst_axi_wlast && mst_axi_wvalid && mst_axi_wready)       r_burst_cnt <= 'b0;
        else if(mst_axi_wvalid && mst_axi_wready)                   r_burst_cnt <= r_burst_cnt + 1'b1;
    end
end

assign mst_axi_awaddr       = {8'b0, r_mst_axi_awaddr};
assign mst_axi_awlen        = BURST_SIZE-1; //r_mst_axi_awlen;
assign mst_axi_awvalid      = r_mst_axi_awvalid;

`ifndef SPARTAN7

function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1)
value = value>>1;
end
endfunction

`endif

endmodule

`default_nettype wire