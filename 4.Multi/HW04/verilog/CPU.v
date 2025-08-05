`timescale 1ns / 1ps


module CPU(
	input		clk,
	input		rst,
	output 		halt
	);
	
	// Split the instructions
	// Instruction-related wires
	// wire [31:0]		inst;
	wire [5:0]		opcode;
	wire [4:0]		rs;
	wire [4:0]		rt;
	wire [4:0]		rd;
	wire [4:0]		shamt;
	wire [5:0]		funct;
	wire [15:0]		immi;
	wire [25:0]		immj;

	// Control-related wires
	wire RegDst;
	wire RegWrite;
	wire ALUSrcA;
	wire [3:0] ALUSrcB;
	wire [3:0] ALUOp;
	wire [3:0] PCSource;
	wire IRWrite;
	wire MemtoReg;
	wire MemWrite;
	wire MemRead;
	wire IorD;
	wire PCWrite;
	wire PCWriteCond;
	wire JR;
	wire SignExtend;
	wire SavePC;

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
	wire [31:0]		alu_zero;

	// Define PC
	reg [31:0]		PC;
	reg [31:0]		IR;
	reg [31:0]		A;
	reg [31:0] 		B;
	reg [31:0] 		ALUOut;
	reg [31:0]		MDR;

	// Define the wires

	// for testbench
	// assign halt = (PC == 32'h4e4);
	assign halt				= (IR == 32'b0);

	// Update the Clock
	// init
	always @(posedge clk) begin
		if(rst) begin
			PC <= 0;
			IR <= 0;
			A <= 0;
			B <= 0;
			ALUOut <= 0;
			MDR <= 0;
		end else begin
			if(IRWrite) begin
				IR <= mem_read_data;
				// $write("PC : %x A : %x // %x\n", PC, PC_next, ALUOut);
			end else
				MDR <= mem_read_data;
			// $write("----------------------------\n@inst %x PC %x A %x B %x aluout %x\n", IR,PC, A, B, ALUOut);
			A <= rd_data1;
			B <= rd_data2;
			ALUOut <= alu_result;

			if (PCWrite || (PCWriteCond && alu_zero)) begin
				// $write("pc next -> %x\n", PC_next);
				case(PCSource)
					0: PC <= alu_result;
					1: PC <= ALUOut;
					2: PC <= {PC[31:28], immj, 2'b00};
					3: PC <= A;
				endcase
			end 
		end
	end
	
	// instruction split
	assign opcode = IR[31:26];
	assign rs = IR[25:21];
	assign rt = IR[20:16];
	assign rd = IR[15:11];
	assign shamt = IR[10:6];
	assign funct = IR[5:0];
	assign immi = IR[15:0];
	assign immj = IR[25:0];
	// signExtend
	assign ext_imm = SignExtend ? {{16{immi[15]}}, immi} : {16'b0, immi};

	assign mem_addr = IorD?ALUOut:PC;

	CTRL ctrl (
		.opcode(opcode),
		.funct(funct),
		.rst(rst),
		.clk(clk),
		.RegDst(RegDst),
		.RegWrite(RegWrite),
		.ALUSrcA(ALUSrcA),
		.ALUSrcB(ALUSrcB),
		.ALUOp(ALUOp),
		.PCSource(PCSource),
		.IRWrite(IRWrite),
		.MemtoReg(MemtoReg),
		.MemWrite(MemWrite),
		.MemRead(MemRead),
		.IorD(IorD),
		.PCWrite(PCWrite),
		.PCWriteCond(PCWriteCond),
		.JR(JR),
		.SignExtend(SignExtend),
		.SavePC(SavePC)
	);
	
	MEM mem (
		.clk(clk),
		.rst(rst),
		.mem_addr(mem_addr),
		.MemWrite(MemWrite),
		.mem_write_data(B),
		.mem_read_data(mem_read_data)
	);

	RF rf (
		.clk(clk),
        .rst(rst),
        .rd_addr1(rs),
        .rd_addr2(rt),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2),
        .RegWrite(RegWrite),
        .wr_addr(wr_addr),
        .wr_data(wr_data)
	);
	
	assign operand1 = ALUSrcA?A:PC;
	assign operand2 = (ALUSrcB==0)?B:
					  (ALUSrcB==1)?32'd4:
					  (ALUSrcB==2)?ext_imm:
					  			  (ext_imm << 2);

	ALU alu (
		.operand1(operand1),
        .operand2(operand2),
        .shamt(shamt),
        .funct(ALUOp),
        .alu_result(alu_result)
	);

	assign alu_zero = (alu_result == 32'b1);
	assign wr_addr = SavePC ? 5'd31 : (RegDst ? rd : rt);
	assign wr_data = SavePC ? ALUOut : (MemtoReg ? MDR : ALUOut);

endmodule
