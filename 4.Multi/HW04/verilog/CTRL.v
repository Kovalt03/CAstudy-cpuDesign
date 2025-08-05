`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,
	input		rst,
	input		clk,

	// output various ports
	output reg RegDst,
	output reg RegWrite,
	output reg ALUSrcA,
	output reg [3:0] ALUSrcB,
	output reg [3:0] ALUOp,
	output reg [3:0] PCSource,
	output reg IRWrite,
	output reg MemtoReg,
	output reg MemWrite,
	output reg MemRead,
	output reg IorD,
	output reg PCWrite,
	output reg PCWriteCond,
	output reg JR,
	output reg SignExtend,
	output reg SavePC

    );

	reg [4:0]	state, nextState;
	// for FSM next
	always @(posedge clk) begin
		if (rst) begin
			// $write("reset ctrl\n");
			state <= `STATE_IF;
			nextState <= `STATE_ID;
		end
		else begin
			state <= nextState;
		end
	end

	always @(*) begin
		// $write("state[%d] : %d\n", state, opcode);
		case (state)
			`STATE_IF: begin
				nextState <= `STATE_ID;
			end
			`STATE_ID: begin
				// if (opcode == `OP_RTYPE && funct == `FUNCT_JR) // JR
				// 	nextState <= `STATE_IF;
				// else
				nextState <= `STATE_EX;
			end
			`STATE_EX: begin
				case (opcode)
					`OP_BEQ, `OP_BNE, `OP_J: begin
						// $write("JUMP\n");
						nextState <= `STATE_IF; // BEQ, BNE, J
					end
					`OP_RTYPE: begin
						if(funct == `FUNCT_JR) nextState <= `STATE_IF;
						else nextState <= `STATE_WB;
					end
					`OP_ADDIU, `OP_LUI, `OP_ORI, `OP_ANDI, `OP_SLTI, `OP_XORI, `OP_SLTIU, `OP_JAL: nextState <= `STATE_WB;
					default: nextState <= `STATE_MEM;
				endcase
			end
			`STATE_MEM: begin
				if(opcode == `OP_SW)
					nextState <= `STATE_IF;
				else if (opcode == `OP_LW) // LW
					nextState <= `STATE_WB;
				else
					nextState <= `STATE_WB;
			end
			`STATE_WB: nextState <= `STATE_IF;
		endcase
	// end

	// always @(*) begin
		// FIXME
		// Reset controls
		// $write("ctrl ");
		RegDst = 0;
		PCSource = 0;
		SignExtend = 0;
		RegWrite = 0;
		ALUOp = 0;
		SavePC = 0;
		IRWrite = 0;
		IorD = 0;
		PCWrite = 0;
		ALUSrcA = 0;
		ALUSrcB = 0;
		MemRead = 0;
		MemtoReg = 0;
		MemWrite = 0;
		PCWriteCond = 0;

		case (state)
            `STATE_IF: begin
				MemRead = 1;
				IRWrite = 1;
				PCWrite = 1;
				ALUSrcA = 0;
				ALUSrcB = 1;
				ALUOp = `ALU_ADDU;
			end
			`STATE_ID: begin
				ALUSrcA = 0;
				ALUSrcB = 3;
				SignExtend = 1;
				ALUOp = `ALU_ADDU;
			end
			`STATE_EX: begin
				case (opcode)
					`OP_RTYPE: begin
						RegDst = 1;
						ALUSrcA = 1;
						ALUSrcB = 0;
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
								// $write("JR\n");
								PCSource = 3;
								PCWrite = 1;
							end
						endcase
					end
					`OP_J: begin
						PCSource = 2;
						PCWrite = 1;
					end
					`OP_JAL: begin
						PCSource = 2;
						PCWrite = 1;
					end
					`OP_BEQ: begin
						ALUSrcA = 1;
						ALUSrcB = 0;
						PCWriteCond = 1;
						PCSource = 1;
						ALUOp = `ALU_EQ;
					end
					`OP_BNE: begin
						ALUSrcA = 1;
						ALUSrcB = 0;
						PCWriteCond = 1;
						PCSource = 1;
						ALUOp = `ALU_NEQ;
					end
					`OP_ADDIU: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 1;
						ALUOp = `ALU_ADDU;
					end
					`OP_ANDI: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 0;
						ALUOp = `ALU_AND;
					end
					`OP_LUI: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 0;
						ALUOp = `ALU_LUI;
					end
					`OP_ORI: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 0;
						ALUOp = `ALU_OR;
					end
					`OP_SLTI: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 1;
						ALUOp = `ALU_SLT;
					end
					`OP_SLTIU: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 1;
						ALUOp = `ALU_SLTU;
					end
					`OP_XORI: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 0;
						ALUOp = `ALU_XOR;
					end
					`OP_LW: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 1;
						ALUOp = `ALU_ADDU;
					end
					`OP_SW: begin
						ALUSrcA = 1;
						ALUSrcB = 2;
						SignExtend = 1;
						ALUOp = `ALU_ADDU;
					end
					default: begin
						// ALUOp = `ALU_NOP;
						// invalid instruction, do nothing (or signal error)
					end
				endcase
			end
			`STATE_MEM: begin
                case (opcode)
					`OP_LW: begin
						MemRead = 1;
						IorD = 1;
					end
					`OP_SW: begin
						MemWrite = 1;
						IorD = 1;
					end
				endcase
			end
			`STATE_WB: begin
				case (opcode)
					`OP_RTYPE: begin
						RegWrite = 1;
						MemtoReg = 0;
						RegDst = 1;
					end
					`OP_SW: begin
						RegWrite = 0;
						MemtoReg = 0;
					end
					`OP_LW: begin
						RegWrite = 1;
						MemtoReg = 1;
					end
					`OP_JAL: begin
						SavePC = 1;
						RegWrite = 1;
					end
					`OP_ADDIU, `OP_LUI, `OP_ORI, `OP_ANDI, `OP_SLTI, `OP_XORI,`OP_SLTIU: begin
						RegWrite = 1;
						MemtoReg = 0;
					end
				endcase
			end
		endcase
		// $write("state : %d ID: %d IR : %d done\n", state, IorD, IRWrite);
	end
endmodule
