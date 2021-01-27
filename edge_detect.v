module edge_detect (
   clk,
   data_in,
	pos_edge,
   neg_edge
   );
input      clk;
input      data_in;
output	  pos_edge;
output     neg_edge;

reg        data_in_d1;
reg        data_in_d2; 

assign pos_edge =  data_in_d1 & ~data_in_d2;
assign neg_edge =  ~data_in_d1 & data_in_d2;

always@(posedge clk) 
begin 
  data_in_d1 <= data_in;
  data_in_d2 <= data_in_d1;   
end

endmodule 