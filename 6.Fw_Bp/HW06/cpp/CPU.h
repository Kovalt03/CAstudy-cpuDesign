#ifndef CPU_H
#define CPU_H

#include <stdint.h>
#include "ALU.h"
#include "RF.h"
#include "MEM.h"
#include "CTRL.h"
#include "HAZARD.h"
#include "FORWARD.h"
#include "BP.h"
#include "LATCH.h"

class CPU {
public:
    CPU(); // Constructor
	void init(std::string inst_file);
    uint32_t tick(); // Run simulation
    ALU alu;
    RF rf;
    CTRL ctrl;
	MEM mem;
    HAZARD hazard;
    FORWARD forward;
    Forward_mux fwd;
    BP bp;

    IF_ID_Reg IF_ID;
    ID_EX_Reg ID_EX;
    EX_MEM_Reg EX_MEM;
    MEM_WB_Reg MEM_WB;

	// Act like a storage element
	uint32_t PC;
    uint32_t cycle;


};



#endif // CPU_H

