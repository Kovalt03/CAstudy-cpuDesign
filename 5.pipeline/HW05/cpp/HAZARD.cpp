#include "HAZARD.h"

#include <iostream>
using namespace std;

#define VERBOSE 0

bool HAZARD::detectRAWStall(
    uint32_t rs_I, uint32_t rt_I, bool reads_rs, bool reads_rt,
    const ID_EX_Reg& ID_EX_curr,
    const EX_MEM_Reg& EX_MEM_curr,
    const MEM_WB_Reg& MEM_WB_curr
) {
    if (ID_EX_curr.WB.RegWrite) {
        uint32_t wr_addr = ID_EX_curr.EX.SavePC ? 31 :
                   (ID_EX_curr.EX.RegDst ? ID_EX_curr.rd : ID_EX_curr.rt);
        if ((reads_rs && wr_addr == rs_I) || (reads_rt && wr_addr == rt_I)) {
            if (VERBOSE) cout << "[Hazard] RAW hazard on ID/EX stage\n";
            return true;
        }
    }

    if (EX_MEM_curr.WB.RegWrite) {
        if ((reads_rs && EX_MEM_curr.wr_addr == rs_I) || (reads_rt && EX_MEM_curr.wr_addr == rt_I)) {
            if (VERBOSE) cout << "[Hazard] RAW hazard on EX/MEM stage\n";
            return true;
        }
    }

    if (MEM_WB_curr.WB.RegWrite) {
        if ((reads_rs && MEM_WB_curr.wr_addr == rs_I) || (reads_rt && MEM_WB_curr.wr_addr == rt_I)) {
            if (VERBOSE) cout << "[Hazard] RAW hazard on MEM/WB stage\n";
            return true;
        }
    }

    return false;
}