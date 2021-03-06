module axi_to_stream_dma #(
    parameter ADDR_WIDTH = 24,
    parameter BURST_SIZE = 64,
    parameter MAX_OUTSTANDING_TR = 1
)(
    input   wire                               clk                         ,
    input   wire                               rst_n                       ,

    /********* AXI read channels *********/
    output  wire [4 - 1:0]                     mst_axi_arid                ,
    output  wire [24 - 1:0]                    mst_axi_araddr              ,
    output  wire [7:0]                         mst_axi_arlen               ,
    output  wire [2:0]                         mst_axi_arsize              ,
    output  wire [1:0]                         mst_axi_arburst             ,
    output  wire [0:0]                         mst_axi_arlock              ,
    output  wire [3:0]                         mst_axi_arcache             ,
    output  wire [2:0]                         mst_axi_arprot              ,
    output  wire [3:0]                         mst_axi_arqos               ,
    output  wire                               mst_axi_arvalid             ,
    input   wire                               mst_axi_arready             ,

    input   wire [4 - 1:0]                     mst_axi_rid                 ,
    input   wire [32 - 1:0]                    mst_axi_rdata               ,
    input   wire [1:0]                         mst_axi_rresp               ,
    input   wire                               mst_axi_rlast               ,
    input   wire                               mst_axi_rvalid              ,
    output  wire                               mst_axi_rready              ,

    /*********  Stream out *********/
    output  wire [31:0]                        st_data                     ,
    output  wire                               st_valid                    ,
    output  wire                               st_endofpacket              ,
    output  wire                               st_startofpacket            ,
    input   wire                               st_ready                    ,

    /********* MM iface *********/
    input   wire [3:0]                         ctrl_address                ,
    input   wire                               ctrl_read                   ,
    output  wire [31:0]                        ctrl_readdata               ,
    output  wire [1:0]                         ctrl_response               ,
    input   wire                               ctrl_write                  ,
    input   wire [31:0]                        ctrl_writedata              ,
    input   wire [3:0]                         ctrl_byteenable             ,
    output  wire                               ctrl_waitrequest
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
`ifdef SPARTAN7
localparam MAX_PENDING_RQST_LOG = $clog2(MAX_OUTSTANDING_TR);
`else
localparam MAX_PENDING_RQST_LOG = clog2(MAX_OUTSTANDING_TR);
`endif

assign sys_read_resp = 2'b00;
assign sys_write_ready = 1'b1;
assign sys_read_ready = 1'b1;
assign sys_read_data = 'b0;

reg [ADDR_WIDTH-1:0] start_addr;
reg [ADDR_WIDTH-1:0] curr_addr;
reg [30-1:0] words_number;
reg [30-1:0] words_number_cnt;
reg dma_enable;
wire addr_rst;
reg r_mst_axi_arvalid;
wire rqst_enable;
reg r_st_endofpacket;
reg r_st_startofpacket;
reg [MAX_PENDING_RQST_LOG-1:0] transactions_counter;
reg set_start_addr;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  set_start_addr <= 'b0;
    else if(sys_write_req[0])   set_start_addr <= 1;
    else                        set_start_addr <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  start_addr <= 24'b0;
    else if(sys_write_req[0])   start_addr <= sys_write_data[23:0];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  words_number <= 30'b0;
    else if(sys_write_req[1])   words_number <= sys_write_data[29:0];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  dma_enable <= 1'b0;
    else if(sys_write_req[2])   dma_enable <= sys_write_data[0];
end

assign mst_axi_arlen        = BURST_SIZE - 1;
assign mst_axi_arburst      = 2'b01;
assign mst_axi_arid         = 4'h0;
assign mst_axi_rid          = 4'h0;
assign mst_axi_arsize       = 3'b010;
assign mst_axi_arlock       = 2'b00;
assign mst_axi_arcache      = 4'b0000;
assign mst_axi_arprot       = 3'b000;
assign mst_axi_arqos        = 4'b000;
assign mst_axi_arvalid      = r_mst_axi_arvalid;
assign st_data              = mst_axi_rdata;
assign st_valid             = mst_axi_rvalid;
assign mst_axi_rready       = st_ready;
assign st_endofpacket       = mst_axi_rvalid && (words_number_cnt == (words_number - 1));
assign st_startofpacket     = mst_axi_rvalid && (words_number_cnt == 0);
assign mst_axi_araddr       = curr_addr;

assign rqst_enable              = (transactions_counter < (MAX_OUTSTANDING_TR - 2));
assign addr_rst                 = mst_axi_arready && mst_axi_arvalid && (curr_addr >= (start_addr + ((words_number-BURST_SIZE)<<2)));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                                                                  transactions_counter <= 'b0;
    else if(addr_rst)                                                                                           transactions_counter <= 'b0;
    else if(mst_axi_arready && r_mst_axi_arvalid && mst_axi_rvalid && mst_axi_rready && mst_axi_rlast)          transactions_counter <= transactions_counter;
    else if(mst_axi_arready && r_mst_axi_arvalid)                                                               transactions_counter <= transactions_counter + 2'd1;
    else if(mst_axi_rvalid && mst_axi_rready && mst_axi_rlast)                                                  transactions_counter <= transactions_counter - 2'd1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                          curr_addr <= 'b0;
    else if(set_start_addr)                             curr_addr <= start_addr;
    else if(addr_rst)                                   curr_addr <= start_addr;
    else if(mst_axi_arready && r_mst_axi_arvalid)       curr_addr <= curr_addr + (BURST_SIZE*4);
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                      r_mst_axi_arvalid <= 1'b0;
    else if(dma_enable && rqst_enable)                              r_mst_axi_arvalid <= 1'b1;
    else if(!rqst_enable && mst_axi_arready && r_mst_axi_arvalid)   r_mst_axi_arvalid <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                                              words_number_cnt <= 'b0;
    else if(mst_axi_rvalid && mst_axi_rready && st_endofpacket)                             words_number_cnt <= 'b0;
    else if(mst_axi_rvalid && mst_axi_rready)                                               words_number_cnt <= words_number_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                          r_st_endofpacket <= 1'b0;
    else if(words_number_cnt == (words_number - 1))     r_st_endofpacket <= 1'b1;
    else if(mst_axi_rvalid && mst_axi_rready)           r_st_endofpacket <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_st_startofpacket <= 1'b1;
    else if(st_valid)           r_st_startofpacket <= 1'b0;
    else if(r_st_endofpacket)   r_st_startofpacket <= 1'b1;
end


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