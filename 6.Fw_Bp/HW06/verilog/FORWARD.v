module FORWARD (
    input  [4:0] rs_I,
    input  [4:0] rt_I,
    input        ex_mem_regwrite,
    input  [4:0] ex_mem_wr_addr,
    input        mem_wb_regwrite,
    input  [4:0] mem_wb_wr_addr,

    output [1:0] ForwardA,
    output [1:0] ForwardB
);

        // ForwardA logic
    assign ForwardA =
    (ex_mem_regwrite && (ex_mem_wr_addr != 0) && (ex_mem_wr_addr == rs_I)) ? 2'b10 :
    (mem_wb_regwrite && (mem_wb_wr_addr != 0) && (mem_wb_wr_addr == rs_I)) ? 2'b01 :
    2'b00;

    assign ForwardB =
        (ex_mem_regwrite && (ex_mem_wr_addr != 0) && (ex_mem_wr_addr == rt_I)) ? 2'b10 :
        (mem_wb_regwrite && (mem_wb_wr_addr != 0) && (mem_wb_wr_addr == rt_I)) ? 2'b01 :
        2'b00;

endmodule