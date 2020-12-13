`ifndef FB_CDC_SYNC
`define FB_CDC_SYNC
/********************************************************************
    Module implements Multi-cycle path (MCP) formulation with feedback
    scheme
    http://www.verilogpro.com/clock-domain-crossing-design-part-3/
********************************************************************/

module feedback_cdc_sync #(
    parameter WIDTH             = 1,
    parameter SRC_STAGES        = 2,
    parameter DEST_STAGES       = 2
    ) (
    input   wire                  clk_src           ,    // Clock of source domain
    input   wire                  rst_n_src         ,    // reset of source domain
    input   wire                  clk_dest          ,    // Clock of destination domain
    input   wire                  rst_n_dest        ,    // reset of destination domain

    input   wire [WIDTH-1:0]      src_data          ,
    input   wire                  src_write         ,
    output  wire                  src_ready         ,

    output  wire [WIDTH-1:0]      dest_data

);

/********* Source part *********/
reg [WIDTH-1:0]     src_out_reg;
wire                next_data_pulse;

always @(posedge clk_src or negedge rst_n_src)
    if(!rst_n_src)              src_out_reg <= 'b0;
    else if(next_data_pulse)    src_out_reg <= src_data;

reg                         src_ready_not_busy;
reg [SRC_STAGES-1:0]        src_resync_ack;
reg [DEST_STAGES-1:0]       dest_resync_load;
reg                         src_load;
reg                         src_ack_reg;
reg                         src_load_reg;

wire                        src_ack;
wire                        dest_ack;

always @(posedge clk_src or negedge rst_n_src)
    if(!rst_n_src)          src_load <= 1'b0;
    else                    src_load <= src_load ^ next_data_pulse;

always @(posedge clk_src or negedge rst_n_src)
    if(!rst_n_src)                              src_ready_not_busy <= 1'b1;
    else if(src_ready_not_busy && src_write)    src_ready_not_busy <= 1'b0;
    else if(!src_ready_not_busy && src_ack)     src_ready_not_busy <= 1'b1;

assign src_ready            = src_ready_not_busy;
assign next_data_pulse      = src_write & src_ready;

always @(posedge clk_src or negedge rst_n_src)
    if(!rst_n_src)      src_resync_ack <= 'b0;
    else                src_resync_ack <={src_resync_ack[SRC_STAGES-2:0], dest_ack};

always @(posedge clk_src or negedge rst_n_src)
    if(!rst_n_src)      src_ack_reg <= 1'b0;
    else                src_ack_reg <= src_resync_ack[SRC_STAGES-1];

assign src_ack = src_ack_reg ^ src_resync_ack[SRC_STAGES-1];

/********* Destination part *********/
always @(posedge clk_dest or negedge rst_n_dest)
    if(!rst_n_dest)     dest_resync_load <= 'b0;
    else                dest_resync_load <={dest_resync_load[DEST_STAGES-2:0], src_load};

always @(posedge clk_dest or negedge rst_n_dest)
    if(!rst_n_dest)     src_load_reg <= 1'b0;
    else                src_load_reg <= dest_resync_load[DEST_STAGES-1];

assign dest_ack     = src_load_reg;

wire load_enable;

assign load_enable = src_load_reg ^ dest_resync_load[DEST_STAGES-1];

reg [WIDTH-1:0]     dest_reg_out;

always @(posedge clk_dest or negedge rst_n_dest)
    if(!rst_n_dest)         dest_reg_out <= 'b0;
    else if(load_enable)    dest_reg_out <= src_out_reg;

assign dest_data = dest_reg_out;

endmodule

`endif
