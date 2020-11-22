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

reg [ADDR_WIDTH-1:0] start_addr;
reg [30-1:0] words_number;
reg dma_enable;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  start_addr <= 'b0;
    else if(sys_write_req[0])   start_addr <= sys_write_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  words_number <= 'b0;
    else if(sys_write_req[1])   words_number <= sys_write_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  dma_enable <= 'b0;
    else if(sys_write_req[2])   dma_enable <= sys_write_data[0];
end

endmodule