`timescale 1ns/10ps
module  CONV(clk,reset,cdata_rd,ready,idata,iaddr,cwr,caddr_wr,cdata_wr,crd,caddr_rd,busy,csel);

input clk;
input reset;
input [19:0] cdata_rd;
input ready;	
input signed [19:0] idata;	

output reg [11:0] iaddr;	
output reg cwr;
output reg [11:0] caddr_wr;
output reg [19:0] cdata_wr;
output reg crd;
output reg [11:0] caddr_rd;
output reg busy;
output reg [2:0] csel;

reg [2:0] state_cs, state_ns;
reg signed [19:0] data [0:8];
reg [12:0] count_addr; //4096
reg [3:0] count_data; 
reg signed [39:0] layer0;
reg [19:0] maxpool [0:3];
reg [2:0] count1;

wire signed [19:0] kernel0 = 20'h0A89E;
wire signed [19:0] kernel1 = 20'h092D5;
wire signed [19:0] kernel2 = 20'h06D43;
wire signed [19:0] kernel3 = 20'h01004;
wire signed [19:0] kernel4 = 20'hF8F71;
wire signed [19:0] kernel5 = 20'hF6E54;
wire signed [19:0] kernel6 = 20'hFA6D7;
wire signed [19:0] kernel7 = 20'hFC834;
wire signed [19:0] kernel8 = 20'hFAC19;

wire signed [39:0] bias = 40'h0013100000;

parameter ST_IDLE = 3'd0;
parameter ST_INPUT = 3'd1;
parameter ST_CONV = 3'd2;
parameter ST_MAXPOOL = 3'd3;
parameter ST_DONE = 3'd4;

always @(posedge clk or posedge reset) begin
	if(reset)
		state_cs <= ST_IDLE;
	else
		state_cs <= state_ns;
end

always @(*) begin //state machine
	case (state_cs)
		ST_IDLE:
			if(busy)
				state_ns = ST_INPUT;
			else
				state_ns = ST_IDLE;
		ST_INPUT:
			if(count_data == 9)
				state_ns = ST_CONV;
			else
				state_ns = ST_INPUT;
		ST_CONV:
			if(count_addr == 4096 && cwr)
				state_ns = ST_MAXPOOL;
			else if(count_addr < 4096 && cwr)
				state_ns = ST_INPUT;
			else
				state_ns = ST_CONV;
		ST_MAXPOOL:
			if(caddr_wr == 2048)
				state_ns = ST_DONE;
			else
				state_ns = ST_MAXPOOL;
		ST_DONE:
			state_ns = ST_DONE;
		default:
			state_ns = ST_IDLE;
	endcase
end

always @(posedge clk or posedge reset) begin //count_data
    if(reset)
        count_data <= 4'd0;
	else if(state_ns == ST_INPUT)
		count_data <= count_data + 1'b1;
	else if(count_data == 9)
		count_data <= 0;
	else
		count_data <= count_data;
end

always @(posedge clk or posedge reset) begin //count_addr
	if(reset)
		count_addr <= 13'd0;
	else if(count_data == 9)
		count_addr <= count_addr + 1'b1;
	else
		count_addr <= count_addr;
end

always @(posedge clk) begin //data
	if(state_cs == ST_INPUT)
		case (count_data)
			4'd1:
				if(count_addr <= 63 || count_addr[5:0] == 6'd0) 
					data[0] <= 20'd0;
				else
					data[0] <= idata;
			4'd2:
				if(count_addr <= 63)
					data[1] <= 20'd0;
				else
					data[1] <= idata;
			4'd3:
				if(count_addr <= 63 || count_addr[5:0] == 6'd63)
					data[2] <= 20'd0;
				else
					data[2] <= idata;
			4'd4:
				if(count_addr[5:0] == 6'd0) 
					data[3] <= 20'd0;
				else
					data[3] <= idata;
			4'd5:
				data[4] <= idata;
			4'd6:
				if(count_addr[5:0] == 6'd63)
					data[5] <= 20'd0;
				else
					data[5] <= idata;
			4'd7:
				if(count_addr >= 4032 || count_addr[5:0] == 6'd0) 
					data[6] <= 20'd0;
				else
					data[6] <= idata;
			4'd8:
				if(count_addr >= 4032)
					data[7] <= 20'd0;
				else
					data[7] <= idata;
			4'd9:
				if(count_addr >= 4032 || count_addr[5:0] == 6'd63)
					data[8] <= 20'd0;
				else
					data[8] <= idata;
			default: 
				data[count_data] <= data[count_data];
		endcase
	else
		data[count_data] <= data[count_data];
end

always @(posedge clk or posedge reset) begin //iaddr
	if(reset)
		iaddr <= 12'd0;
	else if(state_ns == ST_INPUT)
		case (count_data)
			4'd0:
				if(count_addr <= 63 || count_addr[5:0] == 6'd0) 
					iaddr <= 12'd0;
				else
					iaddr <= count_addr - 65;
			4'd1:
				if(count_addr <= 63)
					iaddr <= 12'd0;
				else
					iaddr <= count_addr - 64;
			4'd2:
				if(count_addr <= 63 || count_addr[5:0] == 6'd63)
					iaddr <= 12'd0;
				else
					iaddr <= count_addr - 63;
			4'd3:
				if(count_addr[5:0] == 6'd0) 
					iaddr <= 12'd0;
				else
					iaddr <= count_addr - 1;
			4'd4:
				iaddr <= count_addr;
			4'd5:
				if(count_addr[5:0] == 6'd63)
					iaddr <= 12'd0;
				else
					iaddr <= count_addr + 1;
			4'd6:
				if(count_addr >= 4032 || count_addr[5:0] == 6'd0) 
					iaddr <= 12'd0;
				else
					iaddr <= count_addr + 63;
			4'd7:
				if(count_addr >= 4032)
					iaddr <= 12'd0;
				else
					iaddr <= count_addr + 64;
			4'd8:
				if(count_addr >= 4032 || count_addr[5:0] == 6'd63)
					iaddr <= 12'd0;
				else
					iaddr <= count_addr + 65;
			default:
				iaddr <= iaddr;
		endcase
	else
		iaddr <= iaddr;
end

always @(posedge clk or posedge reset) begin //busy
	if(reset)
		busy <= 0;
	else if(state_ns == ST_IDLE)
		busy <= 1;
	else if(state_ns == ST_DONE)
		busy <= 0;
    else
        busy <= busy;
end

always @(*) begin //layer0
	if(state_cs == ST_CONV)begin
		layer0 = ( data[0]*kernel0 +
					data[1]*kernel1 +
					data[2]*kernel2 +
					data[3]*kernel3 +
					data[4]*kernel4 +
					data[5]*kernel5 +
					data[6]*kernel6 +
					data[7]*kernel7 +
					data[8]*kernel8) + bias;
	end
	else
		layer0 = 40'd0;
end

always @(posedge clk) begin //cdata_wr
	if(state_cs == ST_CONV)begin
		if(layer0 > 0 && layer0[15]==1) 
			cdata_wr <= layer0[35:16]+ 1;
		else if(layer0 > 0 && layer0[15]==0) 
			cdata_wr <= layer0[35:16];
		else 
			cdata_wr <= 0;
	end
	else if(state_ns == ST_MAXPOOL && count1 == 4)
		cdata_wr <= max(maxpool[0],maxpool[1],maxpool[2],maxpool[3]);
end

always @(posedge clk or posedge reset) begin //caddr_wr
	if(reset)
		caddr_wr <= 12'd0;
	else if(state_cs == ST_CONV)
		caddr_wr <= count_addr - 1;
	else if(state_ns == ST_MAXPOOL && count1 == 6)
		caddr_wr <= caddr_wr + 1'b1;
	else if(caddr_wr == 4222)
		caddr_wr <= 12'd0;
end

always @(posedge clk) begin //cwr
	if(state_cs == ST_CONV)
		if(cwr)
			cwr <= 0;
		else
			cwr <= 1;
	else if(state_ns == ST_MAXPOOL && count1 == 4)
		cwr <= 1;
	else 
		cwr <= 0;
end

always @(posedge clk or posedge reset) begin //count1
	if(reset)
		count1 <= 0;
	else if(count1 == 6)
		count1 <= 0;
	else if(state_ns == ST_MAXPOOL)
		count1 <= count1 + 1'b1;
	else
		count1 <= 0;
end

always @(posedge clk or posedge reset) begin //caddr_rd
	if(reset)
		caddr_rd <= 12'd0;
	else if(state_ns == ST_MAXPOOL)
		case (count1)
			3'b000:
				caddr_rd <= caddr_rd + 1'b1;
			3'b001:
				caddr_rd <= caddr_rd + 63;
			3'b010:
				caddr_rd <= caddr_rd + 1;
			3'b101:
				if(caddr_rd % 64 == 63)
					caddr_rd <= caddr_rd + 1;
				else if(caddr_wr == 4095)	
					caddr_rd <= caddr_rd - 65;
				else
					caddr_rd <= caddr_rd - 63;
			default: 
				caddr_rd <= caddr_rd;
		endcase
end

always @(posedge clk or posedge reset) begin //crd
	if(reset)	
		crd <= 0;
	else if(state_ns == ST_MAXPOOL)
		if(count1 == 3)
			crd <= 0;
		else if (count1 == 6 || crd)
			crd <= 1;
	else
		crd <= 0;
end

always @(posedge clk) begin //maxpool
	if(state_ns == ST_MAXPOOL && count1 <= 3)
		maxpool[count1] <= cdata_rd;
end

always @(posedge clk or posedge reset) begin //csel
	if(reset)
		csel <= 3'd0;
	else if(state_ns == ST_CONV)
		csel <= 3'b001;
	else if(state_ns == ST_MAXPOOL)
		if(count1 == 4)
			csel <= 3'b011;
		else 
			csel <= 3'b001;
	else
		csel <= 3'd0;
end

function [19:0] max;
	input [19:0] data1, data2, data3, data4;
	integer i;
	reg [19:0] data_in [0:2];
	
	begin
		max = data1;
		data_in[0] = data2;
		data_in[1] = data3;
		data_in[2] = data4;
		for(i=0;i<3;i=i+1)
			if(max > data_in[i])
				max = max;
			else 
				max = data_in[i];
	end
	
endfunction

endmodule