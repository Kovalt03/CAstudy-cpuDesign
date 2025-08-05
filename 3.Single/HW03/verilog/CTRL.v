`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	// output various ports
	output reg RegDst,
	output reg Jump,
	output reg Branch,
	output reg JR,
	output reg MemRead,
	output reg MemtoReg,
	output reg MemWrite,
	output reg ALUSrc,
	output reg SignExtend,
	output reg RegWrite,
	output reg [3:0] ALUOp,
	output reg SavePC
    );

	always @(*) begin
		// FIXME
		// Reset controls
		RegDst     = 0;
		RegWrite   = 0;
		ALUSrc     = 0;
		ALUOp      = 0;
		MemRead    = 0;
		MemWrite   = 0;
		MemtoReg   = 0;
		Branch     = 0;
		Jump       = 0;
		JR         = 0;
		SavePC     = 0;
		SignExtend = 0;

		case (opcode)
			`OP_RTYPE: begin
				RegDst   = 1;
				RegWrite = 1;
				case (funct)
					`FUNCT_ADDU: ALUOp = `ALU_ADDU;
					`FUNCT_AND:  ALUOp = `ALU_AND;
					`FUNCT_NOR:  ALUOp = `ALU_NOR;
					`FUNCT_OR:   ALUOp = `ALU_OR;
					`FUNCT_SLT:  ALUOp = `ALU_SLT;
					`FUNCT_SLTU: ALUOp = `ALU_SLTU;
					`FUNCT_SUBU: ALUOp = `ALU_SUBU;
					`FUNCT_XOR:  ALUOp = `ALU_XOR;
					`FUNCT_SLL:  ALUOp = `ALU_SLL;
					`FUNCT_SRA:  ALUOp = `ALU_SRA;
					`FUNCT_SRL:  ALUOp = `ALU_SRL;
					`FUNCT_JR: begin
						JR = 1;
						RegWrite = 0;
						RegDst = 0;
					end
					default: ALUOp = 4'd15; // unsupported
				endcase
			end
			`OP_J: begin
				Jump = 1;
			end
			`OP_JAL: begin
				Jump = 1;
				SavePC = 1;
				RegWrite = 1;
			end
			`OP_BEQ: begin
				Branch = 1;
				SignExtend = 1;
				ALUOp = `ALU_EQ;
			end
			`OP_BNE: begin
				Branch = 1;
				SignExtend = 1;
				ALUOp = `ALU_NEQ;
			end
			`OP_ADDIU: begin
				ALUSrc = 1;
				RegWrite = 1;
				SignExtend = 1;
				ALUOp = `ALU_ADDU;
			end
			`OP_ANDI: begin
				ALUSrc = 1;
				RegWrite = 1;
				ALUOp = `ALU_AND;
			end
			`OP_LUI: begin
				ALUSrc = 1;
				RegWrite = 1;
				ALUOp = `ALU_LUI;
			end
			`OP_ORI: begin
				ALUSrc = 1;
				RegWrite = 1;
				ALUOp = `ALU_OR;
			end
			`OP_SLTI: begin
				ALUSrc = 1;
				RegWrite = 1;
				SignExtend = 1;
				ALUOp = `ALU_SLT;
			end
			`OP_SLTIU: begin
				ALUSrc = 1;
				RegWrite = 1;
				SignExtend = 1;
				ALUOp = `ALU_SLTU;
			end
			`OP_XORI: begin
				ALUSrc = 1;
				RegWrite = 1;
				ALUOp = `ALU_XOR;
			end
			`OP_LW: begin
				ALUSrc = 1;
				MemtoReg = 1;
				RegWrite = 1;
				MemRead = 1;
				SignExtend = 1;
				ALUOp = `ALU_ADDU;
			end
			`OP_SW: begin
				ALUSrc = 1;
				MemWrite = 1;
				SignExtend = 1;
				ALUOp = `ALU_ADDU;
			end
			default: begin
				// invalid instruction, do nothing (or signal error)
			end
		endcase
	end
endmodule
