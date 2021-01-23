`ifndef I2C_REGS
`define I2C_REGS

module i2c_regs (

    /********* Sys iface *********/
    input   wire                                clk                             ,   // Clock
    input   wire                                rst_n                           ,   // Asynchronous reset active low

    output  wire                                irq                             ,

    /********* Avalon-MM iface *********/
    input   wire [4:0]                          avl_mm_addr                     ,

    input   wire                                avl_mm_read                     ,
    output  wire [31:0]                         avl_mm_readdata                 ,
    output  wire [1:0]                          avl_mm_response                 ,

    input   wire                                avl_mm_write                    ,
    input   wire [31:0]                         avl_mm_writedata                ,
    input   wire [3:0]                          avl_mm_byteenable               ,

    output  wire                                avl_mm_waitrequest              ,

    /********* Control signals *********/
    output  wire [6:0]                          cmd_address                     ,
    output  wire                                cmd_start                       ,
    output  wire                                cmd_read                        ,
    output  wire                                cmd_write                       ,
    output  wire                                cmd_write_multiple              ,
    output  wire                                cmd_stop                        ,
    output  wire                                cmd_valid                       ,
    input   wire                                cmd_ready                       ,

    output  wire [7:0]                          data_in                         ,
    output  wire                                data_in_valid                   ,
    input   wire                                data_in_ready                   ,
    output  wire                                data_in_last                    ,

    input   wire [7:0]                          data_out                        ,
    input   wire                                data_out_valid                  ,
    output  wire                                data_out_ready                  ,
    input   wire                                data_out_last                   ,

    input   wire                                busy                            ,
    input   wire                                bus_control                     ,
    input   wire                                bus_active                      ,
    input   wire                                missed_ack                      ,

    output  wire [15:0]                         prescale                        ,
    output  wire                                stop_on_idle
);

localparam REGISTERS_NUMBER     = 6;
localparam ADDR_WIDTH           = 5;
localparam MEMORY_MAP           = {
                                    5'h14,
                                    5'h10,
                                    5'h0C,
                                    5'h08,
                                    5'h04,
                                    5'h00
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
        .ADDR_WIDTH       (ADDR_WIDTH           ),
        .MEMORY_MAP       (MEMORY_MAP           )
    ) avalon_mm_manager_0 (

    .clk                     (clk                           ),
    .rst_n                   (rst_n                         ),

    /********* Avalon MM Slave iface *********/
    .avl_mm_addr             (avl_mm_addr                   ),

    .avl_mm_read             (avl_mm_read                   ),
    .avl_mm_readdata         (avl_mm_readdata               ),
    .avl_mm_response         (avl_mm_response               ),

    .avl_mm_write            (avl_mm_write                  ),
    .avl_mm_writedata        (avl_mm_writedata              ),
    .avl_mm_byteenable       (avl_mm_byteenable             ),

    .avl_mm_waitrequest      (avl_mm_waitrequest            ),

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


/********* Registers *********/
wire [31:0]  i2c_reg_cr1;
wire [31:0]  i2c_reg_cr2;
wire [31:0]  i2c_reg_cr3;
wire [31:0]  i2c_reg_data_in;
wire [31:0]  i2c_reg_data_out;
wire [31:0]  i2c_reg_status;

/********* write signals *********/
wire i2c_reg_cr1_w;
wire i2c_reg_cr2_w;
wire i2c_reg_cr3_w;
wire i2c_reg_data_in_w;
wire i2c_reg_data_out_w;
wire i2c_reg_status_w;

assign i2c_reg_cr1_w                = sys_write_req[0];
assign i2c_reg_cr2_w                = sys_write_req[1];
assign i2c_reg_cr3_w                = sys_write_req[2];
assign i2c_reg_data_in_w            = sys_write_req[3];
assign i2c_reg_data_out_w           = sys_write_req[4];
assign i2c_reg_status_w             = sys_write_req[5];

/********* Read signals *********/
wire i2c_reg_cr1_r;
wire i2c_reg_cr2_r;
wire i2c_reg_cr3_r;
wire i2c_reg_data_in_r;
wire i2c_reg_data_out_r;
wire i2c_reg_status_r;

assign i2c_reg_cr1_r            = sys_read_req[0];
assign i2c_reg_cr2_r            = sys_read_req[1];
assign i2c_reg_cr3_r            = sys_read_req[2];
assign i2c_reg_data_in_r        = sys_read_req[3];
assign i2c_reg_data_out_r       = sys_read_req[4];
assign i2c_reg_status_r         = sys_read_req[5];

/********* IRQ *********/
//reg irq_reg;
//
//always @(posedge clk or negedge rst_n)
//    if(!rst_n)      irq_reg <= 1'b0;
//    else            irq_reg <= |(uart_reg_isr & uart_reg_ier);
//
//assign irq = irq_reg;

/********* Read regs *********/

wire  [31:0]    reg_read;
reg  [31:0]     reg_read_reg;
reg             read_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      reg_read_reg <= 32'b0;
    else            reg_read_reg <= reg_read;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      read_ack <= 1'b0;
    else            read_ack <= |sys_read_req & (!read_ack);

assign sys_read_data    = reg_read_reg;
assign sys_read_ready   = read_ack;
assign sys_read_resp    = 2'b0;
assign reg_read         =   ({32{i2c_reg_cr1_r}}            & i2c_reg_cr1)      |
                            ({32{i2c_reg_cr2_r}}            & i2c_reg_cr2)      |
                            ({32{i2c_reg_cr3_r}}            & i2c_reg_cr3)      |
                            ({32{i2c_reg_data_in_r}}        & i2c_reg_data_in)  |
                            ({32{i2c_reg_data_out_r}}       & i2c_reg_data_out) |
                            ({32{i2c_reg_status_r}}         & i2c_reg_status);

/********* Write regs *********/
reg write_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      write_ack <= 1'b0;
    else            write_ack <= |sys_write_req;

assign sys_write_ready = write_ack;

/********* Regs fields *********/
//CR1
reg         r_cmd_start;
reg         r_cmd_read;
reg         r_cmd_write;
reg         r_cmd_write_multiple;
reg         r_cmd_stop;
reg         r_cmd_valid;
//CR2
reg [6:0]   r_cmd_address;
//CR3
reg         r_stop_on_idle;
reg [15:0]  r_prescale;
//DATA IN
reg [7:0]   r_data_in;
//DATA OUT
reg [7:0]   r_data_out;
//STATUS
reg         r_busy;
reg         r_bus_control;
reg         r_bus_active;
reg         r_missed_ack;
reg         r_cmd_ready;

/********* Assigns *********/
assign cmd_start              = r_cmd_start;
assign cmd_read               = r_cmd_read;
assign cmd_write              = r_cmd_write;
assign cmd_write_multiple     = r_cmd_write_multiple;
assign cmd_stop               = r_cmd_stop;
assign cmd_valid              = r_cmd_valid;
assign cmd_address            = r_cmd_address;
assign stop_on_idle           = r_stop_on_idle;
assign prescale               = r_prescale;

/********* Registers block *********/

/********************************************************************
reg:        CR1
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
tx_enable               0         1         RW
rx_enable               1         1         RW
********************************************************************/

assign i2c_reg_cr1 = {
                    26'd0,
                    r_cmd_start,
                    r_cmd_read,
                    r_cmd_write,
                    r_cmd_write_multiple,
                    r_cmd_stop,
                    r_cmd_valid
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_cmd_start <= 1'b0;
    else if(i2c_reg_cr1_w)      r_cmd_start <= sys_write_data[5];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_cmd_read <= 1'b0;
    else if(i2c_reg_cr1_w)      r_cmd_read <= sys_write_data[4];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_cmd_write <= 1'b0;
    else if(i2c_reg_cr1_w)      r_cmd_write <= sys_write_data[3];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_cmd_write_multiple <= 1'b0;
    else if(i2c_reg_cr1_w)      r_cmd_write_multiple <= sys_write_data[2];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_cmd_stop <= 1'b0;
    else if(i2c_reg_cr1_w)      r_cmd_stop <= sys_write_data[1];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_cmd_valid <= 1'b0;
    else if(i2c_reg_cr1_w)      r_cmd_valid <= sys_write_data[0];

/********************************************************************
reg:        CR2
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
tx_enable               0         1         RW
rx_enable               1         1         RW
********************************************************************/

assign i2c_reg_cr2 = {
                    25'd0,
                    r_cmd_address
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_cmd_address <= 7'b0;
    else if(i2c_reg_cr2_w)      r_cmd_address <= sys_write_data[6:0];

/********************************************************************
reg:        CR3
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
tx_enable               0         1         RW
rx_enable               1         1         RW
********************************************************************/

assign i2c_reg_cr3 = {
                    15'd0,
                    r_stop_on_idle,
                    r_prescale
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_stop_on_idle <= 1'b0;
    else if(i2c_reg_cr3_w)      r_stop_on_idle <= sys_write_data[16];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_prescale <= 16'b0;
    else if(i2c_reg_cr3_w)      r_prescale <= sys_write_data[15:0];

/********************************************************************
reg:        DATA IN
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
tx_enable               0         1         RW
rx_enable               1         1         RW
********************************************************************/

assign i2c_reg_data_in = {
                    24'd0,
                    r_data_in
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                      r_data_in <= 8'b0;
    else if(i2c_reg_data_in_w)      r_data_in <= sys_write_data[7:0];

reg [7:0] data_in_2;
reg wr_data_del;
reg r_data_in_valid;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                          wr_data_del <= 1'b0;
    else if(i2c_reg_data_in_w)          wr_data_del <= 1'b1;
    else if(!r_data_in_valid)           wr_data_del <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_data_in_valid <= 1'b0;
    else if(wr_data_del)        r_data_in_valid <= 1'b1;
    else if(data_in_ready)      r_data_in_valid <= 1'b0;

assign data_in_valid = r_data_in_valid;
assign data_in_last = !wr_data_del;
assign data_in = data_in_2;

always @(posedge clk or negedge rst_n)
    if(!rst_n)              data_in_2 <= 1'b0;
    else if(wr_data_del)    data_in_2 <= r_data_in[7:0];


/********************************************************************
reg:        DATA OUT
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
tx_enable               0         1         RW
rx_enable               1         1         RW
********************************************************************/

assign i2c_reg_data_out = {
                    24'd0,
                    r_data_out
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                          r_data_out <= 8'b0;
    else if(data_out_valid)             r_data_out <= data_out;

/********************************************************************
reg:        STATUS
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
tx_enable               0         1         RW
rx_enable               1         1         RW
********************************************************************/

assign i2c_reg_status = {
                    27'd0,
                    r_busy,
                    r_bus_control,
                    r_bus_active,
                    r_missed_ack,
                    r_cmd_ready
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          r_busy <= 1'b0;
    else if(busy)                                       r_busy <= 1'b1;
    else if(i2c_reg_status_w & sys_write_data[4])       r_busy <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          r_bus_control <= 1'b0;
    else if(bus_control)                                r_bus_control <= 1'b1;
    else if(i2c_reg_status_w & sys_write_data[3])       r_bus_control <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          r_bus_active <= 1'b0;
    else if(bus_active)                                 r_bus_active <= 1'b1;
    else if(i2c_reg_status_w & sys_write_data[2])       r_bus_active <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          r_missed_ack <= 1'b0;
    else if(missed_ack)                                 r_missed_ack <= 1'b1;
    else if(i2c_reg_status_w & sys_write_data[1])       r_missed_ack <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          r_cmd_ready <= 1'b0;
    else if(cmd_ready)                                  r_cmd_ready <= 1'b1;
    else if(i2c_reg_status_w & sys_write_data[0])       r_cmd_ready <= 1'b0;

endmodule

`endif