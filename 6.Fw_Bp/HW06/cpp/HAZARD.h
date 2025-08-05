#ifndef HAZARD_H
#define HAZARD_H

#include <stdint.h>
#include "LATCH.h"

class HAZARD {
public:
    bool detectRAWStall(
        uint32_t rs_I, uint32_t rt_I, bool reads_rs, bool reads_rt,
        const ID_EX_Reg& ID_EX_curr,
        const EX_MEM_Reg& EX_MEM_curr,
        const MEM_WB_Reg& MEM_WB_curr
    );
};

#endif