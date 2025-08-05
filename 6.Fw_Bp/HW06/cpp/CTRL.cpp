#include <iostream>
#include "CTRL.h"
#include "ALU.h"
#include "globals.h"


CTRL::CTRL() {}

void CTRL::controlSignal(uint32_t opcode, uint32_t funct, Controls *controls) {
	// FILLME
	controls->reset();

	switch(opcode) {
		case OP_RTYPE: // R-type Instruction
			controls->RegDst = 1; // use rd
			controls->RegWrite = 1;
			switch (funct) {
				case FUNCT_ADDU:
					controls->ALUOp = ALU_ADDU;
					break;
				case FUNCT_AND:
					controls->ALUOp = ALU_AND;
					break;
				case FUNCT_NOR:
					controls->ALUOp = ALU_NOR;
					break;
				case FUNCT_OR:
					controls->ALUOp = ALU_OR;
					break;
				case FUNCT_SLT:
					controls->ALUOp = ALU_SLT;
					break;
				case FUNCT_SLTU:
					controls->ALUOp = ALU_SLTU;
					break;
				case FUNCT_SUBU:
					controls->ALUOp = ALU_SUBU;
					break;
				case FUNCT_XOR:
					controls->ALUOp = ALU_XOR;
					break;
				case FUNCT_SLL:
					controls->ALUOp = ALU_SLL;
					break;
				case FUNCT_SRA:
					controls->ALUOp = ALU_SRA;
					break;
				case FUNCT_SRL:
					controls->ALUOp = ALU_SRL;
					break;
				case FUNCT_JR:
					controls->JR = 1;
					controls->RegWrite = 0;
					controls->RegDst = 0; // if error erase!!!!!!
					break;
				default:
					status = UNSUPPORTED_ALU; // 지원하지 않는 funct 코드 처리
					break;
			}
			break;
		case OP_J: // J target
			controls->Jump = 1;
			break;
		case OP_JAL: // JAL target
			controls->Jump = 1;
			controls->SavePC = 1;
			controls->RegWrite = 1;
			break;
		case OP_BEQ: // BEQ rs, rt, offset
			controls->Branch = 1;
			controls->ALUOp = ALU_EQ;
			controls->SignExtend = 1;
			break;
		case OP_BNE: // BNE rs, rt, offset
			controls->Branch = 1;
			controls->ALUOp = ALU_NEQ;
			controls->SignExtend = 1;
			break;
		case OP_ADDIU: // ADDIU rt, rs, imm
			controls->ALUSrc = 1;
			controls->RegWrite = 1;
			controls->SignExtend = 1;
			controls->ALUOp = ALU_ADDU;
			break;
		case OP_ANDI: // ANDI rt, rs, imm
            controls->ALUSrc = 1;
            controls->RegWrite = 1;
            controls->ALUOp = ALU_AND;
            break;
        case OP_LUI: // LUI rt, imm
            controls->ALUSrc = 1;
            controls->RegWrite = 1;
            controls->ALUOp = ALU_LUI;
            break;
        case OP_ORI: // ORI rt, rs, imm
            controls->ALUSrc = 1;
            controls->RegWrite = 1;
            controls->ALUOp = ALU_OR;
            break;
		case OP_SLTI: // SLTI rt, rs, imm
			controls->ALUSrc = 1;
			controls->RegWrite = 1;
			controls->SignExtend = 1;
			controls->ALUOp = ALU_SLT;
			break;
		case OP_SLTIU: // SLTIU rt, rs, immm
			controls->ALUSrc = 1;
			controls->RegWrite = 1;
			controls->SignExtend = 1;
			controls->ALUOp = ALU_SLTU;
			break;
        case OP_XORI: // XORI rt, rs, imm
            controls->ALUSrc = 1;
            controls->RegWrite = 1;
            controls->ALUOp = ALU_XOR;
            break;
        case OP_LW: // LW, rt, offset(rs)
            controls->ALUSrc = 1;
            controls->MemtoReg = 1;
            controls->RegWrite = 1;
            controls->MemRead = 1;
            controls->SignExtend = 1;
            controls->ALUOp = ALU_ADDU;
            break;
        case OP_SW: // Sw rt, offset(rs)
            controls->ALUSrc = 1;
            controls->MemWrite = 1;
            controls->SignExtend = 1;
            controls->ALUOp = ALU_ADDU;
            break;
        default:
            status = INVALID_INST; // not valid instruction - error dectect
            break;
	}
}

void CTRL::splitInst(uint32_t inst, ParsedInst *parsed_inst) {
	// FILLME
	// shift 연산으로 옮기고 나머지 부분을 마스킹으로 0으로 만들어줌
	parsed_inst->opcode = (inst >> 26) & 0x3F; // [31:26] 11 1111 = 0x3F
    parsed_inst->rs = (inst >> 21) & 0x1F; // [25:21] 1 1111 = 0x1F
    parsed_inst->rt = (inst >> 16) & 0x1F; // [20:16] 1 1111 = 0x1F
    parsed_inst->rd = (inst >> 11) & 0x1F; // [15: 11] 1 1111 = 0x1F
    parsed_inst->shamt = (inst >> 6) & 0x1F; // [10:6] 1 1111 = 0x1F
    parsed_inst->funct = inst & 0x3F; // [5:0] 11 1111 = 0x3F
    parsed_inst->immi = inst & 0xFFFF; // [15:0] 1111 1111 1111 1111 = 0xFFFF
    parsed_inst->immj = inst & 0x3FFFFFF; // [25:0] 11 1111 1111 1111 1111 1111 1111= 0x3FFFFFF
}

// Sign extension using bitwise shift
void CTRL::signExtend(uint32_t immi, uint32_t SignExtend, uint32_t *ext_imm) {
	// FILLME
	if (SignExtend && (immi & 0x8000)) { // if signExtend and immi is neg
        *ext_imm = immi | 0xFFFF0000; // if neg fill 1 front
    } else {
        *ext_imm = immi & 0x0000FFFF; // if pos fill 0 front
    }
}
