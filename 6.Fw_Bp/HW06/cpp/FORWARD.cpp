#include "FORWARD.h"

#include <iostream>
using namespace std;

Forward_mux FORWARD::Forwarding(uint32_t rs_I, uint32_t rt_I, const EX_MEM_Reg& EX_MEM, const MEM_WB_Reg& MEM_WB){
    Forward_mux fwd;
    fwd.ForwardA = 0;
    fwd.ForwardB = 0;

    // Forward A
    if (EX_MEM.WB.RegWrite && EX_MEM.wr_addr != 0 && EX_MEM.wr_addr == rs_I)
        fwd.ForwardA = 2; // from MEM
    else if (MEM_WB.WB.RegWrite && MEM_WB.wr_addr != 0 && MEM_WB.wr_addr == rs_I)
        fwd.ForwardA = 1; // from WB

    // Forward B
    if (EX_MEM.WB.RegWrite && EX_MEM.wr_addr != 0 && EX_MEM.wr_addr == rt_I)
        fwd.ForwardB = 2; // from MEM
    else if (MEM_WB.WB.RegWrite && MEM_WB.wr_addr != 0 && MEM_WB.wr_addr == rt_I)
        fwd.ForwardB = 1; // from WB
    // if(fwd.ForwardA + fwd.ForwardB > 0) printf("forward\n");
    return fwd;
}