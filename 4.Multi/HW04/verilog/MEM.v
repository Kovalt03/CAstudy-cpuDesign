`timescale 1ns / 1ps

module MEM(
	input				clk,
	input				rst,

	input [31:0]		mem_addr,
	input				MemWrite,
	input [31:0]		mem_write_data,
	output reg [31:0]	mem_read_data
    );

	reg [31:0] memory [0:8191];

	initial begin
		// $write("reset mem\n");
		$readmemh("../cpp/initial_mem.mem", memory);
	end

	always @(*) begin
		mem_read_data = memory[(mem_addr >> 2)];
		// $write("read mem %x %x\n", mem_addr, mem_read_data);
	end
	
	always @(posedge clk) begin
		if (!rst)
			if (MemWrite) begin
				memory[(mem_addr >> 2)] <= mem_write_data;
				// $write("write %x : %x\n", mem_addr, mem_write_data);
			end
	end

endmodule
