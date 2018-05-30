// adapted from code by: Sameer Ghewari, Portland State University

import xtlm_pkg::*; // For trans-language TLM channels.
`include "config.v"

// instruction types
localparam add_imm = 4'b0000;
localparam add_carry = 4'b1110;
localparam add_imm_carry = 4'b0001;
localparam sub = 4'b1110;
localparam sub_imm = 4'b0010;
localparam sub_carry = 4'b1110;
localparam sub_imm_carry = 4'b0011;
localparam logic_and = 4'b1110;
localparam logic_imm_and = 4'b0100;
localparam logic_or = 4'b1110;
localparam logic_imm_or = 4'b0101;
localparam logic_xor = 4'b1110;
localparam logic_imm_xor = 4'b0110;


// register values
localparam reg0 = 3'b000;
localparam reg1 = 3'b001;
localparam reg2 = 3'b010;
localparam reg3 = 3'b011;
localparam reg4 = 3'b100;
localparam reg5 = 3'b101;
localparam reg6 = 3'b110;
localparam reg7 = 3'b111;

int error_count = 0;


	

//SystemVerilog Queue to store test cases that were sent
//These are popped and given to the golden model once a result is obtained from the emulator 
logic [(18)-1:0] sent_queue [$];

//Scoreboard class
//This class monitors the output pipe. It creates a new object for outputpipe 
// A task runs contineously monitoring the output pipe 
class scoreboard;
   
   xtlm_fifo #(bit[(data_width * 2)-1:0]) monitorChannel;

   logic [17:0]  instruction;   
   logic [3:0] 	 inst_type;
   int 		 rd_index;
   int 		 rs_index;
   int 		 rs2_index;
   logic [7:0] 	 immediate;
   logic [2:0] 	 bottom_three_bits;
   logic [2:0] 	 bottom_two_bits;	 
		   
   logic [7:0] 	 reg_hvl_values [7:0] = {{8{1'b0}}, {8{1'b0}}, {8{1'b0}}, {8{1'b0}},
					 {8{1'b0}}, {8{1'b0}}, {8{1'b0}}, {8{1'b0}}};
   logic [7:0] 	 reg_hdl_values [7:0];

   bit 		 carry = 0;
   logic [8:0] 	 result_with_carry;
   
   function new ();
      begin
	 monitorChannel = new ("module_top.outputpipe");
     end      
   endfunction
   
   task run(); 
      begin

	 while(1)
	   begin
	      logic [63:0] hdl_output;
	  
	      monitorChannel.get(hdl_output);

	      reg_hdl_values = {hdl_output [7:0], hdl_output [15:8], hdl_output [23:16],
				hdl_output[31:24], hdl_output [39:32], hdl_output [47:40],
				hdl_output [55:48], hdl_output [63:56]};
	      
	      
	      instruction = sent_queue.pop_front;

	      
	      inst_type = instruction [17:14];
	      rd_index = instruction [13:11];
	      rs_index = instruction [10:8];
	      rs2_index = instruction [7:5];
	      immediate = instruction [7:0];
	      bottom_three_bits = instruction[2:0];
	      bottom_two_bits = instruction[1:0];
	      
	      	      
	      if (inst_type == add_imm) // add immediate
		begin
		   result_with_carry = reg_hvl_values[rs_index] + immediate;
 		   reg_hvl_values[rd_index] = result_with_carry[7:0];
		   carry = result_with_carry[8];				   
		end

	      if (inst_type == add_carry && bottom_three_bits == 3'b001) // add with carry
		begin
		   result_with_carry = reg_hvl_values[rs_index] + reg_hvl_values[rs2_index] + carry;
 		   reg_hvl_values[rd_index] = result_with_carry[7:0];
		   carry = result_with_carry[8];
		end

	      if (inst_type == add_imm_carry) // add immediate with carry
		begin
		   result_with_carry = reg_hvl_values[rs_index] + immediate + carry;
		   reg_hvl_values[rd_index] = result_with_carry[7:0];
		   carry = result_with_carry[8];
		end

	      if (inst_type == sub && bottom_three_bits == 3'b010)
		begin
		   result_with_carry = reg_hvl_values[rs_index] - reg_hvl_values[rs2_index];
		   reg_hvl_values[rd_index] = result_with_carry[7:0];
		   carry = result_with_carry[8];
		end
	      
	      if (inst_type == sub_imm)
		begin
		   result_with_carry = reg_hvl_values[rs_index] - immediate;
		   reg_hvl_values[rd_index] = result_with_carry[7:0];
		   carry = result_with_carry[8];
		end
	      
	      if (inst_type == sub_carry && bottom_three_bits == 3'b011) // sub with carry
		begin
		   result_with_carry = reg_hvl_values[rs_index] - reg_hvl_values[rs2_index] - carry;
 		   reg_hvl_values[rd_index] = result_with_carry[7:0];
		   carry = result_with_carry[8];
		end
	      
	      if (inst_type == sub_imm_carry) // add immediate with carry
		begin
		   result_with_carry = reg_hvl_values[rs_index] - immediate - carry;
		   reg_hvl_values[rd_index] = result_with_carry[7:0];
		   carry = result_with_carry[8];
		end

	      if (inst_type == logic_and && bottom_three_bits == 3'b100)  // and
		begin
		   reg_hvl_values[rd_index] = reg_hvl_values[rs_index] & reg_hvl_values[rs2_index];
		   carry = 0;
		end

	      if (inst_type == logic_imm_and) // and with immediate
		begin
		   reg_hvl_values[rd_index] = reg_hvl_values[rs_index] & immediate;
		   carry = 0;
		end
	      
	      if (inst_type == logic_or && bottom_three_bits == 3'b101) // or
		begin
		   reg_hvl_values[rd_index] = reg_hvl_values[rs_index] | reg_hvl_values[rs2_index];
		   carry = 0;
		end

	      if (inst_type == logic_imm_or) // or with immediate
		begin
		   reg_hvl_values[rd_index] = reg_hvl_values[rs_index] | immediate;
		   carry = 0;
		end

	       if (inst_type == logic_xor && bottom_three_bits == 3'b110) // xor
		begin
		   reg_hvl_values[rd_index] = reg_hvl_values[rs_index] ^ reg_hvl_values[rs2_index];
		   carry = 0;
		end

	      if (inst_type == logic_imm_xor) // xor with immediate
		begin
		   reg_hvl_values[rd_index] = reg_hvl_values[rs_index] ^ immediate;
		   carry = 0;
		   $display("LOGICAL IMMEDIATE XOR");		   
		end
	      
	
	      // final print statements
	      $display("instruction = %b, rd_index = %d, rs_index = %d, rs2_index = %d, immediate = %d, carry = %d", instruction, rd_index, rs_index, rs2_index, immediate, carry);
			
	      $display("hvl: reg1 = %d, reg2 = %d, reg3 = %d, reg4 = %d, reg5 = %d, reg6 = %d, reg7 = %d",
		       reg_hvl_values[1], reg_hvl_values[2], reg_hvl_values[3], reg_hvl_values[4], reg_hvl_values[5],
		       reg_hvl_values[6], reg_hvl_values[7]);
	      $display("hdl: reg1 = %d, reg2 = %d, reg3 = %d, reg4 = %d, reg5 = %d, reg6 = %d, reg7 = %d\n",
		       reg_hdl_values[1], reg_hdl_values[2], reg_hdl_values[3], reg_hdl_values[4], reg_hdl_values[5],
		       reg_hdl_values[6], reg_hdl_values[7]);
	 

	   end
      end
   endtask
endclass

	
class stimulus_gen ;
   
   
   xtlm_fifo #(bit[(18)-1:0]) driverChannel;		
   int 			   inst_type; 			   
   int 			   rd_select;
   int 			   rs_select;
   int 			   rs2_select;
   
   logic [2:0] 		   rd;
   logic [2:0] 		   rs;
   logic [2:0] 		   rs2; 		   
   logic [3:0] 		   inst_code;
   logic [17:0] 	   instruction;
   logic [7:0] 		   immediate;
   
   int 			   first_pass = 1;
   
   
   
   function new();			// constructor      
      begin
	 
	 driverChannel = new ("module_top.inputpipe");		
      end
   endfunction
   
   task run;
      repeat(200)
	begin

	   rd_select = $urandom_range(7,1);
	   if (rd_select == 1)
	     rd = reg1;
	   else if (rd_select == 2)
	     rd = reg2;
	   else if (rd_select == 3)
	     rd = reg3;
	   else if (rd_select == 4)
	     rd = reg4;
	   else if (rd_select == 5)
	     rd = reg5;
	   else if (rd_select == 6)
	     rd = reg6;
	   else if (rd_select == 7)
	     rd = reg7;

	   rs_select = $urandom_range(7,0);
	   if (rs_select == 0)
	     rs = reg0;
	   if (rs_select == 1)
	     rs = reg1;
	   else if (rs_select == 2)
	     rs = reg2;
	   else if (rs_select == 3)
	     rs = reg3;
	   else if (rs_select == 4)
	     rs = reg4;
	   else if (rs_select == 5)
	     rs = reg5;
	   else if (rs_select == 6)
	     rs = reg6;
	   else if (rs_select == 7)
	     rs = reg7;

	   rs2_select = $urandom_range(7,0);
	   if (rs2_select == 0)
	     rs2 = reg0;
	   if (rs2_select == 1)
	     rs2 = reg1;
	   else if (rs2_select == 2)
	     rs2 = reg2;
	   else if (rs2_select == 3)
	     rs2 = reg3;
	   else if (rs2_select == 4)
	     rs2 = reg4;
	   else if (rs2_select == 5)
	     rs2 = reg5;
	   else if (rs2_select == 6)
	     rs2 = reg6;
	   else if (rs2_select == 7)
	     rs2 = reg7;


	   immediate = $random;
	   
	   
	   inst_type = $urandom_range(12,0);
	   //inst_type = 1; // hard-code addition immediate
	   
	   if (inst_type == 0) // add immediate
	     begin
		inst_code = add_imm;
		instruction = {inst_code, rd, rs, immediate};
	     end
	   else if (inst_type == 1) // add with carry
	     begin
		inst_code = add_carry;
		instruction = {inst_code, rd, rs, rs2, 2'b11, 3'b001};
	     end
	   else if (inst_type == 2) // add immediate with carry
	     begin
		inst_code = add_imm_carry;
		instruction = {inst_code, rd, rs, immediate};
	     end
	   else if (inst_type == 3) // sub
	     begin
		inst_code = sub;
		instruction = {inst_code, rd, rs, rs2, 2'b11, 3'b010};
	     end
	   else if (inst_type == 4) // sub immediate
	     begin
		inst_code = sub_imm;
		instruction = {inst_code, rd, rs, immediate};	
	     end
	   else if (inst_type == 5)
	     begin
		inst_code = sub_carry;
		instruction = {inst_code, rd, rs, rs2, 2'b11, 3'b011};
	     end
	   else if (inst_type == 6)
	     begin
		inst_code = sub_imm_carry;
		instruction = {inst_code, rd, rs, immediate};		
	     end
	   else if (inst_type == 7)
	     begin
		inst_code = logic_and;
		instruction = {inst_code, rd, rs, rs2, 2'b11, 3'b100};
	     end
	   else if (inst_type == 8)
	     begin
		inst_code = logic_imm_and;
		instruction = {inst_code, rd, rs, immediate};
	     end
	   else if (inst_type == 9)
	     begin
		inst_code = logic_or;
		instruction = {inst_code, rd, rs, rs2, 2'b11, 3'b101};
	     end
	   else if (inst_type == 10)
	     begin
		inst_code = logic_imm_or;
		instruction = {inst_code, rd, rs, immediate};
	     end
	   else if (inst_type == 11)
	     begin
		inst_code = logic_xor;
		instruction = {inst_code, rd, rs, rs2, 2'b11, 3'b110};
	     end
	   else if (inst_type == 12)
	     begin
		inst_code = logic_imm_xor;
		instruction = {inst_code, rd, rs, immediate};
	     end
	

	  // $display("rd = %b, rs = %b, rs2 = %b, immediate = %b", rd, rs, rs2, immediate);


	   if (first_pass == 1)
	     begin // clear all registers to zero
		driverChannel.put({add_imm, reg1, reg0, 8'b0000_0000});
		sent_queue.push_back({add_imm, reg1, reg0, 8'b0000_0000});

		driverChannel.put({add_imm, reg2, reg0, 8'b0000_0000});
		sent_queue.push_back({add_imm, reg2, reg0, 8'b0000_0000});

		driverChannel.put({add_imm, reg3, reg0, 8'b0000_0000});
		sent_queue.push_back({add_imm, reg3, reg0, 8'b0000_0000});

		driverChannel.put({add_imm, reg4, reg0, 8'b0000_0000});
		sent_queue.push_back({add_imm, reg4, reg0, 8'b0000_0000});

		driverChannel.put({add_imm, reg5, reg0, 8'b0000_0000});
		sent_queue.push_back({add_imm, reg5, reg0, 8'b0000_0000});

		driverChannel.put({add_imm, reg6, reg0, 8'b0000_0000});
		sent_queue.push_back({add_imm, reg6, reg0, 8'b0000_0000});

		driverChannel.put({add_imm, reg7, reg0, 8'b0000_0000});
		sent_queue.push_back({add_imm, reg7, reg0, 8'b0000_0000});
	     end
	   
	   
	   
	   driverChannel.put(instruction);
	   sent_queue.push_back(instruction);

	   first_pass = 0;
	end
  
      driverChannel.flush_pipe;
   endtask
endclass


module gumnut_hvl;
   
   scoreboard scb;
   stimulus_gen stim_gen;
   
   task run();
      integer i;
      fork
	 begin
	    scb.run();
	 end
      join_none
      
      fork			
	 begin
	    stim_gen.run();
	 end			
      join_none
   endtask
   
   initial 
     fork
	scb = new();
	stim_gen = new();
	$display("\nStarted at"); $system("date");
	run();
	
     join_none
   
   final
     begin
	$display("\nEnded at"); $system("date");
	if(!error_count)
	  $display("All tests are successful");
	else
	  $display("%0d Tests failed",error_count);
     end
   
endmodule





