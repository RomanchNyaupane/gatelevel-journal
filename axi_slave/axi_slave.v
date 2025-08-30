module axi_slave #(
    C_AXI_DATA_WIDTH = 32,
    C_AXI_ADDR_WIDTH = 2
)
(
    input	wire			i_clk,	// System clock
	input	wire			i_axi_reset_n,

// AXI write address channel signals
	output	wire								i_axi_awready,  //Slave is ready to accept
	input	wire	[C_AXI_ADDR_WIDTH-1:0]		i_axi_awaddr,	// Write address
	input	wire	[2:0]						i_axi_awprot,	// Write Protection type
	input	wire								i_axi_awvalid,	// Write address valid

// AXI write data channel signals
	output	wire								i_axi_wready,   // Write data ready
	input	wire	[C_AXI_DATA_WIDTH-1:0]		i_axi_wdata,	// Write data
	input	wire	[C_AXI_DATA_WIDTH/8-1:0]	i_axi_wstrb,	// Write strobes
	input	wire								i_axi_wvalid,	// Write valid

// AXI write response channel signals
	input	wire	[1:0]		i_axi_bresp,	// Write response
	input	wire				i_axi_bvalid,  	// Write reponse valid
	input	wire				i_axi_bready,  	// Response ready

// AXI read address channel signals
	output	wire								i_axi_arready,	// Read address ready
	input	wire	[C_AXI_ADDR_WIDTH-1:0]		i_axi_araddr,	// Read address
	input	wire	[3:0]						i_axi_arcache,	// Read Cache type
	input	wire	[2:0]						i_axi_arprot,	// Read Protection type
	input	wire								i_axi_arvalid,	// Read address valid

// AXI read data channel signals
	input	wire	[1:0]						i_axi_rresp,   // Read response
	input	wire								i_axi_rvalid,  // Read reponse valid
	output	wire	[C_AXI_DATA_WIDTH-1:0]		i_axi_rdata,   // Read data
	input	wire								i_axi_rready,  // Read Response ready

	output	reg	[(F_LGDEPTH-1):0]	f_axi_rd_outstanding,
	output	reg	[(F_LGDEPTH-1):0]	f_axi_wr_outstanding,
	output	reg	[(F_LGDEPTH-1):0]	f_axi_awr_outstanding
);

function [C_AXI_DATA_WIDTH-1:0]	apply_wstrb;
	input	[C_AXI_DATA_WIDTH-1:0]		prior_data;
	input	[C_AXI_DATA_WIDTH-1:0]		new_data;
	input	[C_AXI_DATA_WIDTH/8-1:0]	wstrb;

	integer	k;
	for(k=0; k<C_AXI_DATA_WIDTH/8; k=k+1)
	begin
		apply_wstrb[k*8 +: 8] = wstrb[k] ? new_data[k*8 +: 8] : prior_data[k*8 +: 8];
	end
endfunction

parameter REGISTER_WIDTH = 32, REGISTWER_NUM = 4;

wire reset;
wire axi_ard_req, axi_awr_req, axi_wr_req, axi_rd_ack, axi_wr_ack;

reg [REGISTER_WIDTH-1:0] reg_0, reg_1, reg_2, reg_3;

reg [31:0] axil_rdata;
reg [3:0] wait_counter_read, wait_counter_write;
reg busy;

// output is combinational
assign i_axi_rdata = axil_rdata;

assign reset = !i_axi_reset_n;

assign axi_ard_req = i_axi_arvalid && i_axi_arready;	//read address request
assign axi_awr_req = i_axi_awvalid && i_axi_awready;	//write address request
assign axi_wr_req  = i_axi_wvalid  && i_axi_wready;		//write data request
assign axi_rd_ack  = i_axi_rvalid  && i_axi_rready;		//read data acknowledge
assign axi_wr_ack  = i_axi_bvalid  && i_axi_bready;		//write response acknowledge

//strobe write data
assign wskd_data = i_axi_wdata;
assign wskd_strb = i_axi_wstrb;

// write strobe data after applying wstrb
assign	wskd_r0 = apply_wstrb(reg_0, wskd_data, wskd_strb);
assign	wskd_r1 = apply_wstrb(reg_1, wskd_data, wskd_strb);
assign	wskd_r2 = apply_wstrb(reg_2, wskd_data, wskd_strb);
assign	wskd_r3 = apply_wstrb(reg_3, wskd_data, wskd_strb);

// write address channel
always @(posedge i_clk) begin
	if (reset) begin
		reg_0 <= 0;
		reg_1 <= 0;
		reg_2 <= 0;
		reg_3 <= 0;
		wait_counter <= 0;
		busy <= 0;
	end else begin
		if (axi_awr_req && axi_wr_req && !busy) begin
		busy <= 1;
		i_axi_bvalid <= 1;
			case (i_axi_awaddr)
				2'b00: reg_0 <= wskd_r0;
				2'b01: reg_1 <= wskd_r1;
				2'b10: reg_2 <= wskd_r2;
				2'b11: reg_3 <= wskd_r3;
				default: {};
			endcase
		end else begin busy <= 0; i_axi_bvalid <= 0; end
		end
end

// read address channel
always @(posedge i_clk) begin
	if (reset) begin
		reg_0 <= 0;
		reg_1 <= 0;
		reg_2 <= 0;
		reg_3 <= 0;
		wait_counter <= 0;	
		busy <= 0;
	end else begin
		if (axi_ard_req && && !busy) begin
		busy <= 1;
		i_axi_rvalid <= 1;
			case (i_axi_awaddr)
				2'b00: axil_rdata <= reg_0;
				2'b01: axil_rdata <= reg_1;
				2'b10: axil_rdata <= reg_2;
				2'b11: axil_rdata <= reg_3;
				default: {};
			endcase
		end else begin busy <= 0; i_axi_rvalid <= 0; end
		end
end

//trigger acknowledge signals
always @(posedge i_clk) begin
		if (reset) begin
		reg_0 <= 0;
		reg_1 <= 0;
		reg_2 <= 0;
		reg_3 <= 0;
		wait_counter <= 0;
		busy <= 0;
	end else begin
		if(i_axi_awvalid && !busy) begin	// trigger write address ready
			i_axi_awready <= 1;
		end else i_axi_awready <= 0;
		if(i_axi_arvalid && !busy) begin	// trigger read address ready
			i_axi_arready <= 1;
		end else i_axi_arready <= 0;
		if(i_axi_wvalid && !busy) begin
			i_axi_wready <= 1;				// trigger write data ready
		end else i_axi_wready <= 0;
	end
end

endmodule