module i2c_slave_controller(
	inout sda,
	input scl,
	output reg[7:0] data,
	output reg[7:0] addr
	//input RST
	);
	
	localparam ADDRESS = 7'b0101010;
	
	localparam READ_ADDR = 4'd0;
	localparam ADDR_READ1=4'd1;
	localparam SEND_ACK = 4'd2;
	localparam READ_DATA =4'd3;
	localparam WRITE_DATA =4'd4;
	localparam SEND_ACK2 = 4'd5;
	
	//reg [7:0] addr;
	reg [7:0] counter=7;
   reg [3:0] state=READ_ADDR ;
	reg [7:0] data_out = 8'b01101011;
	reg sda_out = 0;
	//reg sda_in = 0;
	reg start = 0;
	reg stop=0;
	reg write_enable = 0;
	assign sda = (write_enable == 1) ? sda_out :1'bz;
	//assign sda1=sda;
	
	always @(negedge sda) begin
		if ((start==0) &&(scl == 1))
			start <= 1;	
		else
		   start<=0;
	end
	
	
	always @(posedge sda) begin
		if ((stop==0) && (scl == 1))
			stop<=1;
		else  
		   stop<=0;
	end
	
	
	
	always @(posedge scl) begin
			case(state)
				READ_ADDR:begin 
				//if(RST)
				if(start)
				   state<=ADDR_READ1;
				else
			      state<=READ_ADDR;	
				end
				
				ADDR_READ1:
				begin
				addr[counter] <= sda;
			   if(counter == 0) state <= SEND_ACK;
				else counter <= counter - 1;	
				end
				
				
				
				SEND_ACK: begin
				if(addr[7:1] == ADDRESS)begin
					counter <= 7;
					if(addr[0] == 0) begin 
							state <= READ_DATA;
						end
						else state <= WRITE_DATA;
				end
				end
				
				
				READ_DATA: begin
					data[counter] <= sda;
					if(counter == 0) begin
						state <= SEND_ACK2;
					end else counter <= counter - 1;
				end
				
				SEND_ACK2: begin
					state <= READ_ADDR;					
				end
				
				WRITE_DATA: begin
					if(counter == 0) state <= READ_ADDR;
					else counter <= counter - 1;		
				end
				
			endcase
		end
	
	always @(negedge scl) begin
		case(state)
			
			READ_ADDR: begin
				write_enable <= 0;			
			end
			
			ADDR_READ1:begin
			write_enable<=0;
			end
			
			SEND_ACK: begin
				sda_out <= 0;
				write_enable <= 1;	
			end
			
			
			READ_DATA: begin
				write_enable <= 0;
			end
			
			WRITE_DATA: begin
				sda_out <= data_out[counter];
				write_enable <= 1;
			end
			
			SEND_ACK2: begin
				sda_out <= 0;
				write_enable <= 1;
			end
		endcase
	end
endmodule

 