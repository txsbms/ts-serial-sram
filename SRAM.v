module SRAM(address,re,we,data);
  input [12:0] address;
  input re, we;
  inout [7:0] data;
  
  reg [7:0] data_out;
  reg [7:0] mem [8191:0];
  
  always @(*) begin
    if (re & !we) data_out = mem[address];
    if (we & !re) mem[address] = data;
  end
  
  assign data = (re & !we) ? data_out : 8'hz;
endmodule
