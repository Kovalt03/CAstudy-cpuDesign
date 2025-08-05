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

	// Set the debugging status
	status = CONTINUE;
}

// This is a cycle-accurate simulation
uint32_t CPU::tick() {
	// These are just one of the implementations ...

	// wire for instruction
	uint32_t inst;

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

	// PC_next
	uint32_t PC_next;

	// You can declare your own wires (if you want ...)
	uint32_t mem_data;
	//...


	// Access the instruction memory
	mem.imemAccess(PC, &inst); // read instruction from instruction memory
	// cout << "PC: " << hex << setw(8) << setfill('0') << PC << " ";
	// cout << "inst : " << hex << setw(8) << setfill('0') << inst << "\n";
	if (status != CONTINUE) return 0; // IF
	
	// Split the instruction & set the control signals
	ctrl.splitInst(inst, &parsed_inst); // split instruction by MIPS instruction
	ctrl.controlSignal(parsed_inst.opcode, parsed_inst.funct, &controls); 
	ctrl.signExtend(parsed_inst.immi, controls.SignExtend, &ext_imm); // if SignExtend -> extend immi
	if (status != CONTINUE) return 0; // ID

	// read rf, read paresd_int's rs, rt from register
	rf.read(parsed_inst.rs, parsed_inst.rt, &rs_data, &rt_data);

	// cout << "inst: " << hex << inst << endl;
	// cout << "opcode: " << dec << parsed_inst.opcode << ", rs: " << parsed_inst.rs
	// 	<< ", rt: " << parsed_inst.rt
	// 	<< ", rd: " << parsed_inst.rd
	// 	<< ", funct: " << parsed_inst.funct << endl;

	// EX
	operand1 = rs_data;
	operand2 = controls.ALUSrc?ext_imm:rt_data;
	alu.compute(operand1, operand2, parsed_inst.shamt, controls.ALUOp, &alu_result);
	if (status != CONTINUE) return 0; // EX

	// MEM (+PC Update)
	mem.dmemAccess(alu_result, &mem_data, rt_data, controls.MemRead, controls.MemWrite);
	if(controls.MemWrite) cout << hex << setw(8) << setfill('0') << alu_result << " : " << rt_data << endl;
	if (status != CONTINUE) return 0; //MEM

	// WB
	if (controls.SavePC){
		wr_addr = 31; // save r31($ra)
		wr_data = PC + 4; // For JAL
	}else{ 
		wr_addr = controls.RegDst ? parsed_inst.rd : parsed_inst.rt;
		if (controls.MemtoReg){
			wr_data = mem_data; // Load word
		}else {
			wr_data = alu_result;
		}
	}

	rf.write(wr_addr, wr_data, controls.RegWrite);
	if (status != CONTINUE) return 0; // WB

	const char reg_name[REGSIZE][6] = {
		"$zero", "$at", "$v0", "$v1", "$a0", "$a1", "$a2", "$a3",
		"$t0", "$t1", "$t2", "$t3", "$t4", "$t5", "$t6", "$t7", 
		"$s0", "$s1", "$s2", "$s3", "$s4", "$s5", "$s6", "$s7", 
		"$t8", "$t9", "$k0", "$k1", "$gp", "$sp", "$fp", "$ra"
	};
	// if(controls.RegWrite) cout << reg_name[wr_addr] << " : " << wr_data << endl;
	// Update the PC
	if (controls.Jump) {
		PC_next = (PC & 0xF0000000) | (parsed_inst.immj << 2);
	} else if (controls.JR) {
		PC_next = rs_data;
	} else if (controls.Branch) {
		if (controls.ALUOp == ALU_EQ && alu_result)
			PC_next = PC + 4 + (ext_imm << 2);
		else if (controls.ALUOp == ALU_NEQ && alu_result)
			PC_next = PC + 4 + (ext_imm << 2);
		else 
			PC_next = PC + 4;
	} else {
		PC_next = PC + 4;
	}
	// Update the PC register last ...
	PC = PC_next;

	return 1;
}

