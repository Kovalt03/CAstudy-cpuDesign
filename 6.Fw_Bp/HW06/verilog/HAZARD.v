module HAZARD (
    input  [31:0] inst,
    input  [4:0] rs_I,
    input  [4:0] rt_I,
    input  [5:0] funct_I,
    input  [5:0] opcode_I,

    input  [4:0] EX_rd,
    input        EX_MemRead,
    input        EX_RegDst,
    input  [4:0] EX_rt,

    output reg stall
);

    wire [4:0] ex_dst;
    wire    use_rs;
    wire    use_rt;

    assign ex_dst = EX_RegDst ? EX_rd : EX_rt;
    assign use_rs = ((opcode_I == `OP_RTYPE) && (funct_I == `FUNCT_JR ||
                                                            funct_I == `FUNCT_ADDU || funct_I == `FUNCT_SUBU ||
                                                            funct_I == `FUNCT_AND || funct_I == `FUNCT_OR ||
                                                            funct_I == `FUNCT_XOR || funct_I == `FUNCT_NOR ||
                                                            funct_I == `FUNCT_SLT || funct_I == `FUNCT_SLTU)) ||
                               ((opcode_I == `OP_ADDIU || opcode_I == `OP_SLTI || opcode_I == `OP_SLTIU ||
                                 opcode_I == `OP_ANDI || opcode_I == `OP_ORI || opcode_I == `OP_XORI || opcode_I == `OP_LUI)) ||
                               ((opcode_I == `OP_BEQ || opcode_I == `OP_BNE)) ||
                               (opcode_I == `OP_LW) ||
                               (opcode_I == `OP_SW);

    assign use_rt = ((opcode_I == `OP_RTYPE) && (funct_I == `FUNCT_ADDU || funct_I == `FUNCT_SUBU ||
                                                            funct_I == `FUNCT_AND || funct_I == `FUNCT_OR ||
                                                            funct_I == `FUNCT_XOR || funct_I == `FUNCT_NOR ||
                                                            funct_I == `FUNCT_SLT || funct_I == `FUNCT_SLTU ||
                                                            funct_I == `FUNCT_SLL || funct_I == `FUNCT_SRL ||
                                                            funct_I == `FUNCT_SRA)) ||
                               ((opcode_I == `OP_BEQ || opcode_I == `OP_BNE)) ||
                               (opcode_I == `OP_SW);
    always @(*) begin
        if (inst != 0) begin
            // $display("Detecting HAZARD for inst 0x%08h", inst);
            // ID/EX stage
            if (EX_MemRead) begin
                if(((use_rs && (ex_dst == rs_I)) || (use_rt && (ex_dst == rt_I)))) begin
                    stall = 1'b1;
                end else begin
                    stall = 1'b0;
                end
            end
            else begin
                stall = 1'b0;
            end
        end 
        else begin
            stall = 1'b0;
        end
    end

endmodule
