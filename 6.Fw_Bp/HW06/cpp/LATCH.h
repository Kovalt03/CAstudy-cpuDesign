#ifndef LATCH_H
#define LATCH_H

#include <stdint.h>
#include "CTRL.h"

struct IF_ID_Reg {
    uint32_t PC;
    uint32_t bh_PC;
    uint32_t inst;

    IF_ID_Reg() { reset(); }
    void reset() {
        PC = 0;
        bh_PC = 0;
        inst = 0;
    }
};

struct ID_EX_Reg {
    uint32_t PC;
    uint32_t bh_PC;
    uint32_t JAL_return_address;
    uint32_t read_data1;
    uint32_t read_data2;
    uint32_t ext_imm;
    uint32_t rs, rt, rd, shamt, immj;
    CTRL::Controls_WB WB; // Control signals for WB stage
    CTRL::Controls_MEM M;  // Control signals for M stage
    CTRL::Controls_EX EX; // Control signals for EX stage

    ID_EX_Reg() { reset(); }
    void reset() {
        PC = 0;
        bh_PC = 0;
        JAL_return_address = 0;
        read_data1 = 0;
        read_data2 = 0;
        ext_imm = 0;
        rs = 0; rt = 0; rd = 0; shamt = 0; immj = 0;
        WB.reset();
        M.reset();
        EX.reset();
    }
};

struct EX_MEM_Reg {
    uint32_t PC;
    uint32_t alu_result;
    uint32_t zero;
    uint32_t mem_wr_data; // Data to be written to memory (from ID_EX.read_data2)
    uint8_t wr_addr;      // Destination register
    
    CTRL::Controls_WB WB; // Control signals for WB stage
    CTRL::Controls_MEM M;  // Control signals for M stage
    uint32_t JAL_return_address; // For JAL
    bool branch_taken;

    EX_MEM_Reg() { reset(); }
    void reset() {
        PC = 0;
        alu_result = 0;
        zero = false; // Or true, depending on NOP alu_result
        mem_wr_data = 0;
        wr_addr = 0;
        WB.reset();
        M.reset();
        JAL_return_address = 0;
        branch_taken = false;
    }
};

struct MEM_WB_Reg {
    uint32_t mem_data;   // Data read from memory
    uint32_t alu_result; // ALU result from EX stage
    uint8_t wr_addr;     // Destination register

    CTRL::Controls_WB WB; // Control signals for WB stage
    uint32_t JAL_return_address; // For JAL

    MEM_WB_Reg() { reset(); }
    void reset() {
        mem_data = 0;
        alu_result = 0;
        wr_addr = 0;
        WB.reset();
        JAL_return_address = 0;
    }
};

#endif