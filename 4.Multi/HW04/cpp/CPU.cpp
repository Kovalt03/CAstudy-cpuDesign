#include <iomanip>
#include <iostream>
#include "CPU.h"
#include "globals.h"

#define VERBOSE 0

using namespace std;

CPU::CPU() {}

// Reset stateful modules
void CPU::init(string inst_file) {
	// Initialize the register file
	rf.init(false);
	// Load the instructions from the memory
	mem.load(inst_file);
	// Reset the program counter
	PC = 0;
	IR = 0;
	A = 0;
	B = 0;
	ALUOut = 0;
	// Set the debugging status
	status = CONTINUE;
	ctrl.resetFSM();
}

// This is a cycle-accurate simulation
uint32_t CPU::tick() {
	// These are just one of the implementations ...

	// wire for instruction
	// uint32_t inst;

	// parsed & control signals (wire)
	CTRL::ParsedInst parsed_inst;
	CTRL::Controls controls;
	uint32_t ext_imm;

	// Default wires and control signals
	uint32_t rs_data, rt_data;
	uint32_t wr_addr;
	uint32_t wr_data;
	uint32_t operand1;
	uint32_t operand2;
	uint32_t alu_result;
	uint32_t zero; // HW04

	// PC_next
	// uint32_t PC_next;

	// You can declare your own wires (if you want ...)
	uint32_t mem_data;
	uint32_t mem_addr;

	//IF or MEM
	ctrl.splitInst(IR, &parsed_inst);
    ctrl.controlSignal(parsed_inst.opcode, parsed_inst.funct, &controls);
	if (status != CONTINUE) return 0;

	if(controls.IorD){
		mem_addr = ALUOut;
	}else{
		mem_addr = PC;
	}
	// if(controls.MemWrite) printf("%d %d", B, mem_addr);
	mem.memAccess(mem_addr, &mem_data, B, controls.MemRead, controls.MemWrite);

	// if(controls.MemWrite) cout << hex << setw(8) << setfill('0') << "Memory : " << mem_addr << " : " << B << endl;
	
	if(mem_data==0) { // IF instruction end TERMINATE
		status = TERMINATE;
		return 0;
	}
	if (status != CONTINUE) return 0; // MEM

	// ID
	rf.read(parsed_inst.rs, parsed_inst.rt, &rs_data, &rt_data);
	// A = rs_data;
	// B = rt_data;

	operand1 = (controls.ALUSrcA)?A:PC;
	ctrl.signExtend(parsed_inst.immi, controls.SignExtend, &ext_imm);
	switch(controls.ALUSrcB){
		case 0: operand2 = B; break;
		case 1: operand2 = 4; break;
		case 2: 
			operand2 = ext_imm;
			break;
		case 3:
			operand2 = ext_imm << 2;
			break;
	}
	if (status != CONTINUE) return 0;

	// EX
	alu.compute(operand1, operand2, parsed_inst.shamt, controls.ALUOp, &alu_result);
	zero = alu_result;	
	if (controls.PCWrite || (controls.PCWriteCond && zero)) {
        switch (controls.PCSource) {
            case 0: PC = alu_result; break;
            case 1: PC = ALUOut; break;
            case 2: PC = (PC & 0xF0000000) | (parsed_inst.immj << 2); break;
            case 3: PC = A; break; // JR
        }
    }
	if (status != CONTINUE) return 0; // EX


	// WB
	if (controls.SavePC){
		wr_addr = 31; // save r31($ra)
		wr_data = ALUOut; // For JAL
	}else{ 
		wr_addr = controls.RegDst ? parsed_inst.rd : parsed_inst.rt;
		wr_data = controls.MemtoReg ? MDR : ALUOut;
	}

	rf.write(wr_addr, wr_data, controls.RegWrite);

	const char reg_name[REGSIZE][6] = {
		"$zero", "$at", "$v0", "$v1", "$a0", "$a1", "$a2", "$a3",
		"$t0", "$t1", "$t2", "$t3", "$t4", "$t5", "$t6", "$t7", 
		"$s0", "$s1", "$s2", "$s3", "$s4", "$s5", "$s6", "$s7", 
		"$t8", "$t9", "$k0", "$k1", "$gp", "$sp", "$fp", "$ra"
	};
	// if(controls.RegWrite) cout << reg_name[wr_addr] << " : " << wr_data << endl;
	if (status != CONTINUE) return 0;
	
	ALUOut = alu_result;
	MDR = mem_data;
	A = rs_data;
	B = rt_data;
	if(controls.IRWrite) {
		IR = mem_data;
		// cout << "PC: " << hex << setw(8) << setfill('0') << PC << " ";
		// cout << "inst : " << hex << setw(8) << setfill('0') << IR << "\n";
	}
	
	ctrl.nextState(parsed_inst.opcode,parsed_inst.funct);
	if (status != CONTINUE) return 0;
	
	return 1;
}

