module hdmi_recv #(
    parameter BURST_SIZE = 128,
    parameter MAX_OUTSTANDING_TR = 16

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
    output wire [24 - 1:0]  mst_axi_awaddr          ,
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

    output wire             mst_axi_bid             ,
    output wire             mst_axi_wid             ,
    input  wire [1:0]       mst_axi_bresp           ,
    input  wire             mst_axi_bvalid          ,
    output wire             mst_axi_bready          ,

    /********* MM iface *********/
    input   wire [4:0]      ctrl_address            ,
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
assign mst_axi_bready   = 1'b0;
assign mst_axi_bid      = 0;
assign mst_axi_wid      = 0;

localparam REGISTERS_NUMBER     = 5;
localparam CTRL_ADDR_WIDTH      = 4;
localparam MEMORY_MAP           = {
                                    4'h14,
                                    4'h10,
                                    4'h0C,
                                    4'h08,
                                    4'h04,
                                    4'h00
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
assign sys_read_ready = 1'b1;
assign sys_read_data = 'b0;

reg [24-1:0] start_addr;
reg [30-1:0] words_number;
reg dma_enable;
reg reg_fifo_full;
reg [26-1:0] reg_pixel_number;
reg [27-1:0] reg_words_number;
reg [27-1:0] reg_words_cnt;

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              start_addr <= 'b0;
    else if(sys_write_req[0])   start_addr <= sys_write_data;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              words_number <= 'b0;
    else if(sys_write_req[1])   words_number <= sys_write_data;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              dma_enable <= 'b0;
    else if(sys_write_req[2])   dma_enable <= sys_write_data[0];
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              reg_pixel_number <= 'b0;
    else if(sys_write_req[3])   reg_pixel_number <= sys_write_data[26-1:0];
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)              reg_words_number <= 'b0;
    else                        reg_words_number <= (reg_pixel_number*3) >> 2;
end

/* latching input data */
reg [23:0] data_line_resync [4:0];
reg [4:0] hs_line_resync;
reg [4:0] vs_line_resync;
reg [5:0] de_line_resync;

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
        de_line_resync[5:1] <= de_line_resync[4:0];
    end
end
reg [47:0] hdmi_data_repack_0;
reg [47:0] hdmi_data_repack_1;
reg [23:0] hdmi_data_repack_2;
reg [1:0] byte_shift;
reg [3:0] fifo_write;

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n)                 byte_shift <= 'b0;
    else if(de_line_resync[3])      byte_shift <= byte_shift + 1;
    else                            byte_shift <= 'd3;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) hdmi_data_repack_0 <= 'b0;
    else            hdmi_data_repack_0 <= {data_line_resync[2], {24{1'b0}}};
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) hdmi_data_repack_1 <= 'b0;
    else            hdmi_data_repack_1 <= hdmi_data_repack_0 >> byte_shift*8;
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) hdmi_data_repack_2 <= 'b0;
    else            hdmi_data_repack_2 <= hdmi_data_repack_1[31:0];
end

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) fifo_write <= 'b0;
    else            fifo_write <= {fifo_write[2:0], (byte_shift == 'd3)};
end

wire w_fifo_empty;
wire w_fifo_full;
wire [31:0] w_fifo_data_out;
wire [9:0]  w_rd_data_count;

reg [31:0] r_fifo_data_out;
reg        r_data_out_valid;

hdmi_data_fifo hdmi_data_fifo_0(
    .rst                (rst_sys_n                      ),
    .wr_clk             (hdmi_clk                       ),
    .rd_clk             (clk_sys                        ),
    .din                (hdmi_data_repack_2             ),
    .wr_en              (fifo_write[2]                  ),
    .rd_en              (!w_fifo_empty && st_ready      ),
    .dout               (w_fifo_data_out                ),
    .full               (w_fifo_full                    ),
    .empty              (w_fifo_empty                   ),
    .rd_data_count      (w_rd_data_count                ),
    .wr_rst_busy        (),
    .rd_rst_busy        ()
   );

localparam BW_TRANS_CNT = $clog2(MAX_OUTSTANDING_TR);
localparam BW_BURST_CNT = $clog2(BURST_SIZE);

reg                     r_mst_axi_awlen; //    = BURST_SIZE - 1;
reg [24-1:0]            r_mst_axi_awaddr;
reg                     r_mst_axi_awvalid;
reg [BW_BURST_CNT-1:0]  r_burst_cnt;
reg [BW_TRANS_CNT-1:0]  r_transaction_counter;
wire                    reset_addr_pointer;

assign mst_axi_wdata    = w_fifo_data_out;
assign mst_axi_wstrb    = 4'b1111;
assign mst_axi_wlast    = (r_burst_cnt == BURST_SIZE-1);
assign mst_axi_wvalid   = !w_fifo_empty && (r_transaction_counter != 0);

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                                                              r_transaction_counter <= 'b0;
    else if(dma_enable)                                                                         r_transaction_counter <= 'b0;
    else if(r_mst_axi_awvalid && mst_axi_awready && mst_axi_bvalid && mst_axi_bready)           r_transaction_counter <= r_transaction_counter;
    else if(r_mst_axi_awvalid && mst_axi_awready)                                               r_transaction_counter <= r_transaction_counter + 1;
    else if(mst_axi_bvalid && mst_axi_bready)                                                   r_transaction_counter <= r_transaction_counter - 1;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                                                                                      r_mst_axi_awvalid <= 1'b0;
    else if(dma_enable)                                                                                                 r_mst_axi_awvalid <= 1'b1;
    else if((r_transaction_counter <= MAX_OUTSTANDING_TR) && ((w_rd_data_count - r_burst_cnt) > BURST_SIZE))            r_mst_axi_awvalid <= 1'b1;
    else                                                                                                                r_mst_axi_awvalid <= 1'b0;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                  r_mst_axi_awaddr <= 1'b0;
    else if(dma_enable)                             r_mst_axi_awaddr <= 1'b0;
    else if(reset_addr_pointer)                     r_mst_axi_awaddr <= start_addr;
    else if(r_mst_axi_awvalid && mst_axi_awready)   r_mst_axi_awaddr <= r_mst_axi_awaddr + BURST_SIZE;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)                                                  r_burst_cnt <= 'b0;
    else if(dma_enable)                                             r_burst_cnt <= 'b0;
    else if(mst_axi_wlast && mst_axi_wvalid && mst_axi_wready)      r_burst_cnt <= 'b0;
    else if(mst_axi_wvalid && mst_axi_wready)                       r_burst_cnt <= r_burst_cnt + 1;
end

assign mst_axi_awaddr       = r_mst_axi_awaddr;
assign mst_axi_awlen        = BURST_SIZE-1; //r_mst_axi_awlen;
assign mst_axi_awvalid      = r_mst_axi_awvalid;

endmodule