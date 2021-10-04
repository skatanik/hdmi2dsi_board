module progmem_wrapper(
    //* system signals
    input  wire                     clk                     ,
    input  wire                     rst_n                   ,

    //* system interface
`ifdef SPARTAN7
    input   wire [11:0]             ctrl_address            ,
`else
    input   wire [13:0]              ctrl_address            , // 16K memory space
`endif

    input   wire                    ctrl_read               ,
    output  wire [31:0]             ctrl_readdata           ,
    output  wire [1:0]              ctrl_response           ,

    input   wire                    ctrl_write              ,
    input   wire  [3:0]             ctrl_byteenable              ,
    input   wire  [31:0]            ctrl_writedata          ,

    output  wire                    ctrl_waitrequest
);

assign ctrl_response = 0;

reg[6:0] r_ctrl_waitrequest;

assign ctrl_waitrequest = (ctrl_read || ctrl_write) && !(r_ctrl_waitrequest[6]);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  r_ctrl_waitrequest <= 7'b0;
    else if(ctrl_read || ctrl_write)            r_ctrl_waitrequest <= {r_ctrl_waitrequest[5:0], 1'b1};
    else if(r_ctrl_waitrequest[6])              r_ctrl_waitrequest <= 7'b0;
end

`ifdef SPARTAN7
prgr_rom prgr_rom_0(
  .clka     (clk),
  .rsta     (!rst_n),
  .addra    ({20'b0, ctrl_address}),
  .douta    (ctrl_readdata),
  .dina     (ctrl_writedata),
  .wea      (ctrl_byteenable & {4{ctrl_write}})
  );

`else

prgr_rom prgr_rom_0 (
  .clka(clk), // input clka
  .rsta     (!rst_n),
//   .ena(1'b1), // input ena
  .addra({18'b0, ctrl_address}), // input [31 : 0] addra
  .douta(ctrl_readdata), // output [31 : 0] douta
  .dina     (ctrl_writedata),
  .wea      (ctrl_byteenable & {4{ctrl_write}})
);
// prgr_rom prgr_rom_0 (
//   .a(ctrl_address[9:2]),
//   .d(ctrl_writedata),
//   .clk(clk),
//   .we(ctrl_write),
//   .qspo_rst(!rst_n),
//   .qspo(ctrl_readdata)
// );


`endif
endmodule