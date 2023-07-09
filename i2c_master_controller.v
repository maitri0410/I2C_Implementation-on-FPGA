module i2c_master_controller(
	input wire clk,
	input wire rst,
	input wire enable,
   output reg [7:0] data_out,
	output wire ready,
   inout i2c_sda,
   output  i2c_scl,
	//output reg i2c_clk=0,
	output sda1
	);

	localparam IDLE = 4'd0;
	localparam START = 4'd1;
	localparam START1=4'd2;
	localparam ADDRESS =4'd3;
	localparam READ_ACK =4'd4;
	localparam WRITE_DATA =4'd5;
	localparam WRITE_ACK =4'd6;
	localparam READ_DATA =4'd7;
	localparam READ_ACK2 =4'd8;
	localparam STOP =4'd9;
   
	//localparam DIVIDE_BY = 4;
   
	reg [6:0] addr= 7'b0101010;
	reg [7:0] data_in=8'b10101011;
	reg rw=0;
	//reg ack=1;
	reg [3:0] state;
	reg [7:0] saved_addr;
	reg [7:0] saved_data;
	reg [7:0] counter;
	reg [22:0] counter2 = 0;
	reg write_enable;
	reg i2c_clk=0;
	reg sda_out;
	reg i2c_scl_enable = 0;

	assign ready = ((rst == 0) && (state == IDLE)) ? 1 : 0;
	assign i2c_scl = (i2c_scl_enable == 0 ) ? 1 : i2c_clk;
	assign i2c_sda = (write_enable == 1) ? sda_out : 1'bz;
	assign sda1=i2c_sda;
	
	always @(posedge clk) begin
	   counter2=counter2+23'd1;
		if (counter2 == 23'd6000000) begin
			i2c_clk <= ~i2c_clk;
			counter2 <= 0;
		end
		
	end 
	/*always @(posedge clk) begin
		if (counter2 == (DIVIDE_BY/2) - 1) begin
			i2c_clk <= ~i2c_clk;
			counter2 <= 0;
		end
		else counter2 <= counter2 + 8'd1;
	end 
	*/
	always @(negedge i2c_clk, posedge rst) begin
		if(rst) begin
			i2c_scl_enable <= 0;
		end else begin
			if ((state == IDLE) || (state == START) || (state == STOP)) begin
				i2c_scl_enable <= 0;
			end else begin
				i2c_scl_enable <= 1;
			end
		end
	
	end


	always @(posedge i2c_clk, posedge rst) begin
		if(rst) begin
			state <= IDLE;
			data_out<=8'd0;
			saved_addr<=8'd0;
			saved_data<=8'd0;
		end		
		else begin
			case(state)
			
				IDLE: begin
					if (enable) begin
						state <= START;
						saved_addr <= {addr, rw};
						saved_data <= data_in;
					end
					else state <= IDLE;
				end

				START: begin
					counter <= 7;
					state <= START1;
				end
				
				START1:begin
				  state<=ADDRESS;
				  end

				ADDRESS: begin
					if (counter == 0) begin 
						state <= READ_ACK;
					end
					else 
					counter <= counter - 1;
				end

				READ_ACK: begin
				    if (i2c_sda == 0) begin
						counter <= 7;
						if(saved_addr[0] == 0) 
						state <= WRITE_DATA;
						else
						state <= READ_DATA;
					end
					else 
					state <= STOP;
				end

				WRITE_DATA: begin
					if(counter == 0) begin
						state <= READ_ACK2;
					end 
					else counter <= counter - 1;
				end
				
				READ_ACK2: begin
					if (i2c_sda == 0) begin
					state <= IDLE;
					end
					else state <= STOP;
				end

				READ_DATA: begin
					data_out[counter] <= i2c_sda;
					if (counter == 0) state <= WRITE_ACK;
					else counter <= counter - 1;
				end
				
				WRITE_ACK: begin
					state <= STOP;
				end

				STOP: begin
					state <= IDLE;
				end
			endcase
		end
	end
	
	always @(negedge i2c_clk, posedge rst) begin
		if(rst == 1) begin
			write_enable <= 1;
			sda_out <= 1;
		end else begin
			case(state)
				
				START: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				START1:begin
				   write_enable<=1;
					sda_out<=0;
				end
				
				ADDRESS: begin
					sda_out <= saved_addr[counter];
				end
				
				READ_ACK: begin
					write_enable <= 0;
				end
				
				WRITE_DATA: begin 
					write_enable <= 1;
					sda_out <= saved_data[counter];
				end
				
				WRITE_ACK: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				READ_DATA: begin
					write_enable <= 0;				
				end
				
				STOP: begin
					write_enable <= 1;
					sda_out <= 1;
				end
			endcase
		end
	end

endmodule
