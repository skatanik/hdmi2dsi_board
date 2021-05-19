module sys_timer (
    input   wire                                clk                         ,
    input   wire                                rst_n                       ,

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

/********* Registers *********/
wire [31:0]  sys_timer_reg_cr;
wire [31:0]  sys_timer_reg_rld;
wire [31:0]  sys_timer_reg_curr;

/********* write signals *********/
wire sys_timer_reg_cr_w;
wire sys_timer_reg_rld_w;
wire sys_timer_reg_curr_w;

assign sys_timer_reg_cr_w             = sys_write_req[0];
assign sys_timer_reg_rld_w            = sys_write_req[1];
assign sys_timer_reg_curr_w            = sys_write_req[2];

/********* Read signals *********/
wire sys_timer_reg_cr_r;
wire sys_timer_reg_rld_r;
wire sys_timer_reg_curr_r;

assign sys_timer_reg_cr_r        = sys_read_req[0];
assign sys_timer_reg_rld_r       = sys_read_req[1];
assign sys_timer_reg_curr_r       = sys_read_req[2];

/********* IRQ *********/
reg irq_reg;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      irq_reg <= 1'b0;
    else            irq_reg <= (sys_timer_reg_cr[4] & sys_timer_reg_cr[3]);

assign irq = irq_reg;

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
assign reg_read         =   ({32{sys_timer_reg_cr_r}}           & sys_timer_reg_cr)           |
                            ({32{sys_timer_reg_rld_r}}          & sys_timer_reg_rld)          |
                            ({32{sys_timer_reg_curr_r}}          & sys_timer_reg_curr);

/********* Write regs *********/
reg write_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      write_ack <= 1'b0;
    else            write_ack <= |sys_write_req;

assign sys_write_ready = write_ack;

/********* Regs fields *********/
// CR
reg         sys_timer_cr_enable;
reg         sys_timer_cr_count_flag;
reg         sys_timer_cr_irq_en;
reg         sys_timer_cr_irq_status;

// rld
reg [23:0]  sys_timer_reload_val;

// CURR
reg [23:0]  sys_timer_current_val;


/********* Registers block *********/

/********************************************************************
reg:        CR
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
sys_timer_cr_enable      0         1         RW
sys_timer_cr_count_flag  1         1         RW
sys_timer_cr_irq_en      1         1         RW
sys_timer_cr_irq_status  1         1         RW1C
********************************************************************/

assign sys_timer_reg_cr = {
                    28'd0,
                    sys_timer_cr_irq_status,
                    sys_timer_cr_irq_en,
                    sys_timer_cr_count_flag,
                    sys_timer_cr_enable
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                              sys_timer_cr_irq_status <= 1'b0;
    else if(sys_timer_reg_cr_w & sys_write_data[3])         sys_timer_cr_irq_status <= 1'b0;
    else if(!(|sys_timer_current_val))                      sys_timer_cr_irq_status <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                      sys_timer_cr_irq_en <= 1'b0;
    else if(sys_timer_reg_cr_w)     sys_timer_cr_irq_en <= sys_write_data[2];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                              sys_timer_cr_count_flag <= 1'b0;
    else if(sys_timer_reg_cr_r)                             sys_timer_cr_count_flag <= 0;
    else if(!(|sys_timer_current_val))                      sys_timer_cr_count_flag <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                      sys_timer_cr_enable <= 1'b1;
    else if(sys_timer_reg_cr_w)     sys_timer_cr_enable <= sys_write_data[0];

/********************************************************************
reg:        reload
offset:     0x04

Field                   offset    width     access
-----------------------------------------------------------
sys_timer_rld             0         24         RW1C
********************************************************************/

assign uart_reg_isr = {
                    8'd0,
                    sys_timer_reload_val
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                          sys_timer_reload_val       <= 24'hffffff;
    else if(sys_timer_reg_rld_w)        sys_timer_reload_val       <= sys_write_data[23:0];

/********************************************************************
reg:        IER
offset:     0x08

Field                   offset    width     access
-----------------------------------------------------------

sys_timer_current_val     0         24         RO
********************************************************************/

assign uart_reg_ier = {
                    8'd0,
                    sys_timer_current_val
                    };

reg [2:0] divider_reg;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      divider_reg <= 3'b0;
    else            divider_reg <= divider_reg + 3'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                              sys_timer_current_val <= 24'hffffff;
    else if(!(|sys_timer_current_val))                      sys_timer_current_val <= sys_timer_reload_val;
    else if(sys_timer_cr_enable && (&divider_reg))          sys_timer_current_val <= sys_timer_current_val - 24'b1;


endmodule