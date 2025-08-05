#ifndef BP_H
#define BP_H

#define NOTINITIALIZED 0
#define JUMP 1
#define BRANCH 2
#include <stdint.h>

struct BTB {
    uint32_t tag;
    uint32_t target;
    uint32_t valid;
};
class BP {
public:
    BTB btb[64];
    uint32_t pht[256];
    
    uint32_t predict(uint32_t PC);
    void update(uint32_t PC, bool taken, uint32_t actual_target, uint32_t is_Jump, uint32_t is_Branch);
    void init();
};

#endif