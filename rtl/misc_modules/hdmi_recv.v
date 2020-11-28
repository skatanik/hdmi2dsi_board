module hdmi_recv(
    input   wire            hdmi_rst_n              ,
    input   wire            hdmi_clk                ,

    input   wire [24-1:0]   hdmi_data               ,
    input   wire            hdmi_hs                 ,
    input   wire            hdmi_vs                 ,
    input   wire            hdmi_de                 ,

    /********* ST output *********/
    input   wire            rst_sys_n               ,
    input   wire            clk_sys                 ,

    output  wire [31:0]     st_data                 ,
    output  wire            st_valid                ,
    output  wire            st_endofpacket          ,
    output  wire            st_startofpacket        ,
    input   wire            st_ready                ,

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


localparam REGISTERS_NUMBER     = 3;
localparam CTRL_ADDR_WIDTH      = 4;
localparam MEMORY_MAP           = {
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

reg [ADDR_WIDTH-1:0] start_addr;
reg [30-1:0] words_number;
reg dma_enable;
reg reg_fifo_full;

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

/* latching input data */
reg [23:0] data_line_resync [4:0];
reg [4:0] hs_line_resync;
reg [4:0] vs_line_resync;
reg [5:0] de_line_resync;

always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
    if(!hdmi_rst_n) begin
        data_line_resync <= 'b0;
        hs_line_resync <= 'b0;
        vs_line_resync <= 'b0;
        de_line_resync <= 'b0;
    end else
    begin
        data_line_resync[0] <= hdmi_data;
        hs_line_resync[0] <= hdmi_hs;
        vs_line_resync[0] <= hdmi_vs;
        de_line_resync[0] <= hdmi_de;

        data_line_resync[4:1] <= data_line_resync[3:0];
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
wire [31:0] w_fifo_data_out;

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
    .full               (),
    .empty              (w_fifo_empty                   ),
    .wr_rst_busy        (),
    .rd_rst_busy        ()
   );

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)      r_fifo_data_out <= 'b0;
    else if(st_ready)   r_fifo_data_out <= w_fifo_data_out;
end

always @(posedge clk_sys or negedge rst_sys_n) begin
    if(!rst_sys_n)  r_data_out_valid <= 'b0;
    else            r_data_out_valid <= !w_fifo_empty;
end




endmodule