module axi_slave #(
    C_AXI_DATA_WIDTH = 32,
    C_AXI_ADDR_WIDTH = 2
)
(
    input	wire			i_clk,	// System clock
	input	wire			i_axi_reset_n,

// AXI write address channel signals
	output	reg								    i_axi_awready,  //Slave is ready to accept
	input	wire	[C_AXI_ADDR_WIDTH-1:0]		i_axi_awaddr,	// Write address
	input	wire	[2:0]						i_axi_awprot,	// Write Protection type
	input	wire								i_axi_awvalid,	// Write address valid

// AXI write data channel signals
	output	reg								    i_axi_wready,   // Write data ready
	input	wire	[C_AXI_DATA_WIDTH-1:0]		i_axi_wdata,	// Write data
	input	wire	[C_AXI_DATA_WIDTH/8-1:0]	i_axi_wstrb,	// Write strobes
	input	wire								i_axi_wvalid,	// Write valid

// AXI write response channel signals
	output	wire	[1:0]		i_axi_bresp,	// Write response
	output	reg				i_axi_bvalid,  	// Write reponse valid
	input	wire				i_axi_bready,  	// Response ready

// AXI read address channel signals
	output	reg								    i_axi_arready,	// Read address ready
	input	wire	[C_AXI_ADDR_WIDTH-1:0]		i_axi_araddr,	// Read address
	input	wire	[3:0]						i_axi_arcache,	// Read Cache type
	input	wire	[2:0]						i_axi_arprot,	// Read Protection type
	input	wire								i_axi_arvalid,	// Read address valid

// AXI read data channel signals
	output	wire	[1:0]						i_axi_rresp,   // Read response
	output	reg								    i_axi_rvalid,  // Read reponse valid
	output	reg	[C_AXI_DATA_WIDTH-1:0]		    i_axi_rdata,   // Read data
	input	wire								i_axi_rready   // Read Response ready
	
	//output reg read_active, write_active
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
wire [C_AXI_DATA_WIDTH-1:0] wskd_data, wskd_r0, wskd_r1, wskd_r2, wskd_r3;
wire [C_AXI_DATA_WIDTH/8-1:0] wskd_strb;

reg [REGISTER_WIDTH-1:0] reg_0, reg_1, reg_2, reg_3;
reg [C_AXI_ADDR_WIDTH-1:0] write_addr, read_addr;
reg rd_addr_ready, wr_addr_ready;
reg read_ready, write_ready;
reg read_complete, write_complete;

reg [31:0] axil_rdata;
reg [3:0] wait_counter;
reg read_busy, write_busy, timeout;
wire busy;


assign reset = !i_axi_reset_n;

assign busy = read_busy || write_busy;

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
	if (!i_axi_reset_n) begin
		reg_0 <= 0;
		reg_1 <= 0;
		reg_2 <= 0;
		reg_3 <= 0;
		wait_counter <= 0;
		write_busy <= 0;
		read_busy <= 0;
		timeout <= 0;
	end else begin
		if (wr_addr_ready & !(read_busy | write_busy) & i_axi_wvalid & write_ready) begin
		write_busy <= 1;
		
		i_axi_bvalid <= 1;
		i_axi_awready <= 0;
		i_axi_wready <= 1;
		
		write_ready <= 0;
		wr_addr_ready <= 0;
		
		write_complete <= 1;
		//write_active <= 1;
			case (write_addr)
				2'b00: reg_0 <= wskd_r0;
				2'b01: reg_1 <= wskd_r1;
				2'b10: reg_2 <= wskd_r2;
				2'b11: reg_3 <= wskd_r3;
			endcase
		end else begin 
			write_busy <= 0;
			i_axi_bvalid <= 0;
			//write_active <= 0;
			i_axi_wready <= 0;
		end
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
		write_busy <= 0;
		read_busy <= 0;
		timeout <= 0;
	end else begin
		if (rd_addr_ready & !(read_busy | write_busy) & read_ready) begin
		read_busy <= 1;
		read_complete <= 1;
		//read_active <= 1;
			case (read_addr)
				2'b00: axil_rdata <= reg_0;
				2'b01: axil_rdata <= reg_1;
				2'b10: axil_rdata <= reg_2;
				2'b11: axil_rdata <= reg_3;
			endcase
		end else begin
			read_busy <= 0;
			i_axi_rvalid <= 0;
			//read_active <= 0;
		end
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
		write_busy <= 0;
		read_busy <= 0;
		timeout <= 0;
	end else begin
		if(i_axi_awvalid & !busy & !timeout) begin	// trigger write address ready
			write_addr <= i_axi_awaddr;
			wr_addr_ready <= 1;
			i_axi_awready <= 1;
		end else begin i_axi_awready <= 0;  end
		if(i_axi_arvalid & !busy & !timeout) begin	// trigger read address ready
		    read_addr <= i_axi_araddr;
		    rd_addr_ready <= 1;
			i_axi_arready <= 1;
			read_ready <= 1;
		end else i_axi_arready <= 0;
		if(i_axi_wvalid & !busy & !timeout) begin
			write_ready <= 1;				            // trigger write data ready
		end// else i_axi_wready <= 0;
	end
end

//wait counter
always @(posedge i_clk) begin
	if (reset) begin
		reg_0 <= 0;
		reg_1 <= 0;
		reg_2 <= 0;
		reg_3 <= 0;
		wait_counter <= 0;
		read_busy <= 0;
		write_busy <= 0;
		timeout <= 0;
	end else begin
		if(busy) wait_counter <= wait_counter + 1;
		else wait_counter <= 0;
		if(wait_counter == 12) timeout <= 1;
		else timeout <= 0;
		
		if(write_complete) begin
		  write_complete<=0;
		  i_axi_bvalid <= 1;
		end
		else i_axi_bvalid <= 0;
		
		if(read_complete) begin
		  read_complete <= 0;
		  i_axi_rvalid <= 1;
		end else i_axi_rvalid <= 0;
end
end

always @ (*) // output is combinational
    i_axi_rdata = axil_rdata;
endmodule