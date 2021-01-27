module AM2302_master(
	input clk,	//27.08ns
   input rst_n,
   input sfr_rd,
   input sfr_wr,
   input [7:0]sfr_data_out,
   input [7:0]sfr_addr,
	inout sda,
	output reg [7:0]sfr_data_in
);

reg [15:0]sda_counter = 16'd0;
reg [3:0]state = 4'd0;
reg [5:0]bit_num = 6'd0;
reg [39:0]data = 40'h0;
reg sda_reg;
wire sda_neg_edge;
wire sda_pos_edge;

assign sda = (state == 4'd2 || state == 4'd3) ? 1'bz : sda_reg;

edge_detect d0(.clk(clk), .data_in(sda), .pos_edge(sda_pos_edge), .neg_edge(sda_neg_edge));

always @(negedge clk or negedge rst_n)			//sda_counter
begin
	if(!rst_n)
		sda_counter <= 16'd0;
	else if(sda_neg_edge)
		sda_counter <= 16'd0;
	else
		sda_counter <= sda_counter + 16'd1;
end

always @(negedge clk or negedge rst_n)			//state
begin
	if(!rst_n)
		state <= 4'd0;
	else
		case(state)
		4'd0:
			if(sfr_wr && sfr_addr == 8'he1 && sfr_data_out[0] == 1'b1)
				state <= 4'd1;
		4'd1:
			if(sda_counter == 16'd36927)
				state <= 4'd2;
		4'd2:
			if(sda_neg_edge && sda_counter > 16'd5500 && sda_counter < 16'd6400)
				state <= 4'd3;
		4'd3:
			if(bit_num == 6'd40 && sda_counter >= 16'd1660)
				state <= 4'd4;
		endcase
end

always @(negedge clk or negedge rst_n)			//bit_num
begin
	if(!rst_n)
		bit_num <= 6'd0;
	else if(bit_num == 6'd40 && sda_counter >= 16'd1660)
		bit_num <= 6'd0;
	else if(state == 4'd3 && sda_neg_edge && ((sda_counter > 16'd2500 && sda_counter < 16'd3100) || (sda_counter > 16'd4000 && sda_counter < 16'd4900)))
		bit_num <= bit_num + 6'd1;
end

always @(negedge clk or negedge rst_n)			//data
begin
	if(!rst_n)
		data <= 40'h0;
	else if(state == 4'd3)
		if(sda_neg_edge && sda_counter > 16'd2500 && sda_counter < 16'd3100)
			data[6'd39 - bit_num] <= 1'b0;
		else if(sda_neg_edge && sda_counter > 16'd4000 && sda_counter < 16'd4900)
			data[6'd39 - bit_num] <= 1'b1;		
end

always @(negedge clk or negedge rst_n)			//sda_reg
begin
	if(!rst_n)
		sda_reg <= 1'bz;
	else if(state == 4'd1 && sda_counter < 16'd36927)
		sda_reg <= 1'b0;
	else
		sda_reg <= 1'bz;
end

always @(negedge clk or negedge rst_n)
begin
	if(!rst_n)
		sfr_data_in <= 8'd0;
	else if(state == 4'd4 && sfr_rd)
		case(sfr_addr)
		8'he1: sfr_data_in <= 8'h11;
		8'he2: sfr_data_in <= data[39:32];
		8'he3: sfr_data_in <= data[31:24];
		8'he4: sfr_data_in <= data[23:16];
		8'he5: sfr_data_in <= data[15:8];
		8'he6: sfr_data_in <= data[7:0];
		endcase
	else
		sfr_data_in <= 8'd0;
end

endmodule		
