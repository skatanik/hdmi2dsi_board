module pattern_generator #(
    parameter IMG_HEIGH = 24,
    parameter IMG_WIDTH = 64
)(
    input   wire                                clk                         ,
    input   wire                                rst_n                       ,

    /*********  Stream in *********/
    input  wire [31:0]                          st_in_data                     ,
    input  wire                                 st_in_valid                    ,
    input  wire                                 st_in_endofpacket              ,
    input  wire                                 st_in_startofpacket            ,
    output wire                                 st_in_ready                    ,

    /*********  Stream out *********/
    output  wire [31:0]                         st_out_data                     ,
    output  wire                                st_out_valid                    ,
    output  wire                                st_out_endofpacket              ,
    output  wire                                st_out_startofpacket            ,
    input   wire                                st_out_ready                    ,

    /********* MM iface *********/
    input   wire [3:0]                          ctrl_address                ,
    input   wire                                ctrl_read                   ,
    output  wire [31:0]                         ctrl_readdata               ,
    output  wire [1:0]                          ctrl_response               ,
    input   wire                                ctrl_write                  ,
    input   wire [31:0]                         ctrl_writedata              ,
    input   wire [3:0]                          ctrl_byteenable             ,
    output  wire                                ctrl_waitrequest
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

    .clk                     (clk                           ),
    .rst_n                   (rst_n                         ),

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
wire fifo_write;
reg source_pg;
reg dma_enable;
wire w_st_out_endofpacket;
wire w_st_out_startofpacket;
reg [31:0] hdmi_data_repack_2;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  source_pg <= 1'b1;
    else if(sys_write_req[0])   source_pg <= sys_write_data[0];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  dma_enable <= 1'b0;
    else if(sys_write_req[1])   dma_enable <= sys_write_data[0];
end

assign st_out_data             = source_pg ? hdmi_data_repack_2     : st_in_data;
assign st_out_valid            = source_pg ? fifo_write             : st_in_valid;
assign st_out_endofpacket      = source_pg ? w_st_out_endofpacket   : st_in_endofpacket;
assign st_out_startofpacket    = source_pg ? w_st_out_startofpacket : st_in_startofpacket;
assign st_in_ready             = source_pg ? 1'b1                   : st_out_ready;

reg [47:0] hdmi_data_repack_0;
reg [47:0] hdmi_data_repack_1;
reg [1:0] byte_shift_0;
reg [2:0] byte_shift_1;

reg [4:0] en_del;
reg [23:0] rgb_reg;

reg [31:0] data_counter;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  rgb_reg <= 24'd0;
    else if(en_del[0] & st_out_ready)           rgb_reg <= 24'hFFFFFF;
    // else if(en_del[0] & st_out_ready)           rgb_reg <= rgb_reg + 1 + (1 << 8) + (1 << 16);
end

wire last_data;

assign last_data = (data_counter == IMG_HEIGH*IMG_WIDTH*3/4 - 1);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  data_counter <= 32'd0;
    else if(fifo_write && st_out_ready)  begin
        if(last_data)                           data_counter <= 0;
        else                                    data_counter <= data_counter + 1;
    end
end

assign w_st_out_endofpacket     = (last_data) && fifo_write;
assign w_st_out_startofpacket   = (data_counter == 0) && fifo_write;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  en_del <= 5'b0;
    else        en_del <= {en_del[3:0], dma_enable};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                      byte_shift_0 <= 2'd0;
    else if(en_del[1] & st_out_ready)               byte_shift_0 <= byte_shift_0 - 2'd1;
    else                                            byte_shift_0 <= 2'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  byte_shift_1 <= 3'd0;
    else if(en_del[2] & st_out_ready)           byte_shift_1 <= (byte_shift_0 == 2'd0 ? 3'd0 : 3'd4);
    else                                        byte_shift_1 <= 3'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)      hdmi_data_repack_0 <= 'b0;
    else            hdmi_data_repack_0 <= (rgb_reg << byte_shift_0*8) | {48{1'b0}};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)      hdmi_data_repack_1 <= 'b0;
    else            hdmi_data_repack_1 <= hdmi_data_repack_0 >> byte_shift_1*8;
end

wire [47:0] conv_repak;

assign conv_repak = hdmi_data_repack_0 | hdmi_data_repack_1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)      hdmi_data_repack_2 <= 'b0;
    else            hdmi_data_repack_2 <= conv_repak[31:0];
end

assign fifo_write = (byte_shift_0 != 2'd2) && en_del[4] && en_del[3];

endmodule