`timescale 1ns / 1ps


module CPU(
	input		clk,
	input		rst,
	output 		halt
	);
	
	// Split the instructions
	// Instruction-related wires
	wire [31:0]		inst;
	wire [5:0]		opcode;
	wire [4:0]		rs;
	wire [4:0]		rt;
	wire [4:0]		rd;
	wire [4:0]		shamt;
	wire [5:0]		funct;
	wire [15:0]		immi;
	wire [25:0]		immj;

	// Control-related wires
	wire			RegDst;
	wire			Jump;
	wire 			Branch;
	wire 			JR;
	wire			MemRead;
	wire			MemtoReg;
	wire 			MemWrite;
	wire			ALUSrc;
	wire			SignExtend;
	wire			RegWrite;
	wire [3:0]		ALUOp;
	wire			SavePC;

	// Sign extend the immediate
	wire [31:0]		ext_imm;

	// RF-related wires
	wire [4:0]		rd_addr1;
	wire [4:0]		rd_addr2;
	wire [31:0]		rd_data1;
	wire [31:0]		rd_data2;
	wire [4:0]		wr_addr;
	wire [31:0]		wr_data;

	// MEM-related wires
	wire [31:0]		mem_addr;
	wire [31:0]		mem_write_data;
	wire [31:0]		mem_read_data;

	// ALU-related wires
	wire [31:0]		operand1;
	wire [31:0]		operand2;
	wire [31:0]		alu_result;

	// Define PC
	reg [31:0]	PC;
	reg [31:0]	PC_next;

	// Define the wires

	//hazard 수행
	reg			use_rs;
	reg 		use_rt;
	wire [5:0]	opcode_I;
	wire [4:0]	rs_I;
	wire [4:0]	rt_I;
	wire [5:0]	shamt_I;
	wire [5:0]	funct_I;

	assign opcode_I = IF_ID_inst[31:26];
	assign rs_I = IF_ID_inst[25:21];
	assign rt_I = IF_ID_inst[20:16];
	assign shamt_I = IF_ID_inst[10:6];
	assign funct_I = IF_ID_inst[5:0];

	wire stall;

	HAZARD hazard(
		.inst(IF_ID_inst),
		.rs_I(rs_I),
		.rt_I(rt_I),
		.funct_I(funct_I),
		.opcode_I(opcode_I),

		.EX_rd(ID_EX_rd),
		.EX_MemRead(ID_EX_M_MemRead),
		.EX_RegDst(ID_EX_EX_RegDst),
		.EX_rt(ID_EX_rt),

		.stall(stall)
	);

	// IF
	//mem.imemAccess -> input PC, get inst
	reg [31:0]	IF_ID_PC;
	reg [31:0]	IF_ID_inst;
    reg [31:0]  IF_ID_bh_PC;

	// ID
	// instruction split
	assign opcode = IF_ID_inst[31:26];
	assign rs = IF_ID_inst[25:21];
	assign rt = IF_ID_inst[20:16];
	assign rd = IF_ID_inst[15:11];
	assign shamt = IF_ID_inst[10:6];
	assign funct = IF_ID_inst[5:0];
	assign immi = IF_ID_inst[15:0];
	assign immj = IF_ID_inst[25:0];

	assign ext_imm = SignExtend ? {{16{immi[15]}}, immi} : {16'b0, immi};
	// set control signals
	CTRL ctrl (
		.opcode(opcode),
		.funct(funct),
		.RegDst(RegDst),
		.Jump(Jump),
		.Branch(Branch),
		.JR(JR),
		.MemRead(MemRead),
		.MemtoReg(MemtoReg),
		.MemWrite(MemWrite),
		.ALUSrc(ALUSrc),
		.SignExtend(SignExtend),
		.RegWrite(RegWrite),
		.ALUOp(ALUOp),
		.SavePC(SavePC)
	);
	// ID_EX_LATCH
	reg [31:0]	ID_EX_PC;
	reg [31:0]	ID_EX_JAL_return_address;
	reg [31:0]	ID_EX_read_data1;
	reg [31:0]	ID_EX_read_data2;
	reg [31:0]	ID_EX_ext_imm;
	reg [4:0]	ID_EX_rs;
	reg [4:0]	ID_EX_rt;
	reg [4:0]	ID_EX_rd;
	reg [4:0]	ID_EX_shamt;
	reg [25:0]	ID_EX_immj;
    reg [31:0]  ID_EX_inst;
    reg [31:0]  ID_EX_bh_PC;

	reg 		ID_EX_WB_RegWrite;
	reg 		ID_EX_WB_MemtoReg;
	reg 		ID_EX_WB_SavePC;

	reg 		ID_EX_M_MemWrite;
	reg 		ID_EX_M_MemRead;
	reg 		ID_EX_M_Branch;
	reg			ID_EX_M_SavePC;

	reg			ID_EX_EX_ALUSrc;
	reg	[3:0]	ID_EX_EX_ALUOp;
	reg			ID_EX_EX_RegDst;
	reg			ID_EX_EX_SavePC;
	reg			ID_EX_EX_Branch;
	reg			ID_EX_EX_JR;
	reg			ID_EX_EX_Jump;

	//read
	// assign operand1 = ID_EX_read_data1;
	// assign operand2 = ID_EX_EX_ALUSrc ? ID_EX_ext_imm : ID_EX_read_data2;

    wire [1:0] ForwardA;
    wire [1:0] ForwardB;

    FORWARD forward(
        .rs_I(ID_EX_rs),
        .rt_I(ID_EX_rt),
        .ex_mem_regwrite(EX_MEM_WB_RegWrite),
        .ex_mem_wr_addr(EX_MEM_wr_addr),
        .mem_wb_regwrite(MEM_WB_WB_RegWrite),
        .mem_wb_wr_addr(MEM_WB_wr_addr),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );
    
    assign operand1 = (ForwardA == 2'b10) ? EX_MEM_alu_result : (ForwardA == 2'b01) ? wb_wr_data : ID_EX_read_data1;

    wire [31:0] forwarded_rt;
    assign forwarded_rt = (ForwardB == 2'b10) ? EX_MEM_alu_result : (ForwardB == 2'b01) ? wb_wr_data : ID_EX_read_data2;

    assign operand2 = (ID_EX_EX_ALUSrc == 1'b1) ? ID_EX_ext_imm : forwarded_rt;

	ALU alu (
		.operand1(operand1),
        .operand2(operand2),
        .shamt(ID_EX_shamt),
        .funct(ID_EX_EX_ALUOp),
        .alu_result(alu_result)
	);

    // EX_MEM_LATCH
	reg [31:0]	EX_MEM_PC;
	reg [31:0]	EX_MEM_alu_result;
	reg [31:0]	EX_MEM_mem_wr_data;
	reg [4:0]	EX_MEM_wr_addr;
	reg [31:0]	EX_MEM_JAL_return_address;
    reg [31:0]  EX_MEM_inst;
    reg [31:0]  EX_MEM_bh_PC;
    reg [31:0]  EX_MEM_update_PC;

	reg 		EX_MEM_WB_RegWrite;
	reg 		EX_MEM_WB_MemtoReg;
	reg 		EX_MEM_WB_SavePC;

	reg 		EX_MEM_M_MemWrite;
	reg 		EX_MEM_M_MemRead;
	reg 		EX_MEM_M_Branch;
	reg			EX_MEM_M_SavePC;

	//MEM
	// dmemAccess
	wire [31:0]		mem_data;
	wire [31:0]		mem_wr_data;
    wire            mem_MemWrite;
	assign mem_addr = EX_MEM_alu_result;
	assign mem_wr_data = EX_MEM_mem_wr_data;
    assign mem_MemWrite = EX_MEM_M_MemWrite;

	MEM mem (
		.clk(clk),
		.rst(rst),
		.inst_addr(PC),
		.inst(inst),
		.mem_addr(mem_addr),
		.MemWrite(mem_MemWrite),
		.mem_write_data(mem_wr_data),
		.mem_read_data(mem_data)
	);

	reg [31:0]	MEM_WB_mem_data;
	reg [31:0]	MEM_WB_alu_result;
	reg [4:0]	MEM_WB_wr_addr;
	reg [31:0]	MEM_WB_JAL_return_address;
    reg [31:0]  MEM_WB_inst;
    reg [31:0]  MEM_WB_PC;

	reg 		MEM_WB_WB_RegWrite;
	reg 		MEM_WB_WB_MemtoReg;
	reg 		MEM_WB_WB_SavePC;
	
	wire [4:0]	wb_wr_addr;
	wire [31:0]	wb_wr_data;

	assign wb_wr_addr = MEM_WB_wr_addr;
	assign wb_wr_data = (MEM_WB_WB_SavePC?MEM_WB_JAL_return_address:(MEM_WB_WB_MemtoReg?MEM_WB_mem_data:MEM_WB_alu_result));

	// WB
	RF rf (
		.clk(clk),
        .rst(rst),
        .rd_addr1(rs),
        .rd_addr2(rt),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2),
        .RegWrite(MEM_WB_WB_RegWrite),
        .wr_addr(wb_wr_addr),
        .wr_data(wb_wr_data)
	);

	assign halt = (PC > 32'h17FF);
    reg branch_taken;
    reg [31:0] cycle;
    wire [31:0] predicted_PC;

    //
    reg EX_MEM_EX_JR, EX_MEM_EX_Branch, EX_MEM_EX_Jump;

    BP bp (
        .clk(clk),
        .rst(rst),
        .branch_taken(branch_taken),
        .pc(PC),
        .upc(EX_MEM_update_PC - 4),
        .update_target1(EX_MEM_PC),
        .update_target2(EX_MEM_update_PC),
        .JR(EX_MEM_EX_JR),
        .Branch(EX_MEM_EX_Branch),
        .Jump(EX_MEM_EX_Jump),
        .predicted_target(predicted_PC)
    );
    wire flush;
    assign flush = (branch_taken && (EX_MEM_PC != EX_MEM_bh_PC));

    always @(posedge clk) begin
        if (rst) begin
            cycle <= 0;
            PC <= 0;
            branch_taken <= 0;
            IF_ID_PC <= 0;
            IF_ID_inst <= 0;
            
            ID_EX_PC <= 0;
            ID_EX_JAL_return_address <= 0;
            ID_EX_read_data1 <= 0;
            ID_EX_read_data2 <= 0;
            ID_EX_ext_imm <= 0;
            ID_EX_rs <= 0;
            ID_EX_rt <= 0;
            ID_EX_rd <= 0;
            ID_EX_shamt <= 0;
            ID_EX_immj <= 0;
            IF_ID_inst <= 0;

            ID_EX_WB_RegWrite  <= 0;
            ID_EX_WB_MemtoReg  <= 0;
            ID_EX_WB_SavePC    <= 0;

            ID_EX_M_MemWrite   <= 0;
            ID_EX_M_MemRead    <= 0;
            ID_EX_M_Branch     <= 0;
            ID_EX_M_SavePC     <= 0;

            ID_EX_EX_ALUSrc    <= 0;
            ID_EX_EX_ALUOp     <= 0;
            ID_EX_EX_RegDst    <= 0;
            ID_EX_EX_SavePC    <= 0;
            ID_EX_EX_Branch    <= 0;
            ID_EX_EX_JR        <= 0;
            ID_EX_EX_Jump      <= 0;
            
            EX_MEM_PC <= 0;
            EX_MEM_alu_result <= 0;
            EX_MEM_mem_wr_data <= 0;
            EX_MEM_inst <= 0;
            EX_MEM_wr_addr <= 0;

            EX_MEM_WB_RegWrite <= 0;
            EX_MEM_WB_MemtoReg <= 0;
            EX_MEM_WB_SavePC <= 0;
            
            EX_MEM_M_MemWrite <= 0;
            EX_MEM_M_MemRead <= 0;
            EX_MEM_M_Branch <= 0;
            EX_MEM_M_SavePC <= 0;
            EX_MEM_JAL_return_address <= 0;
            EX_MEM_PC <= 0;
            
            MEM_WB_mem_data <= 0;
            MEM_WB_alu_result <= 0;
            MEM_WB_wr_addr <= 0;
            MEM_WB_inst <= 0;

            MEM_WB_WB_RegWrite <= 0;
            MEM_WB_WB_MemtoReg <= 0;
            MEM_WB_WB_SavePC <= 0;

            MEM_WB_JAL_return_address <= 0;

        end else begin 
            if (flush) begin
                // $write("flush\n");
                PC <= EX_MEM_PC;
            end else if (!stall) begin
                PC <= predicted_PC;
            end

            // $write("\nstart Stage!\n");
            // -------- IF Stage --------
            if(flush) begin
                IF_ID_PC <= 32'b0;
                IF_ID_inst <= 32'd0;
            end else 
            if(stall == 1'b1) begin
                // $write("stall\n");
                IF_ID_PC <= IF_ID_PC;
                IF_ID_inst <= IF_ID_inst;
            end
            else begin
                // $write("IF : [%h]:%h\n", PC, inst);
                IF_ID_bh_PC = predicted_PC;
                IF_ID_PC <= PC + 4;
                IF_ID_inst <= inst;
            end

            // -------- ID Stage --------
            if(stall == 1'b1 || flush) begin
                // $write("ID-stall\n");
                ID_EX_PC <= 0;
                ID_EX_JAL_return_address <= 0;
                ID_EX_read_data1 <= 0;
                ID_EX_read_data2 <= 0;
                ID_EX_ext_imm <= 0;
                ID_EX_rs <= 0;
                ID_EX_rt <= 0;
                ID_EX_rd <= 0;
                ID_EX_shamt <= 0;
                ID_EX_immj <= 0;
                ID_EX_inst <= 0;
                
                ID_EX_WB_RegWrite  <= 0;
                ID_EX_WB_MemtoReg  <= 0;
                ID_EX_WB_SavePC    <= 0;

                ID_EX_M_MemWrite   <= 0;
                ID_EX_M_MemRead    <= 0;
                ID_EX_M_Branch     <= 0;
                ID_EX_M_SavePC     <= 0;

                ID_EX_EX_ALUSrc    <= 0;
                ID_EX_EX_ALUOp     <= 0;
                ID_EX_EX_RegDst    <= 0;
                ID_EX_EX_SavePC    <= 0;
                ID_EX_EX_Branch    <= 0;
                ID_EX_EX_JR        <= 0;
                ID_EX_EX_Jump      <= 0;
            end
            else if(IF_ID_inst != 0) begin
                // $write("ID Stage : 0x%h %d %d\n", IF_ID_inst, rs, rt);
                ID_EX_bh_PC <= IF_ID_bh_PC;
                ID_EX_PC <= IF_ID_PC;
                ID_EX_JAL_return_address <= IF_ID_PC;
                ID_EX_read_data1 <= rd_data1;
                ID_EX_read_data2 <= rd_data2;
                ID_EX_ext_imm <= ext_imm;
                ID_EX_rs <= rs;
                ID_EX_rt <= rt;
                ID_EX_rd <= rd;
                ID_EX_shamt <= shamt;
                ID_EX_immj <= immj;
                ID_EX_inst <= IF_ID_inst;

                ID_EX_WB_RegWrite  <= RegWrite;
                ID_EX_WB_MemtoReg  <= MemtoReg;
                ID_EX_WB_SavePC    <= SavePC;

                ID_EX_M_MemWrite   <= MemWrite;
                ID_EX_M_MemRead    <= MemRead;
                ID_EX_M_Branch     <= Branch;
                ID_EX_M_SavePC     <= SavePC;

                ID_EX_EX_ALUSrc    <= ALUSrc;
                ID_EX_EX_ALUOp     <= ALUOp;
                ID_EX_EX_RegDst    <= RegDst;
                ID_EX_EX_SavePC    <= SavePC;
                ID_EX_EX_Branch    <= Branch;
                ID_EX_EX_JR        <= JR;
                ID_EX_EX_Jump      <= Jump;
            end else begin
                // $write("ID : NOP\n");
                ID_EX_PC <= 0;
                ID_EX_JAL_return_address <= 0;
                ID_EX_read_data1 <= 0;
                ID_EX_read_data2 <= 0;
                ID_EX_ext_imm <= 0;
                ID_EX_rs <= 0;
                ID_EX_rt <= 0;
                ID_EX_rd <= 0;
                ID_EX_shamt <= 0;
                ID_EX_immj <= 0;
                ID_EX_inst <= 0;

                ID_EX_WB_RegWrite  <= 0;
                ID_EX_WB_MemtoReg  <= 0;
                ID_EX_WB_SavePC    <= 0;

                ID_EX_M_MemWrite   <= 0;
                ID_EX_M_MemRead    <= 0;
                ID_EX_M_Branch     <= 0;
                ID_EX_M_SavePC     <= 0;

                ID_EX_EX_ALUSrc    <= 0;
                ID_EX_EX_ALUOp     <= 0;
                ID_EX_EX_RegDst    <= 0;
                ID_EX_EX_SavePC    <= 0;
                ID_EX_EX_Branch    <= 0;
                ID_EX_EX_JR        <= 0;
                ID_EX_EX_Jump      <= 0;
            end

            // -------EX---------
            if(!flush) begin
                // $write("Ex : 0x%h %h + %h = %h\n", ID_EX_inst, ID_EX_read_data1, ID_EX_read_data2, alu_result);
                EX_MEM_inst <= ID_EX_inst;
                EX_MEM_alu_result <= alu_result;
                EX_MEM_mem_wr_data <= forwarded_rt;

                if (ID_EX_EX_SavePC) begin
                    EX_MEM_wr_addr <= 31;
                end else begin
                    EX_MEM_wr_addr <= ID_EX_EX_RegDst ? ID_EX_rd : ID_EX_rt;
                end
                
                EX_MEM_WB_RegWrite <= ID_EX_WB_RegWrite;
                EX_MEM_WB_MemtoReg <= ID_EX_WB_MemtoReg;
                EX_MEM_WB_SavePC <= ID_EX_WB_SavePC;
                EX_MEM_bh_PC <= ID_EX_bh_PC; // testing
                EX_MEM_update_PC <= ID_EX_PC;

                EX_MEM_M_MemWrite <= ID_EX_M_MemWrite;
                EX_MEM_M_MemRead <= ID_EX_M_MemRead;
                EX_MEM_M_Branch <= ID_EX_M_Branch;
                EX_MEM_M_SavePC <= ID_EX_M_SavePC;

                EX_MEM_JAL_return_address <= ID_EX_JAL_return_address;

                EX_MEM_EX_JR     <= ID_EX_EX_JR;
                EX_MEM_EX_Branch <= ID_EX_EX_Branch;
                EX_MEM_EX_Jump   <= ID_EX_EX_Jump;

                if(flush) begin
                    branch_taken <= 1'b0;
                end else begin
                    if (ID_EX_EX_Branch) begin
                        if(alu_result) begin
                            EX_MEM_PC <= ID_EX_PC + (ID_EX_ext_imm << 2);
                            branch_taken <= 1'b1;
                        end else begin
                            EX_MEM_PC <= 0;
                            branch_taken <= 1'b0;
                        end
                    end else if (ID_EX_EX_JR) begin
                        if (ForwardA == 1) 
                            EX_MEM_PC <= wb_wr_data;
                        else if (ForwardA == 2)
                            EX_MEM_PC <= EX_MEM_alu_result;
                        else
                            EX_MEM_PC <= ID_EX_read_data1;
                        branch_taken <= 1'b1;
                    end else if (ID_EX_EX_Jump) begin
                        EX_MEM_PC <= {ID_EX_PC[31:28], ID_EX_immj, 2'b00};
                        branch_taken <= 1'b1;
                    end else begin
                        EX_MEM_PC <= 0;
                        branch_taken <= 1'b0;
                    end
                end
            end else begin
                branch_taken <= 1'b0;
                EX_MEM_PC <= 0;
                EX_MEM_alu_result <= 0;
                EX_MEM_mem_wr_data <= 0;
                EX_MEM_inst <= 0;
                EX_MEM_wr_addr <= 0;

                EX_MEM_WB_RegWrite <= 0;
                EX_MEM_WB_MemtoReg <= 0;
                EX_MEM_WB_SavePC <= 0;
                
                EX_MEM_M_MemWrite <= 0;
                EX_MEM_M_MemRead <= 0;
                EX_MEM_M_Branch <= 0;
                EX_MEM_M_SavePC <= 0;
                EX_MEM_JAL_return_address <= 0;
                EX_MEM_PC <= 0;
            end
            // ---------MEM---------
            // $write("MEM : 0x%h\n", EX_MEM_inst);
            MEM_WB_mem_data <= mem_data;
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_wr_addr <= EX_MEM_wr_addr;
            MEM_WB_inst <= EX_MEM_inst;
            MEM_WB_PC <= EX_MEM_PC;

            MEM_WB_WB_RegWrite <= EX_MEM_WB_RegWrite;
            MEM_WB_WB_MemtoReg <= EX_MEM_WB_MemtoReg;
            MEM_WB_WB_SavePC <= EX_MEM_WB_SavePC;

            MEM_WB_JAL_return_address <= EX_MEM_JAL_return_address;
            // $write("WB : 0x%h\n", MEM_WB_inst);
            // if(MEM_WB_WB_RegWrite) $write("%h : REG %d : %h\n", MEM_WB_inst, MEM_WB_wr_addr, (MEM_WB_WB_SavePC ? MEM_WB_JAL_return_address:(MEM_WB_WB_MemtoReg?MEM_WB_mem_data:MEM_WB_alu_result)));
        end
	end
endmodule
