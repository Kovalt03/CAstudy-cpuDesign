#ifndef CTRL_H
#define CTRL_H

#include <stdint.h>

class CTRL {
public:
    CTRL();
	// You can fix these if you want ...
	struct Controls {
		uint32_t RegDst;
		uint32_t Jump;
		uint32_t Branch;
		uint32_t JR;
		uint32_t MemRead;
		uint32_t MemtoReg;
		uint32_t MemWrite;
		uint32_t ALUSrc;
		uint32_t SignExtend;
		uint32_t RegWrite;
		uint32_t ALUOp;
		uint32_t SavePC;

		void reset() {
			RegDst = Jump = Branch = JR = MemRead = MemtoReg = MemWrite = 0;
			ALUSrc = SignExtend = RegWrite = ALUOp = SavePC = 0;
		}
	};

	struct Controls_EX {
		uint32_t ALUSrc;
		uint32_t ALUOp;
		uint32_t RegDst;
		uint32_t SavePC;
		uint32_t Branch;
		uint32_t JR;
		uint32_t Jump;
		void reset() {
			ALUSrc = ALUOp = RegDst = SavePC = Branch = JR = Jump = 0;
		}
	};

	struct Controls_MEM {
		uint32_t MemWrite;
		uint32_t MemRead;
		uint32_t Branch;
		uint32_t SavePC;
		void reset() {
			MemWrite = MemRead = Branch = SavePC = 0;
		}
	};

	struct Controls_WB {
		uint32_t RegWrite;
		uint32_t MemtoReg;
		uint32_t SavePC;
		void reset() {
			RegWrite = MemtoReg = SavePC = 0;
		}
	};

	struct ParsedInst {
		uint32_t opcode;
		uint32_t rs;
		uint32_t rt;
		uint32_t rd;
		uint32_t shamt;
		uint32_t funct;
		uint32_t immi;
		uint32_t immj;
	};

	void controlSignal(uint32_t opcode, uint32_t funct, Controls *controls);
	void splitInst(uint32_t inst, ParsedInst *parsed_inst);
	void signExtend(uint32_t immi, uint32_t SignExtend, uint32_t *ext_imm);
};

#endif // CTRL_H
