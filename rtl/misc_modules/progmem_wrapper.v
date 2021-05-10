module progmem_wrapper(
    //* system signals
    input  wire                     clk                     ,
    input  wire                     rst_n                   ,

    //* system interface
`ifdef SPARTAN7
    input   wire [11:0]             ctrl_address            ,
`else
    input   wire [11:0]              ctrl_address            ,
`endif

    input   wire                    ctrl_read               ,
    output  wire [31:0]             ctrl_readdata           ,
    output  wire [1:0]              ctrl_response           ,

    input   wire                    ctrl_write              ,
    input   wire  [31:0]            ctrl_writedata          ,

    output  wire                    ctrl_waitrequest
);

assign ctrl_response = 0;

reg[1:0] r_ctrl_waitrequest;

assign ctrl_waitrequest = ctrl_read && !r_ctrl_waitrequest[1];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  r_ctrl_waitrequest <= 2'b0;
    else if(ctrl_read)                          r_ctrl_waitrequest <= {r_ctrl_waitrequest[0], 1'b1};
    else if(r_ctrl_waitrequest[1])              r_ctrl_waitrequest <= 2'b0;
end

`ifdef SPARTAN7
prgr_rom_s7 prgr_rom_0(
  .clka     (clk),
  .rsta     (!rst_n),
  .addra    ({20'b0, ctrl_address}),
  .douta    (ctrl_readdata),
  .dina     (ctrl_writedata),
  .wea      (ctrl_write)
  );

`else

prgr_rom prgr_rom_0 (
  .clka(clk), // input clka
//   .ena(1'b1), // input ena
  .addra({20'b0, ctrl_address}), // input [31 : 0] addra
  .douta(ctrl_readdata), // output [31 : 0] douta
  .dina     (ctrl_writedata),
  .wea      (ctrl_write)
);

`endif
endmodule