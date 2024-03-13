module axi_stream_insert_header#(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
    )(
    input 						clk,
    input 						rst_n,
    // AXI Stream input original data
    input 						valid_in,
    input [DATA_WD-1 : 0]		data_in,
    input [DATA_BYTE_WD-1 : 0]	keep_in,
    input 						last_in,
    output 						ready_in,
    // AXI Stream output with header inserted
    output 						valid_out,
    output [DATA_WD-1 : 0] 		data_out,
    output [DATA_BYTE_WD-1 : 0] keep_out,
    output 						last_out,
    input 						ready_out,
    // The header to be inserted to AXI Stream input
    input 						valid_insert,
    input [DATA_WD-1 : 0] 		header_insert,
    input [DATA_BYTE_WD-1 : 0] 	keep_insert,
    input [BYTE_CNT_WD : 0] 	byte_insert_cnt,
    output 						ready_insert
);
// Your code here

/********************寄存器*************************/
reg 						last_in_reg_1		= 'd0	;
reg 						last_in_reg_2		= 'd0	;
reg [DATA_WD-1 : 0] 		data_out_reg_1		= 'd0	;
reg [DATA_WD-1 : 0] 		data_out_reg_2		= 'd0	;
reg [DATA_BYTE_WD-1 : 0] 	keep_in_reg		    = 'd0   ;
reg [DATA_WD-1 : 0]		    header_out_reg		= 'd0   ;
reg 					    insert_flag			= 'd0   ;
reg [DATA_BYTE_WD-1 : 0]    keep_insert_out_reg	= 'd0   ;
reg [DATA_WD-1 : 0]	        header_data_out_reg	= 'd0   ;
reg                         ready_insert_flag	= 'd0   ;
reg [DATA_BYTE_WD-1 : 0]    keep_out_reg	    = 'd0   ;      
reg [1:0]                   insert_flag_reg             ;
reg [1:0]                   last_out_reg                ;

/********************网表型*****************************/
wire 						last_in_pulse		 	    ;
wire 						axi_ready_in			    ;
wire                        last_out_pulse              ;

/*******************组合逻辑****************************/
assign last_in_pulse  = ~last_in_reg_1 & last_in_reg_2                  ;
assign axi_ready_in   = last_in_pulse ? 1'b0 : 1'b1                     ;
assign ready_in       = axi_ready_in                                    ;
assign data_out       = ready_out ? header_data_out_reg : data_out_reg_2;
assign negedge_flag   = ~insert_flag_reg[1] & insert_flag_reg[0]        ;
assign valid_out      = negedge_flag ? 'd0 : 'd1                        ;
assign ready_insert	  =	ready_insert_flag                               ;
assign keep_out       = keep_out_reg                                    ;
assign last_out_pulse = ~last_out_reg[0]&last_out_reg[1]                ;
assign last_out       = last_out_pulse                                  ;



/*********************时序逻辑***************************/
always@(posedge clk or negedge rst_n)begin
	  if(!rst_n)begin
	  	last_in_reg_1 <= 'd0;
	  	last_in_reg_2 <= 'd0;
	  end
	  else begin
	  	last_in_reg_1 <= last_in;
	  	last_in_reg_2 <= last_in_reg_1;
	  end
end

always@(posedge clk or negedge rst_n)begin
	  if(!rst_n)begin
	  	keep_in_reg	<= 'd0;
	  	data_out_reg_1 <= 'd0;
	  	data_out_reg_2 <= 'd0;
	  end
	  else if(valid_in && axi_ready_in)begin
	  	keep_in_reg 	<= keep_in;
	  	data_out_reg_1 <= data_in;
	  	data_out_reg_2 <= data_out_reg_1;
	  end
	  else begin
	  	keep_in_reg	<= keep_in_reg;
	  	data_out_reg_1 <= data_out_reg_1;
	  	data_out_reg_2 <= data_out_reg_2;
	  end
end

always@(posedge clk or negedge rst_n)begin
	  if(!rst_n)begin
	  	header_out_reg 		<= 'd0;
	  	insert_flag 		<= 'd0;
	  	keep_insert_out_reg	<= 'd0;
	  end
	  else if(valid_insert && ready_insert)begin
	  	case(keep_insert)
	  	4'b1111:begin 
	  		header_out_reg <= header_insert;
	  		insert_flag <= 'd1;end
	  	4'b0111:begin 
	  		header_out_reg <= {8'b0,header_insert[23:0]};
	  		insert_flag <= 'd1;end
	  	4'b0011:begin 
	  		header_out_reg <= {16'b0,header_insert[15:0]};
	  		insert_flag <= 'd1;end
	  	4'b0001:begin 
	  		header_out_reg <= {24'b0,header_insert[7:0]};
	  		insert_flag <= 'd1;end
	  	default:begin 
	  		header_out_reg <= header_out_reg;
	  		insert_flag <= 'd1;end
	  	endcase
	  	keep_insert_out_reg <= keep_insert;
	  end
	  else if(insert_flag)
	  	insert_flag <= 'd0;
end

always@(posedge clk or negedge rst_n)begin
	  if(!rst_n)begin
	  	header_data_out_reg <= 'd0;
	  end
	  else if(insert_flag)begin
	  	case(keep_insert)
	  	4'b1111: header_data_out_reg <= header_out_reg;
	  	4'b0111: header_data_out_reg <= {header_insert[23:0],data_out_reg_1[31:24]};
	  	4'b0011: header_data_out_reg <= {header_insert[15:0],data_out_reg_1[31:16]};
	  	4'b0001: header_data_out_reg <= {header_insert[7:0],data_out_reg_1[31:8]};
	  	default: header_data_out_reg <= header_data_out_reg;
	  	endcase
	  end
	  else begin
        case(keep_insert_out_reg)
        4'b1111:header_data_out_reg <= data_out_reg_2; 
        4'b0111:header_data_out_reg <= {data_out_reg_2[23:0],data_out_reg_1[31:24]};
        4'b0011:header_data_out_reg <= {data_out_reg_2[15:0],data_out_reg_1[31:16]};
        4'b0001:header_data_out_reg <= {data_out_reg_2[7:0],data_out_reg_1[31:8]};
        default:header_data_out_reg <= header_data_out_reg;
	  	endcase
      end
end

always@(posedge clk or negedge rst_n)begin
      if(!rst_n)
          ready_insert_flag <= 'd0;
      else
          ready_insert_flag <= insert_flag=='d1 ? 'd0 : 'd1;
end  

always@(posedge clk or negedge rst_n)begin
      if(!rst_n)
          insert_flag_reg <= 'd0;
      else
          insert_flag_reg <= {insert_flag_reg[0], insert_flag};
end

always@(posedge clk or negedge rst_n)begin
      if(!rst_n)
          keep_out_reg	<= 'd0;
      else if(valid_out)
          keep_out_reg 	<= 4'b1111;
      else if(last_out_pulse)begin
          case(keep_insert)
              4'b1111: keep_out_reg <= keep_in_reg;
              4'b0111: keep_out_reg <= keep_in_reg << 1;
              4'b0011: keep_out_reg <= keep_in_reg << 2;
              4'b0001: keep_out_reg <= keep_in_reg << 3;
          endcase
      end
      else
          keep_out_reg	<= 'd0;
end

always@(posedge clk or negedge rst_n)begin
      if(!rst_n)
          last_out_reg <= 'd0;
      else 
      begin
          last_out_reg <= {last_out_reg[0],last_in_pulse};
      end     
end

endmodule