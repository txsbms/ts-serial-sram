module _23A640(csb, so, holdb, sck, si);
  input csb;
  output so;
  input holdb;
  input sck;
  input si;
  
  SPI u0(si, sck, ~csb, so);
endmodule
