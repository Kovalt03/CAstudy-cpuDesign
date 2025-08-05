    #include <iomanip>
    #include <iostream>
    #include "CPU.h"
    #include "globals.h"

    #define VERBOSE 0
    using namespace std;

    CPU::CPU() {}

    void CPU::init(string inst_file) {
        rf.init(false);
        mem.load(inst_file);
        PC = 0;
        IF_ID.reset();
        ID_EX.reset();
        EX_MEM.reset();
        MEM_WB.reset();
        status = CONTINUE;
        cycle = 0;
    }

    uint32_t CPU::tick() {
        if (status != CONTINUE) {
            return 0;
        }
        cycle++;
        if(VERBOSE) cout << "[" << dec << cycle << " Cycle]" << endl;
        IF_ID_Reg IF_ID_curr = IF_ID;
        ID_EX_Reg ID_EX_curr = ID_EX;
        EX_MEM_Reg EX_MEM_curr = EX_MEM;
        MEM_WB_Reg MEM_WB_curr = MEM_WB;
        IF_ID_Reg IF_ID_next; IF_ID_next.reset();
        ID_EX_Reg ID_EX_next; ID_EX_next.reset();
        EX_MEM_Reg EX_MEM_next; EX_MEM_next.reset();
        MEM_WB_Reg MEM_WB_next; MEM_WB_next.reset();

        uint32_t inst;
        CTRL::ParsedInst parsed_inst;
        CTRL::Controls controls;
        uint32_t ext_imm;
        uint32_t operand1, operand2;
        uint32_t rs_data, rt_data;
        uint32_t alu_result;
        uint32_t mem_data = 0;
        uint32_t PC_target_for_branch_jump = 0;
        bool stall = false;
        bool branch_taken = EX_MEM_curr.branch_taken;

         // --- HAZARD DETECTION ---
         if (IF_ID_curr.inst != 0) {
            CTRL::ParsedInst parsed_inst_hazard;
            ctrl.splitInst(IF_ID_curr.inst, &parsed_inst_hazard);
            uint32_t rs_I = parsed_inst_hazard.rs;
            uint32_t rt_I = parsed_inst_hazard.rt;
            
            uint32_t opcode_I = parsed_inst_hazard.opcode;
            uint32_t funct_I = parsed_inst_hazard.funct;
            uint32_t shamt_I = parsed_inst_hazard.shamt;

            bool use_rs = false;
            bool use_rt = false;

            if (opcode_I == OP_RTYPE) {
                if (funct_I == FUNCT_JR) use_rs = true;
                else if (funct_I == FUNCT_ADDU || funct_I == FUNCT_SUBU ||
                         funct_I == FUNCT_AND || funct_I == FUNCT_OR  ||
                         funct_I == FUNCT_XOR || funct_I == FUNCT_NOR ||
                         funct_I == FUNCT_SLT || funct_I == FUNCT_SLTU) {
                    use_rs = true;
                    use_rt = true;
                } else if (funct_I == FUNCT_SLL || funct_I == FUNCT_SRL || funct_I == FUNCT_SRA) {
                    use_rt = true;
                }
            } else if (opcode_I == OP_ADDIU ||
                       opcode_I == OP_SLTI || opcode_I == OP_SLTIU ||
                       opcode_I == OP_ANDI || opcode_I == OP_ORI  ||
                       opcode_I == OP_XORI || opcode_I == OP_LUI) {
                use_rs = true;
            } else if (opcode_I == OP_BEQ || opcode_I == OP_BNE) {
                use_rs = true;
                use_rt = true;
            } else if (opcode_I == OP_LW) {
                use_rs = true;
            } else if (opcode_I == OP_SW) {
                use_rs = true;
                use_rt = true;
            }

            stall = hazard.detectRAWStall(
                rs_I, rt_I, use_rs, use_rt,
                ID_EX_curr,
                EX_MEM_curr,
                MEM_WB_curr
            );
        }
        
        // IF
        uint32_t PC_next = PC;
        // bool flush = EX_MEM_curr.branch_taken;
        // bool flush = false;
        // if (flush) {
        //     PC_next = EX_MEM_curr.PC;
        //     cout << "MISS PREDICT JUMP to " << hex << PC << endl;
        //     IF_ID_next.reset();
        // } else 
        if (stall) {
            IF_ID_next = IF_ID_curr;
            PC_next = PC;
        } else {
            mem.imemAccess(PC, &inst);
            PC_next = PC + 4;
            
            IF_ID_next.PC = PC + 4;
            IF_ID_next.inst = inst;
        }
        if (VERBOSE) {
            cout << "IF: Fetched inst 0x" << hex << setw(8) << setfill('0') << inst << dec
                << " from PC 0x" << setw(8) << setfill('0') << hex << PC << " " << IF_ID_curr.PC << dec
                << ". Next PC will be 0x" << hex << PC_next << dec;
            if(stall) cout << " - Stalled ";
            cout << endl;
        }

        // ID
        // if (flush) {
        //     ID_EX_next.reset();
        //     if (VERBOSE) cout << "ID: FLUSH" << endl;
        // } else 
        if (stall) {
            ID_EX_next.reset();
            if (VERBOSE) cout << "ID : STALLed inserting NOP into ID_EX save 0x" << hex << IF_ID_curr.PC -0x4 << endl;
        } else {
            if (IF_ID_curr.inst != 0) {
                ctrl.splitInst(IF_ID_curr.inst, &parsed_inst);
                ctrl.controlSignal(parsed_inst.opcode, parsed_inst.funct, &controls);

                ctrl.signExtend(parsed_inst.immi, controls.SignExtend, &ext_imm);
                rf.read(parsed_inst.rs, parsed_inst.rt, &rs_data, &rt_data);

                ID_EX_next.PC = IF_ID_curr.PC;
                ID_EX_next.JAL_return_address = IF_ID_curr.PC;
                ID_EX_next.read_data1 = rs_data;
                ID_EX_next.read_data2 = rt_data;
                ID_EX_next.ext_imm = ext_imm;
                ID_EX_next.rs = parsed_inst.rs;
                ID_EX_next.rt = parsed_inst.rt;
                ID_EX_next.rd = parsed_inst.rd;
                ID_EX_next.shamt = parsed_inst.shamt;
                ID_EX_next.immj = parsed_inst.immj;

                ID_EX_next.WB.RegWrite  = controls.RegWrite;
                ID_EX_next.WB.MemtoReg  = controls.MemtoReg;
                ID_EX_next.WB.SavePC    = controls.SavePC;

                ID_EX_next.M.MemWrite   = controls.MemWrite;
                ID_EX_next.M.MemRead    = controls.MemRead;
                ID_EX_next.M.Branch     = controls.Branch;
                ID_EX_next.M.SavePC     = controls.SavePC;

                ID_EX_next.EX.ALUSrc    = controls.ALUSrc;
                ID_EX_next.EX.ALUOp     = controls.ALUOp;
                ID_EX_next.EX.RegDst    = controls.RegDst;
                ID_EX_next.EX.SavePC    = controls.SavePC;
                ID_EX_next.EX.Branch    = controls.Branch;
                ID_EX_next.EX.JR        = controls.JR;
                ID_EX_next.EX.Jump      = controls.Jump;

                if (VERBOSE) {
                    cout << "ID: Processing inst 0x" << hex << IF_ID_curr.inst << dec << " (PC=0x" << IF_ID_curr.PC - 0x4 << dec << ")" << endl;
                }
            } else {
                ID_EX_next.reset();
                if (VERBOSE) cout << "ID: NOP" << endl;
            }
        }

        // EX
        // if(flush){
        //     EX_MEM_next.reset();
        // }else 
        {
            operand1 = ID_EX_curr.read_data1;
            operand2 = ID_EX_curr.EX.ALUSrc ? ID_EX_curr.ext_imm : ID_EX_curr.read_data2;
            alu.compute(operand1, operand2, ID_EX_curr.shamt, ID_EX_curr.EX.ALUOp, &alu_result);
            // cout << "ALU : PC 0x" << hex << ID_EX_curr.PC - 0x4 << " result : " << alu_result << endl;

            EX_MEM_next.PC = ID_EX_curr.PC + (ID_EX_curr.ext_imm << 2);
            EX_MEM_next.alu_result = alu_result;
            EX_MEM_next.zero = (alu_result);
            EX_MEM_next.mem_wr_data = ID_EX_curr.read_data2;

            if (ID_EX_curr.EX.SavePC) {
                EX_MEM_next.wr_addr = 31;
            } else {
                EX_MEM_next.wr_addr = ID_EX_curr.EX.RegDst ? ID_EX_curr.rd : ID_EX_curr.rt;
            }

            EX_MEM_next.WB = ID_EX_curr.WB;
            EX_MEM_next.M = ID_EX_curr.M;
            EX_MEM_next.JAL_return_address = ID_EX_curr.JAL_return_address;

            if (ID_EX_curr.EX.Branch) {
                if (EX_MEM_next.zero) {
                    EX_MEM_next.PC = ID_EX_curr.PC + (ID_EX_curr.ext_imm << 2);
                    EX_MEM_next.branch_taken = true;
                }
            } else if (ID_EX_curr.EX.JR) {
                EX_MEM_next.PC = ID_EX_curr.read_data1;
                EX_MEM_next.branch_taken = true;
            } else if (ID_EX_curr.EX.Jump) {
                EX_MEM_next.PC = (ID_EX_curr.PC & 0xF0000000) | (ID_EX_curr.immj << 2);
                EX_MEM_next.branch_taken = true;
            }
        }
        if(EX_MEM_next.branch_taken){
            printf("flush\n");
            IF_ID_next.reset();
            ID_EX_next.reset();
            PC_next = EX_MEM_next.PC;
        }

        // MEM
        mem.dmemAccess(EX_MEM_curr.alu_result, &mem_data, EX_MEM_curr.mem_wr_data, EX_MEM_curr.M.MemRead, EX_MEM_curr.M.MemWrite);
        // cout << "MEM : " << mem_data << endl;
        MEM_WB_next.mem_data = mem_data;
        MEM_WB_next.alu_result = EX_MEM_curr.alu_result;
        MEM_WB_next.wr_addr = EX_MEM_curr.wr_addr;
        MEM_WB_next.WB = EX_MEM_curr.WB;
        MEM_WB_next.JAL_return_address = EX_MEM_curr.JAL_return_address;

        // WB
        uint32_t wb_wr_addr = MEM_WB_curr.wr_addr;
        uint32_t wb_wr_data;
        if(MEM_WB_curr.WB.SavePC) {
            wb_wr_data = MEM_WB_curr.JAL_return_address;
        } else {
            wb_wr_data = MEM_WB_curr.WB.MemtoReg? MEM_WB_curr.mem_data : MEM_WB_curr.alu_result;
        }

        rf.write(wb_wr_addr, wb_wr_data, MEM_WB_curr.WB.RegWrite);

        if (VERBOSE) {
            const char reg_name[REGSIZE][6] = {
                "$zero", "$at", "$v0", "$v1", "$a0", "$a1", "$a2", "$a3",
                "$t0", "$t1", "$t2", "$t3", "$t4", "$t5", "$t6", "$t7", 
                "$s0", "$s1", "$s2", "$s3", "$s4", "$s5", "$s6", "$s7", 
                "$t8", "$t9", "$k0", "$k1", "$gp", "$sp", "$fp", "$ra"
            };
            if (MEM_WB_curr.WB.RegWrite) {
                if (wb_wr_addr != 0) {
                    cout << "WB: Write R" << wb_wr_addr << " (" << dec << reg_name[wb_wr_addr] << ") <= 0x" << hex << wb_wr_data << endl;
                }
            }
        }        

        IF_ID = IF_ID_next;
        ID_EX = ID_EX_next;
        EX_MEM = EX_MEM_next;
        MEM_WB = MEM_WB_next;
        
        PC = PC_next;

        return status == CONTINUE ? 1 : 0;
    }
