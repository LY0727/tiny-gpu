`default_nettype none
module core (
	clk,
	reset,
	start,
	done,
	block_id,
	thread_count,
	program_mem_read_valid,
	program_mem_read_address,
	program_mem_read_ready,
	program_mem_read_data,
	data_mem_read_valid,
	data_mem_read_address,
	data_mem_read_ready,
	data_mem_read_data,
	data_mem_write_valid,
	data_mem_write_address,
	data_mem_write_data,
	data_mem_write_ready
);
	parameter DATA_MEM_ADDR_BITS = 8;
	parameter DATA_MEM_DATA_BITS = 8;
	parameter PROGRAM_MEM_ADDR_BITS = 8;
	parameter PROGRAM_MEM_DATA_BITS = 16;
	parameter THREADS_PER_BLOCK = 4;
	input wire clk;
	input wire reset;
	input wire start;
	output wire done;
	input wire [7:0] block_id;
	input wire [$clog2(THREADS_PER_BLOCK):0] thread_count;
	output reg program_mem_read_valid;
	output reg [PROGRAM_MEM_ADDR_BITS - 1:0] program_mem_read_address;
	input wire program_mem_read_ready;
	input wire [PROGRAM_MEM_DATA_BITS - 1:0] program_mem_read_data;
	output reg [THREADS_PER_BLOCK - 1:0] data_mem_read_valid;
	output reg [(THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS) - 1:0] data_mem_read_address;
	input wire [THREADS_PER_BLOCK - 1:0] data_mem_read_ready;
	input wire [(THREADS_PER_BLOCK * DATA_MEM_DATA_BITS) - 1:0] data_mem_read_data;
	output reg [THREADS_PER_BLOCK - 1:0] data_mem_write_valid;
	output reg [(THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS) - 1:0] data_mem_write_address;
	output reg [(THREADS_PER_BLOCK * DATA_MEM_DATA_BITS) - 1:0] data_mem_write_data;
	input wire [THREADS_PER_BLOCK - 1:0] data_mem_write_ready;
	reg [2:0] core_state;
	reg [2:0] fetcher_state;
	reg [15:0] instruction;
	reg [7:0] current_pc;
	wire [(THREADS_PER_BLOCK * 8) - 1:0] next_pc;
	reg [7:0] rs [THREADS_PER_BLOCK - 1:0];
	reg [7:0] rt [THREADS_PER_BLOCK - 1:0];
	reg [(THREADS_PER_BLOCK * 2) - 1:0] lsu_state;
	reg [7:0] lsu_out [THREADS_PER_BLOCK - 1:0];
	wire [7:0] alu_out [THREADS_PER_BLOCK - 1:0];
	reg [3:0] decoded_rd_address;
	reg [3:0] decoded_rs_address;
	reg [3:0] decoded_rt_address;
	reg [2:0] decoded_nzp;
	reg [7:0] decoded_immediate;
	reg decoded_reg_write_enable;
	reg decoded_mem_read_enable;
	reg decoded_mem_write_enable;
	reg decoded_nzp_write_enable;
	reg [1:0] decoded_reg_input_mux;
	reg [1:0] decoded_alu_arithmetic_mux;
	reg decoded_alu_output_mux;
	reg decoded_pc_mux;
	reg decoded_ret;
	fetcher #(
		.PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
		.PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS)
	) fetcher_instance(
		.clk(clk),
		.reset(reset),
		.core_state(core_state),
		.current_pc(current_pc),
		.mem_read_valid(program_mem_read_valid),
		.mem_read_address(program_mem_read_address),
		.mem_read_ready(program_mem_read_ready),
		.mem_read_data(program_mem_read_data),
		.fetcher_state(fetcher_state),
		.instruction(instruction)
	);
	decoder decoder_instance(
		.clk(clk),
		.reset(reset),
		.core_state(core_state),
		.instruction(instruction),
		.decoded_rd_address(decoded_rd_address),
		.decoded_rs_address(decoded_rs_address),
		.decoded_rt_address(decoded_rt_address),
		.decoded_nzp(decoded_nzp),
		.decoded_immediate(decoded_immediate),
		.decoded_reg_write_enable(decoded_reg_write_enable),
		.decoded_mem_read_enable(decoded_mem_read_enable),
		.decoded_mem_write_enable(decoded_mem_write_enable),
		.decoded_nzp_write_enable(decoded_nzp_write_enable),
		.decoded_reg_input_mux(decoded_reg_input_mux),
		.decoded_alu_arithmetic_mux(decoded_alu_arithmetic_mux),
		.decoded_alu_output_mux(decoded_alu_output_mux),
		.decoded_pc_mux(decoded_pc_mux),
		.decoded_ret(decoded_ret)
	);
	scheduler #(.THREADS_PER_BLOCK(THREADS_PER_BLOCK)) scheduler_instance(
		.clk(clk),
		.reset(reset),
		.start(start),
		.fetcher_state(fetcher_state),
		.core_state(core_state),
		.decoded_mem_read_enable(decoded_mem_read_enable),
		.decoded_mem_write_enable(decoded_mem_write_enable),
		.decoded_ret(decoded_ret),
		.lsu_state(lsu_state),
		.current_pc(current_pc),
		.next_pc(next_pc),
		.done(done)
	);
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < THREADS_PER_BLOCK; _gv_i_1 = _gv_i_1 + 1) begin : threads
			localparam i = _gv_i_1;
			alu alu_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.core_state(core_state),
				.decoded_alu_arithmetic_mux(decoded_alu_arithmetic_mux),
				.decoded_alu_output_mux(decoded_alu_output_mux),
				.rs(rs[i]),
				.rt(rt[i]),
				.alu_out(alu_out[i])
			);
			lsu lsu_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.core_state(core_state),
				.decoded_mem_read_enable(decoded_mem_read_enable),
				.decoded_mem_write_enable(decoded_mem_write_enable),
				.mem_read_valid(data_mem_read_valid[i]),
				.mem_read_address(data_mem_read_address[i * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS]),
				.mem_read_ready(data_mem_read_ready[i]),
				.mem_read_data(data_mem_read_data[i * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS]),
				.mem_write_valid(data_mem_write_valid[i]),
				.mem_write_address(data_mem_write_address[i * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS]),
				.mem_write_data(data_mem_write_data[i * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS]),
				.mem_write_ready(data_mem_write_ready[i]),
				.rs(rs[i]),
				.rt(rt[i]),
				.lsu_state(lsu_state[i * 2+:2]),
				.lsu_out(lsu_out[i])
			);
			registers #(
				.THREADS_PER_BLOCK(THREADS_PER_BLOCK),
				.THREAD_ID(i),
				.DATA_BITS(DATA_MEM_DATA_BITS)
			) register_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.block_id(block_id),
				.core_state(core_state),
				.decoded_reg_write_enable(decoded_reg_write_enable),
				.decoded_reg_input_mux(decoded_reg_input_mux),
				.decoded_rd_address(decoded_rd_address),
				.decoded_rs_address(decoded_rs_address),
				.decoded_rt_address(decoded_rt_address),
				.decoded_immediate(decoded_immediate),
				.alu_out(alu_out[i]),
				.lsu_out(lsu_out[i]),
				.rs(rs[i]),
				.rt(rt[i])
			);
			pc #(
				.DATA_MEM_DATA_BITS(DATA_MEM_DATA_BITS),
				.PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS)
			) pc_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.core_state(core_state),
				.decoded_nzp(decoded_nzp),
				.decoded_immediate(decoded_immediate),
				.decoded_nzp_write_enable(decoded_nzp_write_enable),
				.decoded_pc_mux(decoded_pc_mux),
				.alu_out(alu_out[i]),
				.current_pc(current_pc),
				.next_pc(next_pc[i * 8+:8])
			);
		end
	endgenerate
endmodule