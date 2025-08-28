module axi_slave #(
    C_AXI_DATA_WIDTH = 32,
    C_AXI_ADDR_WIDTH = 4
)
(
    input	wire			i_clk,	// System clock
	input	wire			i_axi_reset_n,

// AXI write address channel signals
	input	wire			i_axi_awready,//Slave is ready to accept
	input	wire	[C_AXI_ADDR_WIDTH-1:0]	i_axi_awaddr,	// Write address
	input	wire	[3:0]		i_axi_awcache,	// Write Cache type
	input	wire	[2:0]		i_axi_awprot,	// Write Protection type
	input	wire			i_axi_awvalid,	// Write address valid

// AXI write data channel signals
	input	wire			i_axi_wready,  // Write data ready
	input	wire	[C_AXI_DATA_WIDTH-1:0]	i_axi_wdata,	// Write data
	input	wire	[C_AXI_DATA_WIDTH/8-1:0]	i_axi_wstrb,	// Write strobes
	input	wire			i_axi_wvalid,	// Write valid

// AXI write response channel signals
	input	wire	[1:0]		i_axi_bresp,	// Write response
	input	wire			i_axi_bvalid,  // Write reponse valid
	input	wire			i_axi_bready,  // Response ready

// AXI read address channel signals
	input	wire			i_axi_arready,	// Read address ready
	input	wire	[C_AXI_ADDR_WIDTH-1:0]	i_axi_araddr,	// Read address
	input	wire	[3:0]		i_axi_arcache,	// Read Cache type
	input	wire	[2:0]		i_axi_arprot,	// Read Protection type
	input	wire			i_axi_arvalid,	// Read address valid

// AXI read data channel signals
	input	wire	[1:0]		i_axi_rresp,   // Read response
	input	wire			i_axi_rvalid,  // Read reponse valid
	input	wire	[C_AXI_DATA_WIDTH-1:0]	i_axi_rdata,   // Read data
	input	wire			i_axi_rready,  // Read Response ready
);


endmodules