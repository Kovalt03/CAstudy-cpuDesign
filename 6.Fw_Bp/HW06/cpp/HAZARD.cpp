#include "HAZARD.h"

#include <iostream>
using namespace std;

#define VERBOSE 0

bool HAZARD::detectRAWStall(
    uint32_t rs_I, uint32_t rt_I, bool use_rs, bool use_rt,
    const ID_EX_Reg& ID_EX_curr,
    const EX_MEM_Reg& EX_MEM_curr,
    const MEM_WB_Reg& MEM_WB_curr
) {
    if (ID_EX_curr.M.MemRead) {
        uint32_t ex_dst = ID_EX_curr.EX.RegDst ? ID_EX_curr.rd : ID_EX_curr.rt;

        if (ex_dst != 0 &&((use_rs && ex_dst == rs_I) || (use_rt && ex_dst == rt_I))) {
            // printf("stall\n");
            return true;
        }
    }
    return false;
}