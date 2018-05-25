//////////////////////////////////////////////////////////////////////////////
// module_top.sv - Checks functionality of Gumnut CPU
//
// Lead Author:			Jonathan Anchell
// Version:			1.1
// Last modified:		25-May-2018
//
/////////////////////////////////////////////////////////////////////////////


module module_top();
	
	logic clk_i;
	logic rst_i;
    	
	// We do not do any i/o port testing.  These
	// signals are included simply so we have all
	// the signals needed to instantiate Gumnut
	logic port_cyc_o;
	logic port_stb_o;
	logic port_we_o;
	logic port_ack_i;
	logic [7:0] port_adr_o;
	logic [7:0] port_dat_o;
	logic [7:0] port_dat_i;

	// We do not do any interrupt testing.  These
	// signals are included simply so we have all
	// the signals needed to instantiate Gumnut
	logic int_req;
	logic int_ack;

	parameter debug = 1'b0; // set to 1 to debug Gumnut

	// instruction memory bus
	wire        inst_cyc_o;
	wire        inst_stb_o;
	wire        inst_ack_i;
	wire [11:0] inst_adr_o;
	wire [17:0] inst_dat_i;
	
	// data memory bus
	wire        data_cyc_o;
	wire        data_stb_o;
	wire        data_we_o;
	wire        data_ack_i;
	wire  [7:0] data_adr_o;
	wire  [7:0] data_dat_o;
	wire  [7:0] data_dat_i;

	initial begin // reset generator
		rst_i = 1'b1;
		#(25) rst_i = 1'b0;
	end
	
	initial begin // initialize signals
		port_ack_i = 1'b0;
		port_dat_i = 1'b0;
	end


	always begin // clock generator
		clk_i = 1'b1; #(5);
		clk_i = 1'b0; #(5);
	end

	
	// replace instruction memory
	logic [17:0] inst_dat_i_reg;
	assign inst_dat_i = inst_dat_i_reg;
	assign inst_ack_i = inst_cyc_o & inst_stb_o;

//*************************************************************************************************************
//*********************************************************************************************************
	initial begin
		$display("starting test");
		
		#500
		inst_dat_i_reg = 12'b0000_1000_0000_1010;
		$display("inst_dat_i_reg: %b", inst_dat_i_reg);
		#50
		$display("inst_dat_i: %b", inst_dat_i);
		
		#500
		$display ("value of register 1 is %b", core.GPR[1]);
			

		$stop;
	end

	gumnut
	#(.debug(debug))
	core( 
		.clk_i(clk_i),
		.rst_i(rst_i),
		.inst_cyc_o(inst_cyc_o),
		.inst_stb_o(inst_stb_o),
		.inst_ack_i(inst_ack_i),
		.inst_adr_o(inst_adr_o),
		.inst_dat_i(inst_dat_i),
		.data_cyc_o(data_cyc_o),
		.data_stb_o(data_stb_o),
		.data_we_o(data_we_o),
		.data_ack_i(data_ack_i),
		.data_adr_o(data_adr_o),
		.data_dat_o(data_dat_o),
		.data_dat_i(data_dat_i), 
		.port_cyc_o(port_cyc_o),
		.port_stb_o(port_stb_o),
		.port_we_o(port_we_o),
		.port_ack_i(port_ack_i),
		.port_adr_o(port_adr_o), 
		.port_dat_o(port_dat_o), 
		.port_dat_i(port_dat_i), 
		.int_req(int_req),
		.int_ack(int_ack)
	);
/*
	inst_mem core_inst_mem (
		.clk_i(clk_i),
		.cyc_i(inst_cyc_o),
		.stb_i(inst_stb_o),
		.ack_o(inst_ack_i),
		.adr_i(inst_adr_test),
		.dat_o(inst_dat_i) 
	);
	*/
	data_mem core_data_mem(
		.clk_i(clk_i),
		.cyc_i(data_cyc_o),
      		.stb_i(data_stb_o),
      		.we_i(data_we_o),
      		.ack_o(data_ack_i),
      		.adr_i(data_adr_o),
      		.dat_i(data_dat_o),
      		.dat_o(data_dat_i) );

	


endmodule