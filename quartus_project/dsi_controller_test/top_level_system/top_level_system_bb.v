
module top_level_system (
	clk_clk,
	dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_p,
	dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_n,
	dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_p,
	dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_n,
	dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_p,
	dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_n,
	dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_p,
	dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_n,
	reset_reset_n,
	altpll_0_areset_conduit_export);	

	input		clk_clk;
	output	[3:0]	dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_p;
	output	[3:0]	dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_n;
	output	[3:0]	dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_p;
	output	[3:0]	dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_n;
	output		dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_p;
	output		dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_n;
	output		dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_p;
	output		dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_n;
	input		reset_reset_n;
	input		altpll_0_areset_conduit_export;
endmodule
