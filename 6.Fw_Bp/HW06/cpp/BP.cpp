#include "BP.h"
#include <iostream>
uint32_t BP::predict(uint32_t PC){
    uint32_t tag = (PC >> 8) & 0xFFFFFF;
    uint32_t idx = (PC >> 2) & 0x3F;
    uint8_t pht_idx = (PC >> 2) & 0xFF;
    if(btb[idx].valid == JUMP && btb[idx].tag == tag){
        return btb[idx].target;
    }
    if(btb[idx].valid == BRANCH && btb[idx].tag == tag && pht[pht_idx] >= 2){
        return btb[idx].target;
    }
    return PC + 4;
}

void BP::init() {
    for (int i = 0; i < 64; ++i) {
        btb[i].tag = 0xFFFFFFFF;
        btb[i].target = 0;
        btb[i].valid = NOTINITIALIZED;
    }
    for (int i = 0; i < 256; ++i) {
        pht[i] = 1; // weakly not taken
    }
}

void BP::update(uint32_t PC, bool taken, uint32_t target, uint32_t is_Jump, uint32_t is_Branch){
    uint32_t tag = (PC >> 8) & 0xFFFFFF;
    uint32_t idx = (PC >> 2) & 0x3F;
    uint8_t pht_idx = (PC >> 2) & 0xFF;
    // printf("update : %x\n", target);
    btb[idx].tag = tag;
    btb[idx].target = target;

    if(is_Jump){
        btb[idx].valid = JUMP;
    }else if(is_Branch){
        btb[idx].valid = BRANCH;
        uint32_t &history = pht[pht_idx];
        if (taken) {
            if (history < 3) history++; // 01→10→11
        } else {
            if (history > 0) history--; // 10→01→00
        }
    }
    
}