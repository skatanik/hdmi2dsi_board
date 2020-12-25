`timescale 1ns/1ps

import axi_vip_pkg::*;
import axi4_slave_vip_pkg::*;

module tb_dsi_host;

wire                 clk_in                  ;
wire                 rst_n_in                ;
    /* DDR */
wire [16-1:0]        mcb3_dram_dq            ;
wire [14-1:0]        mcb3_dram_a             ;
wire [3-1:0]         mcb3_dram_ba            ;
wire                 mcb3_dram_ras_n         ;
wire                 mcb3_dram_cas_n         ;
wire                 mcb3_dram_we_n          ;
wire                 mcb3_dram_odt           ;
wire                 mcb3_dram_reset_n       ;
wire                 mcb3_dram_cke           ;
wire                 mcb3_dram_dm            ;
wire                 mcb3_dram_udqs          ;
wire                 mcb3_dram_udqs_n        ;
wire                 mcb3_rzq                ;
wire                 mcb3_zio                ;
wire                 mcb3_dram_udm           ;

wire                 mcb3_dram_dqs           ;
wire                 mcb3_dram_dqs_n         ;
wire                 mcb3_dram_ck            ;
wire                 mcb3_dram_ck_n          ;
    /* DPHY */
wire [3:0]      dphy_data_hs_out_p      ;
wire [3:0]      dphy_data_hs_out_n      ;
wire [3:0]      dphy_data_lp_out_p      ;
wire [3:0]      dphy_data_lp_out_n      ;
wire            dphy_clk_hs_out_p       ;
wire            dphy_clk_hs_out_n       ;
wire            dphy_clk_lp_out_p       ;
wire            dphy_clk_lp_out_n       ;
    /* HDMI parallel */
reg [24-1:0]   hdmi_data               ;
reg            hdmi_hs                 ;
reg            hdmi_vs                 ;
reg            hdmi_de                 ;
reg            hdmi_clk                ;

    /* I2C ADV */
    /* I2C EEPROM */
    /* LED */
    /* UART */
wire             rxd                     ;
wire             txd                     ;

logic [7:0] video_memory_send [640*480*3-1:0]; //
logic [7:0] video_memory_recv [640*480*3-1:0]; //
integer recv_vid_ind;

initial
begin
    for(int ind = 0; ind < 640*480*3; ind++)
    begin
        video_memory_send[ind] = $urandom_range(0, 8'hff);
        video_memory_recv[ind] = 0;
    end
end

reg r_clk_25;
reg r_rst_n;

assign clk_in       = r_clk_25;
assign rst_n_in     = r_rst_n;

initial
begin
r_clk_25 = 0;
#500
forever
begin
    #20 r_clk_25 = ~r_clk_25;
end
end

initial
begin
hdmi_clk = 0;
#333
forever
begin
    #25 hdmi_clk = ~hdmi_clk;
end
end


initial
begin
r_rst_n = 0;
repeat(1000) @(posedge r_clk_25);
r_rst_n = 1;
end


// 640x480
localparam VS_FULL_SIZE = 740;
localparam VS_FP_SIZE = 50;
localparam VS_BP_SIZE = 50;
localparam HS_FULL_SIZE = 540;
localparam HS_FP_SIZE = 20;
localparam HS_BP_SIZE = 20;
localparam DE_FULL_SIZE = 500;
localparam DE_FP_SIZE = 10;
localparam DE_BP_SIZE = 10;


dsi_host_top dsi_host_top_0(
    /* CLK */
    .clk_in                  (clk_in                ),
    .rst_n_in                (rst_n_in              ),

    .mcb3_dram_dq            (mcb3_dram_dq          ),
    .mcb3_dram_a             (mcb3_dram_a           ),
    .mcb3_dram_ba            (mcb3_dram_ba          ),
    .mcb3_dram_ras_n         (mcb3_dram_ras_n       ),
    .mcb3_dram_cas_n         (mcb3_dram_cas_n       ),
    .mcb3_dram_we_n          (mcb3_dram_we_n        ),
    .mcb3_dram_odt           (mcb3_dram_odt         ),
    .mcb3_dram_reset_n       (mcb3_dram_reset_n     ),
    .mcb3_dram_cke           (mcb3_dram_cke         ),
    .mcb3_dram_dm            (mcb3_dram_dm          ),
    .mcb3_dram_udqs          (mcb3_dram_udqs        ),
    .mcb3_dram_udqs_n        (mcb3_dram_udqs_n      ),
    .mcb3_rzq                (mcb3_rzq              ),
    .mcb3_zio                (mcb3_zio              ),
    .mcb3_dram_udm           (mcb3_dram_udm         ),
    .mcb3_dram_dqs           (mcb3_dram_dqs         ),
    .mcb3_dram_dqs_n         (mcb3_dram_dqs_n       ),
    .mcb3_dram_ck            (mcb3_dram_ck          ),
    .mcb3_dram_ck_n          (mcb3_dram_ck_n        ),
    .rzq3                     (1'b0                 ),
    .zio3                     (1'b0                 ),
    /* DPHY */
    .dphy_data_hs_out_p      (dphy_data_hs_out_p    ),
    .dphy_data_hs_out_n      (dphy_data_hs_out_n    ),
    .dphy_data_lp_out_p      (dphy_data_lp_out_p    ),
    .dphy_data_lp_out_n      (dphy_data_lp_out_n    ),
    .dphy_clk_hs_out_p       (dphy_clk_hs_out_p     ),
    .dphy_clk_hs_out_n       (dphy_clk_hs_out_n     ),
    .dphy_clk_lp_out_p       (dphy_clk_lp_out_p     ),
    .dphy_clk_lp_out_n       (dphy_clk_lp_out_n     ),
    /* HDMI parallel */
    .hdmi_data               (hdmi_data             ),
    .hdmi_hs                 (hdmi_hs               ),
    .hdmi_vs                 (hdmi_vs               ),
    .hdmi_de                 (hdmi_de               ),
    .hdmi_clk                (hdmi_clk              ),

    /* I2C ADV */
    /* I2C EEPROM */
    /* LED */
    /* UART */
    .rxd                     (rxd                   ),
    .txd                     (txd                   )
    /* BUTTON */
    );

integer debug_symbol;

always @(negedge dsi_host_top_0.picorv32_core.clk) begin
    if(dsi_host_top_0.picorv32_core.bus_write) begin
        if(dsi_host_top_0.picorv32_core.bus_addr == 32'h1000_0000) begin
            debug_symbol = dsi_host_top_0.picorv32_core.bus_writedata;
            $display("\nDATA ON DEBUG PORT = %h", debug_symbol);
        end
    end
end


reg hdmi_enable;

initial begin
wait(r_rst_n == 1)
hdmi_enable = 0;
end


always @(posedge dsi_host_top_0.picorv32_core.clk) begin
    if(dsi_host_top_0.picorv32_core.bus_write) begin
        if(dsi_host_top_0.picorv32_core.bus_addr == 32'h1100_0000) begin
            hdmi_enable <= dsi_host_top_0.picorv32_core.bus_writedata[0];
        end
    end
end

reg req_ADDR    [31:0];
reg req_LEN     [7:0];
reg req_SIZE    [31:0];
reg req_BURST   [31:0];
reg req_LOCK    [31:0];
reg req_CACHE   [31:0];
reg req_PROT    [31:0];
reg req_REGION  [31:0];
reg req_QOS     [31:0];
reg req_ARUSER  [31:0];
reg req_IDTAG   [31:0];
integer res;

axi4_slave_vip_slv_t slave_agent;
axi4_slave_vip_slv_t slave_agent_pix_rd;
axi4_slave_vip_slv_t slave_agent_pix_wr;

localparam RAM_MEM_DEPTH = 2**(18);

logic [31:0] ram_memory [RAM_MEM_DEPTH-1:0];
integer ind;

initial
begin
    for(ind = 0; ind < RAM_MEM_DEPTH; ind++)
    begin
        ram_memory[ind] = 0;
    end
end

initial
begin

slave_agent = new("axi4_slave_vip", dsi_host_top_0.slave_ram.inst.IF);
slave_agent_pix_rd = new("axi4_slave_vip_rd", dsi_host_top_0.slave_ro.inst.IF);
slave_agent_pix_wr = new("axi4_slave_vip_wr", dsi_host_top_0.slave_wo.inst.IF);
slave_agent.set_verbosity(400);
// slave_agent_pix_rd.set_verbosity(400);
// slave_agent_pix_wr.set_verbosity(400);
slave_agent.start_slave();
slave_agent_pix_rd.start_slave();
slave_agent_pix_wr.start_slave();

fork
    wr_response();
    rd_response();
    wr_pix_response();
    rd_pix_response();
    hdmi_streamer();
join_none


end

task wr_response();
    // Declare a handle for write response
    axi_transaction                    wr_reactive;
    integer trans_len;
    integer trans_addr;
    integer trans_data;

    forever begin
        // Block till write transaction occurs
        slave_agent.wr_driver.get_wr_reactive (wr_reactive);
        trans_len = wr_reactive.get_len();
        trans_addr = wr_reactive.get_addr();
        trans_data = wr_reactive.get_data_beat(0);
        // $display("\n/********* CPU->RAM AXI WRITE TRANSACTION ********/\n");
        // $display("Len = %d\n", trans_len);
        // $display("Addr = %h\n", trans_addr);
        // $display("Data = %h\n", trans_data);
        // $display("/****************************************/\n");

        ram_memory[trans_addr/4] = trans_data;

        // User fill in write response
        fill_wr_reactive                (wr_reactive);

        // Write driver send response to VIP interface
        slave_agent.wr_driver.send            (wr_reactive);
    end
endtask

task rd_response();
    // Declare a handle for write response
    axi_transaction                    rd_reactive;
    integer trans_len;
    integer trans_addr;
    logic [7:0] trans_data[3:0];
    integer i;
    xil_axi_payload_byte             beat[];

    forever begin
        // Block till write transaction occurs
        slave_agent.rd_driver.get_rd_reactive (rd_reactive);

        trans_len = rd_reactive.get_len();
        trans_addr = rd_reactive.get_addr();

        beat = new[(1<<rd_reactive.get_size())];

        for(i = 0; i < 4; i = i + 1) begin
            beat[i] = ram_memory[trans_addr/4][i*8+:8];
        end

        // $display("\n/********* RAM->CPU AXI READ TRANSACTION ********/\n");
        // $display("Len = %d\n", trans_len);
        // $display("Addr = %h\n", trans_addr);
        // // $display("Read data = %h\n", ram_memory[trans_addr/4]);
        // $display("Read data from ram = %h\n", ram_memory[trans_addr/4]);
        // $display("/****************************************/\n");

        rd_reactive.set_data_beat_unpacked(rd_reactive.get_beat_index(),beat);
        rd_reactive.clr_beat_index();

        rd_reactive.set_beat_delay(0,$urandom_range(0,10));

        // rd_reactive.set_data_beat(0, trans_data, 1, 4'h1111);
        // Write driver send response to VIP interface
        slave_agent.rd_driver.send            (rd_reactive);
    end
endtask

function automatic void fill_wr_reactive(inout axi_transaction t);
    t.set_bresp(XIL_AXI_RESP_OKAY);
    t.set_beat_delay(0,$urandom_range(0,10));
endfunction: fill_wr_reactive

task wr_pix_response();
    // Declare a handle for write response
    axi_transaction                    wr_reactive;
    integer trans_len;
    integer trans_addr;
    logic [31:0] trans_data;
    logic [31:0] given_data;
    integer ind_mem;
    integer ind;
    integer errors_counter;

    forever begin
        // Block till write transaction occurs
        slave_agent_pix_wr.wr_driver.get_wr_reactive (wr_reactive);
        trans_len = wr_reactive.get_len();
        trans_addr = wr_reactive.get_addr();
        // $display("\n/********* HDMI->RAM AXI WRITE TRANSACTION ********/\n");
        // $display("Len = %d\n", trans_len);
        // $display("Addr = %h\n", trans_addr);


        for(ind_mem = 0; ind_mem <= trans_len; ind_mem = ind_mem + 1 ) begin

            trans_data = wr_reactive.get_data_beat(ind_mem);
            // $display("Data = %h\n", trans_data);
            ram_memory[(trans_addr)/4+ind_mem] = trans_data;

            video_memory_recv[(recv_vid_ind)*4+0] = trans_data[8*0+:8];
            video_memory_recv[(recv_vid_ind)*4+1] = trans_data[8*1+:8];
            video_memory_recv[(recv_vid_ind)*4+2] = trans_data[8*2+:8];
            video_memory_recv[(recv_vid_ind)*4+3] = trans_data[8*3+:8];

            given_data[8*0+:8] = video_memory_send[(recv_vid_ind)*4+0];
            given_data[8*1+:8] = video_memory_send[(recv_vid_ind)*4+1];
            given_data[8*2+:8] = video_memory_send[(recv_vid_ind)*4+2];
            given_data[8*3+:8] = video_memory_send[(recv_vid_ind)*4+3];

            // errors_counter = 0;

            // for(ind = 0; ind < 4; ind = ind + 1) begin
            //     if(video_memory_recv[(recv_vid_ind)*4+ind] != video_memory_send[(recv_vid_ind)*4+ind])
            //     begin
            //         errors_counter = errors_counter + 1;
            //     end
            // end

            if(given_data !== trans_data) begin
                $display("Compare data error on addr %d\n", recv_vid_ind*4);
                $display("%h != %h\n", given_data, trans_data);
                $stop();
            end

            // if(errors_counter == 0)
            //     $display("Data check OK\n");

            recv_vid_ind = recv_vid_ind + 1;

        end
        // $display("/****************************************/\n");

        // User fill in write response
        fill_wr_reactive                (wr_reactive);

        // Write driver send response to VIP interface
        slave_agent_pix_wr.wr_driver.send            (wr_reactive);
    end
endtask

task rd_pix_response();
    // Declare a handle for write response
    axi_transaction                    rd_reactive;
    integer trans_len;
    integer trans_addr;
    logic [7:0] trans_data[3:0];
    integer i;

    forever begin
        // Block till write transaction occurs
        slave_agent_pix_rd.rd_driver.get_rd_reactive (rd_reactive);

        trans_len = rd_reactive.get_len();
        trans_addr = rd_reactive.get_addr();

        // $display("\n/********* RAM->DSI AXI READ TRANSACTION ********/\n");
        // $display("Len = %d\n", trans_len);
        // $display("Addr = %h\n", trans_addr);
        // $display("Read data = %h\n", ram_memory[trans_addr/4]);

        for(int ind_1 = 0; ind_1 <= trans_len; ind_1++) begin
            for(i = 0; i < 4; i++) begin
                trans_data[3-i] = ram_memory[trans_addr/4+ind_1][i*8+:8];
            end
            rd_reactive.set_data_beat_unpacked(rd_reactive.get_beat_index(),trans_data);
            rd_reactive.increment_beat_index();
            rd_reactive.set_beat_delay(ind_1,0); // $urandom_range(0,10)
        end

        // $display("/****************************************/\n");


        rd_reactive.clr_beat_index();



        // rd_reactive.set_data_beat(0, trans_data, 1, 4'h1111);
        // Write driver send response to VIP interface
        slave_agent_pix_rd.rd_driver.send            (rd_reactive);
    end
endtask

integer vid_trn_num;

task hdmi_streamer();

    integer vs_counter;
    integer hs_counter;
    integer de_counter;

    vs_counter = 0;
    hs_counter = 0;
    de_counter = 0;
    vid_trn_num = 0;

    forever begin
        repeat(1) @(posedge hdmi_clk);
        if(hdmi_enable)
        begin

            if(hs_counter == HS_FULL_SIZE) begin
                hs_counter = 0;
                de_counter = 0;
                if(vs_counter == VS_FULL_SIZE)
                begin
                    vs_counter = 0;
                    vid_trn_num = 0;
                    recv_vid_ind = 0;
                    check_hdmi_ram_mem();
                end
                else
                    vs_counter = vs_counter + 1;
            end
            else begin
                hs_counter = hs_counter + 1;
                de_counter = de_counter + 1;
            end

            if(hs_counter >= HS_FP_SIZE && (hs_counter < HS_FULL_SIZE - HS_BP_SIZE))
                hdmi_hs = 1;
            else
                hdmi_hs = 0;

            if((hs_counter >= HS_FP_SIZE+DE_FP_SIZE) && (hs_counter < HS_FULL_SIZE - DE_BP_SIZE - HS_BP_SIZE) && hdmi_vs)
                hdmi_de = 1;
            else
                hdmi_de = 0;

            if(vs_counter >= VS_FP_SIZE && (vs_counter < VS_FULL_SIZE - VS_BP_SIZE))
                hdmi_vs = 1;
            else
                hdmi_vs = 0;

            if(hdmi_de == 1) begin
                hdmi_data[7:0] = video_memory_send[vid_trn_num*3+0];
                hdmi_data[15:8] = video_memory_send[vid_trn_num*3+1];
                hdmi_data[23:16] = video_memory_send[vid_trn_num*3+2];
                vid_trn_num = vid_trn_num + 1;
            end
            else
                hdmi_data = 0;

        end
        else begin
            hdmi_data = 0;
            hdmi_hs = 0;
            hdmi_vs = 0;
            hdmi_de = 0;
            vid_trn_num = 0;
            recv_vid_ind = 0;
        end


    end
endtask

function automatic void check_hdmi_ram_mem();
    integer ind;
    integer error_count;
    error_count = 0;
    for(ind = 0; ind < 640*480*3; ind = ind + 1)
    begin
        if(video_memory_recv[ind] !== video_memory_send[ind])
        begin
            if(error_count < 10)
                $display("\nCompare data error on addr %d", ind);
            error_count = error_count + 1;
        end
    end

    $display("\nCompare data errors number %d", error_count);
    if(error_count == 0)
        $display("\n HDMI-> RAM Test Passed");
    else
        $display("\n HDMI-> RAM Test Failed");

    // $stop();

endfunction

typedef enum {
    DSI_STATE_LP01_WAIT,
    DSI_STATE_LP00_WAIT,
    DSI_STATE_SYNC_WAIT,
    DSI_STATE_BYTE_WAIT,
    DSI_STATE_DATA_RECV,
    DSI_STATE_CRC_WAIT,
    DSI_STATE_EOT_WAIT
} dsi_lane_recv_states_td;

mailbox lane_mailbox[3:0];

initial
begin
    for(int ind = 0; ind < 4; ind++)
        lane_mailbox[ind] = new();

    fork
        dsi_receiver_lane(0);
        dsi_receiver_lane(1);
        dsi_receiver_lane(2);
        dsi_receiver_lane(3);
        dsi_receiver_checker();
    join_none
end

task automatic dsi_receiver_lane;
    input integer task_ind;

    dsi_lane_recv_states_td current_state;
    logic [1:0] lp_lanes;
    logic [7:0] data_byte;
    logic first_byte;
    logic last_byte;

    current_state = DSI_STATE_LP01_WAIT;
    lp_lanes = 2'b0;
    data_byte = 0;
    first_byte  = 0;
    last_byte   = 0;

    forever begin
        repeat(1) @(posedge dsi_host_top_0.dsi_phy_clk);


        lp_lanes = {dsi_host_top_0.dsi_tx_top_0.LP_p_output[task_ind], dsi_host_top_0.dsi_tx_top_0.LP_n_output[task_ind]};
        data_byte = dsi_host_top_0.dsi_tx_top_0.hs_lane_output_bus[task_ind*8+:8];

        case (current_state)
            DSI_STATE_LP01_WAIT:
                current_state = lp_lanes == 2'b01 ? DSI_STATE_LP00_WAIT : DSI_STATE_LP01_WAIT;
            DSI_STATE_LP00_WAIT:
                current_state = lp_lanes == 2'b00 ? DSI_STATE_SYNC_WAIT : DSI_STATE_LP00_WAIT;
            DSI_STATE_SYNC_WAIT: begin
                first_byte = (data_byte == 8'h1D);
                if(first_byte) begin
                    current_state = DSI_STATE_BYTE_WAIT;
                    // $display("Lane %d SYNC received\n",task_ind);
                end else
                    current_state = DSI_STATE_SYNC_WAIT;
            end
            DSI_STATE_BYTE_WAIT: begin
                last_byte = (lp_lanes == 2'b11);
                if(last_byte)
                    // $display("Last Byte on lane %d received\n",task_ind);
                // $display("Byte %h on lane %d received, flags %b\n",data_byte,task_ind, {first_byte, last_byte});
                current_state = last_byte ? DSI_STATE_LP01_WAIT : DSI_STATE_BYTE_WAIT;
                lane_mailbox[task_ind].put({first_byte, last_byte, data_byte});
                first_byte = 0;
                last_byte = 0;
            end
        endcase

    end
endtask

logic [7:0] dsi_recv_array [2048-1:0];

task dsi_receiver_checker();

    logic [31:0] recv_word;
    logic [9:0] recv_chunk;
    logic [7:0] recv_chunk_inv;

    logic wait_first_chunk;
    logic wait_last_chunk;
    integer first_chunk_counter;
    integer last_chunk_counter;
    integer bytes_counter;
    integer words_counter;
    logic [1:0] lp_lanes;

    wait_first_chunk = 1;
    wait_last_chunk = 0;
    first_chunk_counter = 0;
    last_chunk_counter = 0;

    bytes_counter = 0;
    words_counter = 0;

    forever
    begin
        repeat(1) @(negedge dsi_host_top_0.dsi_phy_clk);

        lane_mailbox[0].peek(recv_chunk);

        for(int ind = 0; ind < 4; ind++) begin
            lp_lanes = {dsi_host_top_0.dsi_tx_top_0.LP_p_output[ind], dsi_host_top_0.dsi_tx_top_0.LP_n_output[ind]};
            if(lp_lanes == 2'b00)
            begin
                lane_mailbox[ind].get(recv_chunk);
                // $display("Got %h chunk\n",recv_chunk);

                for(int k=0; k < 8; k++)
                    recv_chunk_inv[k] = recv_chunk[7-k];

                dsi_recv_array[words_counter+ind] = recv_chunk_inv;
                bytes_counter = bytes_counter + 1;

                if(bytes_counter == 4)
                begin
                    bytes_counter = 0;
                    words_counter = words_counter + 4;
                end

                if(recv_chunk[9]) begin
                    first_chunk_counter = first_chunk_counter + 1;
                    // $display("First chunk counter = %d\n",first_chunk_counter);
                end

                if(recv_chunk[8]) begin
                    last_chunk_counter = last_chunk_counter + 1;
                    // $display("Last chunk counter = %d\n",last_chunk_counter);
                end

            end
        end

        if(wait_first_chunk)
            if(first_chunk_counter != 4)
            begin
                $display("Only %d sync received", first_chunk_counter);
                $error();
                $stop();
            end else begin
                wait_first_chunk = 0;
                wait_last_chunk = 1;
                first_chunk_counter = 0;
                last_chunk_counter = 0;
            end
        else if(last_chunk_counter == 4 && wait_last_chunk)
        begin
            last_chunk_counter = 0;
            wait_last_chunk = 0;
            wait_first_chunk = 1;
            first_chunk_counter = 0;
            $display("Data packet received. Checking...");
            dsi_data_check();
            bytes_counter = 0;
            words_counter = 0;
        end

    end

endtask

localparam [5:0] PT_SHORT_1 = 6'h01;
localparam [5:0] PT_SHORT_2 = 6'h11;
localparam [5:0] PT_SHORT_3 = 6'h21;
localparam [5:0] PT_SHORT_4 = 6'h31;
localparam [5:0] PT_SHORT_5 = 6'h07;
localparam [5:0] PT_SHORT_6 = 6'h08;
localparam [5:0] PT_SHORT_7 = 6'h02;
localparam [5:0] PT_SHORT_8 = 6'h12;
localparam [5:0] PT_SHORT_9 = 6'h22;
localparam [5:0] PT_SHORT_10 = 6'h32;

localparam [5:0] PT_LONG_1 = 6'h3E;

integer dsi_checker_data_pointer;
integer dsi_vertical_counter;

function automatic void dsi_data_check();

integer data_length;
logic [7:0] byte_from_ram;
logic [31:0] word_from_ram;
logic [7:0] byte_from_dsi;
integer error_counter;

data_length = 0;
error_counter = 0;

    case(dsi_recv_array[0])
    PT_SHORT_1:
        begin
            $display("Received packet type PT_SHORT_1");
            dsi_checker_data_pointer = 0;
            dsi_vertical_counter = 0;
        end
    PT_SHORT_2:
        begin
            $display("Received packet type PT_SHORT_2");
        end
    PT_SHORT_3:
        begin
            $display("Received packet type PT_SHORT_3");
        end
    PT_SHORT_4:
        begin
            $display("Received packet type PT_SHORT_4");
        end
    PT_SHORT_5:
        begin
            $display("Received packet type PT_SHORT_5");
        end
    PT_SHORT_6:
        begin
            $display("Received packet type PT_SHORT_6");
        end
    PT_SHORT_7:
        begin
            $display("Received packet type PT_SHORT_7");
        end
    PT_SHORT_8:
        begin
            $display("Received packet type PT_SHORT_8");
        end
    PT_SHORT_9:
        begin
            $display("Received packet type PT_SHORT_9");
        end
    PT_SHORT_10:
        begin
            $display("Received packet type PT_SHORT_10");
        end
    PT_LONG_1:
        begin
            $display("Received packet type PT_LONG_1. Line %d", dsi_vertical_counter);
            data_length = {dsi_recv_array[2], dsi_recv_array[1]};
            $display("Packet size %d", data_length);
            for(int ind = 0; ind < data_length; ind=ind+4)
            begin
                word_from_ram = ram_memory[(24'h10000>>2) + dsi_checker_data_pointer];
                // $display("%h", word_from_ram);
                for(int k = 0; k < 4; k++) begin
                    byte_from_ram = word_from_ram[k*8+:8];
                    byte_from_dsi = dsi_recv_array[4+ind+k];
                    if(byte_from_dsi !== byte_from_ram)
                    begin
                        $display("Error on DSI checker on addr %d", (4+ind+k));
                        $display("%h %h", byte_from_dsi, byte_from_ram);
                        if(error_counter > 10)
                            $stop();
                        error_counter = error_counter + 1;
                    end
                end
                dsi_checker_data_pointer = dsi_checker_data_pointer + 1;
            end
            dsi_vertical_counter = dsi_vertical_counter + 1;
            $display("Packet checking done. Great success!");
        end
    default:
            $display("Unknown packet type");
    endcase

    $display("\n");

endfunction

endmodule