module SPI(si, sck, cs, so);
  input si, sck, cs;
  output reg so;
  
  reg [7:0] instr;
  reg [15:0] addr;
  reg [3:0] counter = 4'h0;
  reg [2:0] state = 3'b001;
  
  wire [7:0] data;
  reg [7:0] data_in;
  reg [7:0] data_write;
  
  reg re, we;
  
  parameter GET_INSTR 	= 3'b001;
  parameter GET_ADDR	= 3'b010;
  parameter READ_DATA	= 3'b011;
  parameter WRITE_DATA  = 3'b100;
  parameter INVALID		= 3'b101;

  SRAM sram0(addr[12:0], re, we, data);
  
  assign data = (we & !re) ? data_write : 8'hz;
  
  always @(negedge sck) begin
    case(state)
      READ_DATA: begin // READ_DATA
        re <= 1'b1;
        if (cs) begin
          if (~addr[14] & ~addr[13]) begin
            if (counter == 4'b1000) begin
              counter <= 4'b0000;
              state <= INVALID;
            end
            else begin
              counter <= counter + 1'b1;
              so <= data[4'b0111 - counter];
              state <= READ_DATA;
            end
          end
          else begin
            counter <= 4'b0000;
            so <= 1'bz;
            state <= INVALID;
          end
        end
        else begin
          so <= 1'bz;
          counter <= 4'b0000;
          state <= GET_INSTR;
        end
      end
      default: begin // default
        // do nothing
      end
    endcase
  end
  
  always @(posedge sck, negedge cs) begin
    case(state)
      GET_INSTR: begin		// GET_INSTR
        re <= 1'b0;
        we <= 1'b0;
        so <= 1'bz;
        data_in <= 8'h00;
        addr <= 16'h0000;
        
        if (cs) begin
          if (counter == 4'b0111) begin
            counter <= 4'b0000;
            instr[4'b0111 - counter] <= si;
            state <= GET_ADDR;
          end
          else begin
            counter <= counter + 1'b1;
            instr[4'b0111 - counter] <= si;
            state <= GET_INSTR;
          end
        end
        else begin
          counter <= 4'b0000;
          state <= GET_INSTR;
        end
      end
      GET_ADDR: begin		// GET_ADDR
        so <= 1'bz;
        if (cs) begin
          if (counter == 4'b1111) begin
            counter <= 4'b0000;
            addr[4'b1111 - counter] <= si;
            if (instr == 8'h03) begin	
              re <= 1'b1;
              we <= 1'b0;
              state <= READ_DATA;
            end
            else if (instr == 8'h02) begin
              we <= 1'b0;
              re <= 1'b0;
              state <= WRITE_DATA;
            end
            else begin
              state <= INVALID;
            end
          end
          else begin
            counter <= counter + 1'b1;
            addr[4'b1111 - counter] <= si;
            state <= GET_ADDR;
          end
        end
        else begin
          counter <= 4'b0000;
          instr <= 8'h00;
          state <= GET_INSTR;
        end
      end
      READ_DATA: begin		// READ_DATA
     	 // do nothing
      end
      WRITE_DATA: begin		// WRITE_DATA
        if (cs) begin
          if (counter == 4'b0111) begin
            data_in[0] <= si;
            state <= WRITE_DATA;
          end
          else begin
            counter <= counter + 1'b1;
            data_in[4'b0111 - counter] <= si;
            state <= WRITE_DATA;
          end
        end
        else begin
          if (counter == 4'b0111) begin
            we <= 1'b1;
            re <= 1'b0;
			data_write <= data_in;
            counter <= 4'b0000;
            instr <= 8'h00;
            state <= GET_INSTR;
          end
          else begin
            we <= 1'b0;
            re <= 1'b0;
            counter <= 4'b0000;
            instr <= 8'h00;
            state <= GET_INSTR;
          end
        end
      end
      INVALID: begin		// INVALID
        re <= 1'b0;
        we <= 1'b0;
        so <= 1'bz;
        counter <= 4'b0000;
        if (cs) begin
          state <= INVALID;
        end
        else begin
          instr <= 8'h00;
          state <= GET_INSTR;
        end
      end
      default: begin 		// INIT
        so <= 1'bz;
        counter <= 4'h0;
        addr <= 8'h0;
        instr <= 8'h0;
        state <= 3'b000;
      end
    endcase
  end
endmodule
