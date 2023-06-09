`ifdef MODEL_TECH
	`include "../sys_defs.vh"
`endif

module processor(
    input logic 		clk,                  	// System clk
    input logic 		rst,                  	// System rst
    
	output logic [4:0]  pipeline_commit_wr_idx,
    output logic [31:0] pipeline_commit_wr_data,
    output logic [31:0] pipeline_commit_NPC,
	output logic        pipeline_commit_wr,
	
	input  logic[ 31:0] instruction,
	output logic [31:0] pc_addr,
	output logic [1:0]  im_command,

	input logic [31:0] 	mem2proc_data,
	output logic [31:0] proc2Dmem_addr,
	output logic [1:0] 	proc2Dmem_command,
	output logic [31:0] proc2mem_data,
	
	// Outputs from IF-Stage 
	output logic [31:0] if_PC_out,
	output logic [31:0] if_NPC_out,
	output logic [31:0] if_IR_out,
	output logic        if_valid_inst_out,

	// Outputs from IF/ID Pipeline Register
	output logic [31:0] if_id_PC,
	output logic [31:0] if_id_NPC,
	output logic [31:0] if_id_IR,
	output logic        if_id_valid_inst,

	// Outputs from ID/EX Pipeline Register
	output logic [31:0] id_ex_PC,
	output logic [31:0] id_ex_NPC,
	output logic [31:0] id_ex_IR,
	output logic   		id_ex_valid_inst,
	//output logic [4:0]  id_ex_dest_reg_idx,				//////////////	NEW		////////////////

	// Outputs from EX/MEM Pipeline Register
	output logic [31:0] ex_mem_NPC,
	output logic [31:0] ex_mem_IR,
	output logic   		ex_mem_valid_inst,
	//output logic [4:0]	ex_mem_dest_reg_idx,			//////////////	NEW		////////////////

	// Outputs from MEM/WB Pipeline Register
	output logic [31:0] mem_wb_NPC,
	output logic [31:0] mem_wb_IR,
	output logic   		mem_wb_valid_inst

	//input logic 		stall_due_to_RAW /////////////		NEW			///////////////
	//input logic			stall				///////////		NEW			//////////////
	);			  

// Pipeline register enables
logic 			if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;


// Outputs from ID stage
logic           id_reg_wr_out;
logic [2:0]		id_funct3_out;
logic [31:0]   	id_rega_out;
logic [31:0]   	id_regb_out;
logic [31:0]	id_immediate_out;
logic [1:0] 	id_opa_select_out;
logic [1:0] 	id_opb_select_out;
logic [4:0]   	id_dest_reg_idx_out;
logic [4:0]     id_alu_func_out;
logic         	id_rd_mem_out;
logic           id_wr_mem_out;
logic         	id_illegal_out;
logic         	id_valid_inst_out;
logic 			id_uncond_branch;
logic 			id_cond_branch;
logic [31:0]    id_pc_add_opa;
logic [4:0] 	if_id_rs1; 	///////new
logic [4:0] 	if_id_rs2;   ///////new
logic 			fwd_rs1;	///////new
logic 			fwd_rs2;	///////new

// Outputs from ID/EX Pipeline Register
logic 			id_ex_reg_wr;
logic [2:0]		id_ex_funct3;
logic [31:0]   	id_ex_rega;
logic [31:0]   	id_ex_regb;
logic [31:0]	id_ex_rega_fwd;///////new
logic [31:0]	id_ex_regb_fwd;///////new
logic [31:0] 	id_ex_imm;
logic [1:0]		id_ex_opa_select;
logic [1:0]		id_ex_opb_select;
logic [4:0]   	id_ex_dest_reg_idx;
logic [4:0]     id_ex_alu_func;
logic           id_ex_rd_mem;
logic           id_ex_wr_mem;
logic           id_ex_illegal;
logic 			id_ex_uncond_branch;
logic 			id_ex_cond_branch;
logic [31:0]    id_ex_pc_add_opa;

// Outputs from EX-Stage
logic [31:0] 	ex_target_PC_out;
logic 			ex_take_branch_out;
logic [31:0] 	ex_alu_result_out;

// Outputs from EX/MEM Pipeline Register
logic [2:0]		ex_mem_funct3;
logic [4:0]		ex_mem_dest_reg_idx;
logic      		ex_mem_rd_mem;
logic         	ex_mem_wr_mem;
logic			ex_mem_reg_wr;
logic      		ex_mem_illegal;
logic [31:0]	ex_mem_regb;
logic [31:0]	ex_mem_alu_result;
logic 			ex_mem_take_branch;
logic [31:0] 	ex_mem_target_PC;


// Outputs from MEM-Stage
logic [31:0] 	mem_result_out;

// Outputs from MEM/WB Pipeline Register
logic [2:0]		mem_wb_funct3;
logic       	mem_wb_illegal;
logic       	mem_wb_reg_wr;
logic [4:0]	 	mem_wb_dest_reg_idx;
logic 			mem_wb_rd_mem;
logic [31:0] 	mem_wb_mem_result;
logic [31:0] 	mem_wb_alu_result;


// Output from WB-Stage  (this loop back to the register file in ID and to the EX stage)
logic [31:0] 	wb_reg_wr_data_out;

//Output Memory


assign im_command=`BUS_LOAD;

assign pipeline_commit_wr_idx 	= mem_wb_dest_reg_idx;
assign pipeline_commit_wr_data 	= wb_reg_wr_data_out;
assign pipeline_commit_NPC 		= if_NPC_out;
assign pipeline_commit_wr 		= mem_wb_reg_wr;


//////////////////////////////////////////////////
//                                              //
//                  IF-Stage                    //
//                                              //
//////////////////////////////////////////////////
if_stage if_stage_0 (
// Inputs
.clk 				(clk),
.rst 				(rst),
.mem_wb_valid_inst	(mem_wb_valid_inst),
.ex_take_branch_out	(ex_mem_take_branch),
.ex_target_PC_out	(ex_mem_target_PC),
.Imem2proc_data		(instruction),


// Outputs
.if_NPC_out			(if_NPC_out),
.if_PC_out			(if_PC_out), 
.if_IR_out			(if_IR_out),
.proc2Imem_addr		(pc_addr),
.if_valid_inst_out  (if_valid_inst_out),
.stall_due_to_RAW   (stall_due_to_RAW)
);

/////////// 		NEW			/////////////////////	

// Hazard Detection


/* hazard_detection hazard_detection_0(.id_ex_rd 			(id_ex_dest_reg_idx),
									.ex_mem_rd			(ex_mem_dest_reg_idx),
									.mem_wb_rd 			(mem_wb_dest_reg_idx),
									.if_id_rs1	 		(if_id_rs1),
									.if_id_rs2  		(if_id_rs2),
									.stall_due_to_RAW  	(stall_due_to_RAW)
									); */
								
forwarding_to_id forwarding_to_id_0(
	//inputs
	.if_id_rs1 			(if_id_rs1),
	.if_id_rs2 			(if_id_rs2),
	.id_ex_rd  			(id_ex_dest_reg_idx),
	.ex_mem_rd 			(ex_mem_dest_reg_idx),
	.mem_wb_rd 			(mem_wb_dest_reg_idx),
	.result_from_alu	(ex_alu_result_out),
	.result_from_mem	(mem_result_out),
	.result_from_wb		(wb_reg_wr_data_out),
	.instr				(instruction),
	//outputs
	//rs1
	.result_rs1  		(id_ex_rega_fwd),
	.fwd_rs1			(fwd_rs1),

	//rs2
	.result_rs2  		(id_ex_regb_fwd),
	.fwd_rs2			(fwd_rs2),

	.stall_due_to_next_RAW (stall_due_to_RAW)

);
/////////// 		END NEW			/////////////////////


//////////////////////////////////////////////////
//                                              //
//            IF/ID Pipeline Register           //
//                                              //
//////////////////////////////////////////////////
assign if_id_enable = !stall_due_to_RAW;		 /////////// 		NEW			/////////////////////		

always_ff @(posedge clk or posedge rst) begin
	if(rst||ex_mem_take_branch) begin       /////////// 		NEW			/////////////////////		
		if_id_PC         <=  0;
		if_id_IR         <=  `NOOP_INST;
		if_id_NPC        <=  0;
        if_id_valid_inst <=  0;
    end 
    else if (if_id_enable) begin
		if_id_PC         <=  if_PC_out;
		if_id_NPC        <=  if_NPC_out;
		if_id_IR         <=  if_IR_out;
        if_id_valid_inst <= if_valid_inst_out;
    end 
end 
//assign if_valid_inst_out = ~stall_due_to_RAW;   /////////// 		NEW			/////////////////////	

   
//////////////////////////////////////////////////
//                                              //
//                  ID-Stage                    //
//                                              //
//////////////////////////////////////////////////
id_stage id_stage_0 (
// Inputs
.clk     				(clk),
.rst   					(rst),
.if_id_IR   			(if_id_IR),
.if_id_PC				(if_id_PC),
.mem_wb_dest_reg_idx	(mem_wb_dest_reg_idx),
.mem_wb_valid_inst    	(mem_wb_valid_inst),
.mem_wb_reg_wr			(mem_wb_reg_wr), 
.wb_reg_wr_data_out     (wb_reg_wr_data_out),  	
.if_id_valid_inst       (if_id_valid_inst),
.stall_due_to_RAW 		(stall_due_to_RAW),				///////////////			NEW 		//////////////////////
//.stall					(stall),						///////////////			NEW 		//////////////////////

// Outputs
.id_reg_wr_out          (id_reg_wr_out),
.id_funct3_out			(id_funct3_out),
.id_ra_value_out		(id_rega_out),
.id_rb_value_out		(id_regb_out),
.pc_add_opa				(id_pc_add_opa),
.id_immediate_out		(id_immediate_out),
.id_opa_select_out		(id_opa_select_out),
.id_opb_select_out		(id_opb_select_out),
.id_dest_reg_idx_out	(id_dest_reg_idx_out),
.id_alu_func_out		(id_alu_func_out),
.id_rd_mem_out			(id_rd_mem_out),
.id_wr_mem_out			(id_wr_mem_out),
.cond_branch			(id_cond_branch),
.uncond_branch			(id_uncond_branch),
.id_illegal_out			(id_illegal_out),
.id_valid_inst_out		(id_valid_inst_out),
.ra_idx	 				(if_id_rs1), 				///////////////			NEW 		//////////////////////
.rb_idx  				(if_id_rs2)			        ///////////////			NEW 		//////////////////////
);

//////////////////////////////////////////////////
//                                              //
//            ID/EX Pipeline Register           //
//                                              //
//////////////////////////////////////////////////
assign id_ex_enable =1; // disabled when HzDU initiates a stall
// synopsys sync_set_rst "rst"
always_ff @(posedge clk or posedge rst) begin
// 	if (rst || stall_due_to_RAW || ex_mem_take_branch) begin //sys_rst 		
	if (rst) begin //sys_rst 				//////////	 NEW	 /////////
		//Control
		id_ex_funct3		<=  0;
		id_ex_opa_select    <=  `ALU_OPA_IS_REGA;
		id_ex_opb_select    <=  `ALU_OPB_IS_REGB;
		id_ex_alu_func      <=  `ALU_ADD;
		id_ex_rd_mem        <=  0;
		id_ex_wr_mem        <=  0;
		id_ex_illegal       <=  0;
		id_ex_valid_inst    <=  `FALSE;
        id_ex_reg_wr        <=  `FALSE;
		
		//Data
		id_ex_PC            <=  0;
		id_ex_IR            <=  `NOOP_INST;
		id_ex_rega          <=  0;
		id_ex_regb          <=  0;
		id_ex_imm			<=  0;
		id_ex_dest_reg_idx  <=  `ZERO_REG;
		id_ex_pc_add_opa	<=  0;
		id_ex_uncond_branch <=  0;
		id_ex_cond_branch	<=  0;
		
		//Debug
		id_ex_NPC           <=  0;
	end else begin
		if (id_ex_enable) begin
			id_ex_funct3		<=  id_funct3_out;
			id_ex_opa_select    <=  id_opa_select_out;
			id_ex_opb_select    <=  id_opb_select_out;
			id_ex_alu_func      <=  id_alu_func_out;
			id_ex_rd_mem        <=  id_rd_mem_out;
			id_ex_wr_mem        <=  id_wr_mem_out;
			id_ex_illegal       <=  id_illegal_out;
			id_ex_valid_inst    <=  id_valid_inst_out;
            id_ex_reg_wr        <=  id_reg_wr_out;
			
			id_ex_PC            <=  if_id_PC;
			id_ex_IR            <=  if_id_IR;

			if(fwd_rs1)
				id_ex_rega      <=  id_ex_rega_fwd;
			else
				id_ex_rega      <=  id_rega_out;
			if(fwd_rs2)
				id_ex_regb      <=  id_ex_regb_fwd;
			else
				id_ex_regb      <=  id_regb_out;

			id_ex_imm			<=  id_immediate_out;
			id_ex_dest_reg_idx  <=  id_dest_reg_idx_out;
			
			id_ex_NPC           <=  if_id_NPC;
			id_ex_pc_add_opa	<=  id_pc_add_opa;
			id_ex_uncond_branch <=  id_uncond_branch;
			id_ex_cond_branch	<=  id_cond_branch;
		end // if
    end // else: !if(rst)
end // always
//assign id_ex_valid_inst = ~stall_due_to_RAW;   /////////// 		NEW			/////////////////////	
//////////////////////////////////////////////////
//                                              //
//                  EX-Stage                    //
//                                              //
//////////////////////////////////////////////////
ex_stage ex_stage_0 (
// Inputs
.clk					(clk),
.rst					(rst),
.id_ex_PC				(id_ex_PC), 
.id_ex_imm				(id_ex_imm),
.id_ex_rega				(id_ex_rega),
.id_ex_regb				(id_ex_regb),
.id_ex_opa_select		(id_ex_opa_select),
.id_ex_opb_select		(id_ex_opb_select),
.id_ex_alu_func			(id_ex_alu_func),
.id_ex_valid_inst		(id_ex_valid_inst),
.pc_add_opa				(id_ex_pc_add_opa),
.id_ex_funct3			(id_ex_funct3),
.uncond_branch			(id_ex_uncond_branch),
.cond_branch			(id_ex_cond_branch),
//.stall_due_to_br		(stall_due_to_branch), ////NEW
// Outputs
.ex_take_branch_out		(ex_take_branch_out),
.ex_target_PC_out		(ex_target_PC_out),
.ex_alu_result_out		(ex_alu_result_out)
);

//////////////////////////////////////////////////
//                                              //
//           EX/MEM Pipeline Register           //
//                                              //
//////////////////////////////////////////////////
assign ex_mem_enable = 1; // always enabled
// synopsys sync_set_rst "rst"
always_ff @(posedge clk or posedge rst) begin
	if (rst || ex_mem_take_branch) begin
		//Control
		ex_mem_funct3		<=  0;
		ex_mem_rd_mem       <=  0;
		ex_mem_wr_mem       <=  0;
		ex_mem_illegal      <=  0;
		ex_mem_valid_inst   <=  `FALSE;
		ex_mem_reg_wr       <=  `FALSE;
		//Data
		ex_mem_IR           <=  `NOOP_INST;
		ex_mem_dest_reg_idx <=  `ZERO_REG;
		ex_mem_regb         <=  0;
		ex_mem_alu_result   <=  0;
		ex_mem_take_branch	<=  0;
		ex_mem_target_PC	<=  0;		
		//Debug
		ex_mem_NPC			<=  0;
	end else begin
		if(ex_mem_enable) begin 
			ex_mem_funct3		<=  id_ex_funct3;
			ex_mem_rd_mem       <=  id_ex_rd_mem;
			ex_mem_wr_mem       <=  id_ex_wr_mem;
			ex_mem_illegal      <=  id_ex_illegal;
			ex_mem_valid_inst   <=  id_ex_valid_inst;
		    ex_mem_reg_wr       <=  id_ex_reg_wr;
		
			ex_mem_IR           <=  id_ex_IR;
			ex_mem_dest_reg_idx <=  id_ex_dest_reg_idx;
			ex_mem_regb         <=  id_ex_regb;		
			ex_mem_alu_result   <=  ex_alu_result_out;
			ex_mem_take_branch  <=	ex_take_branch_out;
			ex_mem_target_PC	<=  ex_target_PC_out;			
			ex_mem_NPC			<=  id_ex_NPC;
		end // if		
	end // else: !if(rst)
end // always

//assign ex_mem_valid_inst = ~stall_due_to_RAW;   /////////// 		NEW			/////////////////////	  
//////////////////////////////////////////////////
//                                              //
//                 MEM-Stage                    //
//                                              //
//////////////////////////////////////////////////
mem_stage mem_stage_0 (
//Inputs
.clk				(clk),
.rst				(rst),
.ex_mem_regb		(ex_mem_regb),

.ex_mem_alu_result	(ex_mem_alu_result),
.ex_mem_rd_mem		(ex_mem_rd_mem),
.ex_mem_wr_mem		(ex_mem_wr_mem),
.Dmem2proc_data		(mem2proc_data),
.ex_mem_valid_inst	(ex_mem_valid_inst),

// Outputs
.mem_result_out		(mem_result_out),
.proc2Dmem_command	(proc2Dmem_command),
.proc2Dmem_addr		(proc2Dmem_addr),
.proc2Dmem_data		(proc2mem_data)
);


//////////////////////////////////////////////////
//                                              //
//           MEM/WB Pipeline Register           //
//                                              //
//////////////////////////////////////////////////
assign mem_wb_enable = 1; // always enabled
// synopsys sync_set_rst "rst"
always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
		//Control 
		mem_wb_funct3		<=  0;
		mem_wb_illegal      <=  0;
		mem_wb_valid_inst   <=  `FALSE;
		mem_wb_rd_mem    	<=  `FALSE;
        mem_wb_reg_wr       <=  `FALSE;
		//Data
		mem_wb_IR           <=  `NOOP_INST;
		mem_wb_dest_reg_idx <=  `ZERO_REG;
		mem_wb_mem_result   <=  0;
		mem_wb_alu_result   <=  0;
		
		//Debug
		mem_wb_NPC			<=  0;
	end else begin
		if (mem_wb_enable) begin
			mem_wb_funct3		<=  ex_mem_funct3;
			mem_wb_rd_mem    	<=  ex_mem_rd_mem;
			mem_wb_illegal      <=  ex_mem_illegal;
			mem_wb_valid_inst   <=  ex_mem_valid_inst;
			
            mem_wb_reg_wr       <=  ex_mem_reg_wr;
			mem_wb_IR           <=  ex_mem_IR;
			mem_wb_dest_reg_idx <=  ex_mem_dest_reg_idx;
			mem_wb_mem_result   <=  mem_result_out;
			mem_wb_alu_result   <=  ex_mem_alu_result;
			
			mem_wb_NPC			<=  ex_mem_NPC;
		end // if
	end // else: !if(rst)
end // always
//assign mem_wb_valid_inst = ~stall_due_to_RAW;   /////////// 		NEW			/////////////////////	

//////////////////////////////////////////////////
//                                              //
//                  WB-Stage                    //
//                                              //
//////////////////////////////////////////////////
wb_stage wb_stage_0(
.mem_wb_mem_result	(mem_wb_mem_result),
.mem_wb_alu_result	(mem_wb_alu_result),
.mem_wb_rd_mem		(mem_wb_rd_mem),
.mem_wb_valid_inst  (mem_wb_valid_inst),
		
.wb_reg_wr_data_out	(wb_reg_wr_data_out)
);

endmodule  