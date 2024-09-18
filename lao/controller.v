`default_nettype none
module controller (
	clk,
	reset,
	consumer_read_valid,
	consumer_read_address,
	consumer_read_ready,
	consumer_read_data,
	consumer_write_valid,
	consumer_write_address,
	consumer_write_data,
	consumer_write_ready,
	mem_read_valid,
	mem_read_address,
	mem_read_ready,
	mem_read_data,
	mem_write_valid,
	mem_write_address,
	mem_write_data,
	mem_write_ready
);
	parameter ADDR_BITS = 8;
	parameter DATA_BITS = 16;
	parameter NUM_CONSUMERS = 4;
	parameter NUM_CHANNELS = 1;
	parameter WRITE_ENABLE = 1;
	input wire clk;
	input wire reset;
	input wire [NUM_CONSUMERS - 1:0] consumer_read_valid;
	input wire [(NUM_CONSUMERS * ADDR_BITS) - 1:0] consumer_read_address;
	output reg [NUM_CONSUMERS - 1:0] consumer_read_ready;
	output reg [(NUM_CONSUMERS * DATA_BITS) - 1:0] consumer_read_data;
	input wire [NUM_CONSUMERS - 1:0] consumer_write_valid;
	input wire [(NUM_CONSUMERS * ADDR_BITS) - 1:0] consumer_write_address;
	input wire [(NUM_CONSUMERS * DATA_BITS) - 1:0] consumer_write_data;
	output reg [NUM_CONSUMERS - 1:0] consumer_write_ready;
	output reg [NUM_CHANNELS - 1:0] mem_read_valid;
	output reg [(NUM_CHANNELS * ADDR_BITS) - 1:0] mem_read_address;
	input wire [NUM_CHANNELS - 1:0] mem_read_ready;
	input wire [(NUM_CHANNELS * DATA_BITS) - 1:0] mem_read_data;
	output reg [NUM_CHANNELS - 1:0] mem_write_valid;
	output reg [(NUM_CHANNELS * ADDR_BITS) - 1:0] mem_write_address;
	output reg [(NUM_CHANNELS * DATA_BITS) - 1:0] mem_write_data;
	input wire [NUM_CHANNELS - 1:0] mem_write_ready;
	localparam IDLE = 3'b000;
	localparam READ_WAITING = 3'b010;
	localparam WRITE_WAITING = 3'b011;
	localparam READ_RELAYING = 3'b100;
	localparam WRITE_RELAYING = 3'b101;
	reg [(NUM_CHANNELS * 3) - 1:0] controller_state;
	reg [(NUM_CHANNELS * $clog2(NUM_CONSUMERS)) - 1:0] current_consumer;
	reg [NUM_CONSUMERS - 1:0] channel_serving_consumer;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg [0:1] _sv2v_jump;
		_sv2v_jump = 2'b00;
		if (reset) begin
			mem_read_valid <= 0;
			mem_read_address <= 0;
			mem_write_valid <= 0;
			mem_write_address <= 0;
			mem_write_data <= 0;
			consumer_read_ready <= 0;
			consumer_read_data <= 0;
			consumer_write_ready <= 0;
			current_consumer <= 0;
			controller_state <= 0;
			channel_serving_consumer = 0;
		end
		else begin : sv2v_autoblock_2
			reg signed [31:0] i;
			begin : sv2v_autoblock_3
				reg signed [31:0] _sv2v_value_on_break;
				for (i = 0; i < NUM_CHANNELS; i = i + 1)
					if (_sv2v_jump < 2'b10) begin
						_sv2v_jump = 2'b00;
						case (controller_state[i * 3+:3])
							IDLE: begin : sv2v_autoblock_4
								reg signed [31:0] j;
								begin : sv2v_autoblock_5
									reg signed [31:0] _sv2v_value_on_break;
									reg [0:1] _sv2v_jump_1;
									_sv2v_jump_1 = _sv2v_jump;
									for (j = 0; j < NUM_CONSUMERS; j = j + 1)
										if (_sv2v_jump < 2'b10) begin
											_sv2v_jump = 2'b00;
											if (consumer_read_valid[j] && !channel_serving_consumer[j]) begin
												channel_serving_consumer[j] = 1;
												current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)] <= j;
												mem_read_valid[i] <= 1;
												mem_read_address[i * ADDR_BITS+:ADDR_BITS] <= consumer_read_address[j * ADDR_BITS+:ADDR_BITS];
												controller_state[i * 3+:3] <= READ_WAITING;
												_sv2v_jump = 2'b10;
											end
											else if (consumer_write_valid[j] && !channel_serving_consumer[j]) begin
												channel_serving_consumer[j] = 1;
												current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)] <= j;
												mem_write_valid[i] <= 1;
												mem_write_address[i * ADDR_BITS+:ADDR_BITS] <= consumer_write_address[j * ADDR_BITS+:ADDR_BITS];
												mem_write_data[i * DATA_BITS+:DATA_BITS] <= consumer_write_data[j * DATA_BITS+:DATA_BITS];
												controller_state[i * 3+:3] <= WRITE_WAITING;
												_sv2v_jump = 2'b10;
											end
											_sv2v_value_on_break = j;
										end
									if (!(_sv2v_jump < 2'b10))
										j = _sv2v_value_on_break;
									if (_sv2v_jump != 2'b11)
										_sv2v_jump = _sv2v_jump_1;
								end
							end
							READ_WAITING:
								if (mem_read_ready[i]) begin
									mem_read_valid[i] <= 0;
									consumer_read_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 1;
									consumer_read_data[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)] * DATA_BITS+:DATA_BITS] <= mem_read_data[i * DATA_BITS+:DATA_BITS];
									controller_state[i * 3+:3] <= READ_RELAYING;
								end
							WRITE_WAITING:
								if (mem_write_ready[i]) begin
									mem_write_valid[i] <= 0;
									consumer_write_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 1;
									controller_state[i * 3+:3] <= WRITE_RELAYING;
								end
							READ_RELAYING:
								if (!consumer_read_valid[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]]) begin
									channel_serving_consumer[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] = 0;
									consumer_read_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 0;
									controller_state[i * 3+:3] <= IDLE;
								end
							WRITE_RELAYING:
								if (!consumer_write_valid[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]]) begin
									channel_serving_consumer[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] = 0;
									consumer_write_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 0;
									controller_state[i * 3+:3] <= IDLE;
								end
						endcase
						_sv2v_value_on_break = i;
					end
				if (!(_sv2v_jump < 2'b10))
					i = _sv2v_value_on_break;
				if (_sv2v_jump != 2'b11)
					_sv2v_jump = 2'b00;
			end
		end
	end
endmodule