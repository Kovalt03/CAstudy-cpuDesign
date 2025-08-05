#ifndef FORWARD_H
#define FORWARD_H

#include <stdint.h>
#include "LATCH.h"

struct Forward_mux {
    uint32_t ForwardA; // 00: regfile, 01: WB, 10: MEM
    uint32_t ForwardB;
};
class FORWARD {
public:
    Forward_mux Forwarding(uint32_t rs_I, uint32_t rt_I, const EX_MEM_Reg& EX_MEM_curr, const MEM_WB_Reg& MEM_WB_curr);
        
};

#endif