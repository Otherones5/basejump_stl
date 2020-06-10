// Age arbitration unit

module bsg_age_arb #( parameter inputs_p = "not assigned"
                     ,parameter ts_width_p=-1)
    (input clk_i
    , input reset_i
    , input ready_i
    , input [inputs_p-1:0][ts_width_p-1:0] ts_i
    , input [inputs_p-1:0] reqs_i
    , output [inputs_p-1:0] grants_o
    );
  if (inputs_p == 1)
    always_comb
      unique casez({ready_i, reqs_i})
        2'b0_?: grants_o = 1'b0;
        2'b1_0: grants_o = 1'b0;
        2'b1_1: grants_o = 1'b1;
      endcase
  
  if (inputs_p == 2)
    always_comb
      begin
        logic cmp;
        assign cmp = ts_i[0] < ts_i[1];

        unique casez({ready_i, reqs_i, cmp})
          4'b0_??_?: grants_o = 2'b00;
          4'b1_00_?: grants_o = 2'b00;
          4'b1_01_?: grants_o = 2'b01;
          4'b1_10_?: grants_o = 2'b10;
          4'b1_11_1: grants_o = 2'b01;
          4'b1_11_0: grants_o = 2'b10;
          default:
            begin
              $display("error: %b", {ready_i, reqs_i, cmp});
              grants_o = 2'b00;
            end
        endcase
      end

  if (inputs_p == 3)
    always_comb
      begin
        logic [2:0] cmp;
        assign cmp = {ts_i[1] < ts_i[2], ts_i[0] < ts_i[2], ts_i[0] < ts_i[1]};

        unique casez({ready_i, reqs_i, cmp})
          7'b0_???_???: grants_o = 3'b000;
          7'b1_000_???: grants_o = 3'b000;
          7'b1_001_???: grants_o = 3'b001;
          7'b1_010_???: grants_o = 3'b010;
          7'b1_100_???: grants_o = 3'b100;
          7'b1_011_??1: grants_o = 3'b001;
          7'b1_011_?1?: grants_o = 3'b001;
          7'b1_011_??0: grants_o = 3'b010;
          7'b1_011_1??: grants_o = 3'b010;
          7'b1_101_?0?: grants_o = 3'b100;
          7'b1_110_0??: grants_o = 3'b100;
          7'b1_111_?11: grants_o = 3'b001;
          7'b1_111_1?0: grants_o = 3'b010;
          7'b1_111_00?: grants_o = 3'b100;
          default:
            begin
              $display("error: %b", {ready_i, reqs_i, cmp});
              grants_o = 3'b000;
            end
        endcase
      end

  if (inputs_p == 4)
    always_comb
      begin
        logic [5:0] cmp;
        assign cmp = {ts_i[2] < ts_i[3],
                      ts_i[1] < ts_i[3], ts_i[1] < ts_i[2],
                      ts_i[0] < ts_i[3], ts_i[0] < ts_i[2], ts_i[0] < ts_i[1]};

        unique casez({ready_i, reqs_i, cmp})
          11'b0_????_??????: grants_o = 4'b0000;
          11'b1_0000_??????: grants_o = 4'b0000;
          11'b1_0001_??????: grants_o = 4'b0001;
          11'b1_0010_??????: grants_o = 4'b0010;
          11'b1_0100_??????: grants_o = 4'b0100;
          11'b1_1000_??????: grants_o = 4'b1000;
          11'b1_0011_?????1: grants_o = 4'b0001;
          11'b1_0101_????1?: grants_o = 4'b0001;
          11'b1_1001_???1??: grants_o = 4'b0001;
          11'b1_0011_?????0: grants_o = 4'b0010;
          11'b1_0110_??1???: grants_o = 4'b0010;
          11'b1_1010_?1????: grants_o = 4'b0010;
          11'b1_0101_????0?: grants_o = 4'b0100;
          11'b1_0110_??0???: grants_o = 4'b0100;
          11'b1_1100_1?????: grants_o = 4'b0100;
          11'b1_1001_???0??: grants_o = 4'b1000;
          11'b1_1010_?0????: grants_o = 4'b1000;
          11'b1_1100_0?????: grants_o = 4'b1000;
          11'b1_0111_????11: grants_o = 4'b0001;
          11'b1_1011_???1?1: grants_o = 4'b0001;
          11'b1_1101_???11?: grants_o = 4'b0001;
          11'b1_0111_??1??0: grants_o = 4'b0010;
          11'b1_1011_?1???0: grants_o = 4'b0010;
          11'b1_1110_?11???: grants_o = 4'b0010;
          11'b1_0111_??0?0?: grants_o = 4'b0100;
          11'b1_1101_1???0?: grants_o = 4'b0100;
          11'b1_1110_1?0???: grants_o = 4'b0100;
          11'b1_1011_?0?0??: grants_o = 4'b1000;
          11'b1_1101_0??0??: grants_o = 4'b1000;
          11'b1_1110_00????: grants_o = 4'b1000;
          11'b1_1111_???111: grants_o = 4'b0001;
          11'b1_1111_?11??0: grants_o = 4'b0010;
          11'b1_1111_1?0?0?: grants_o = 4'b0100;
          11'b1_1111_00?0??: grants_o = 4'b1000;
          default:
            begin
              $display("error: %b", {ready_i, reqs_i, cmp});
              grants_o = 4'b0000;
            end
        endcase
      end

  if (inputs_p == 5)
    always_comb
      begin
        logic [9:0] cmp;
        assign cmp  = {ts_i[3] < ts_i[4],
                       ts_i[2] < ts_i[4], ts_i[2] < ts_i[3],
                       ts_i[1] < ts_i[4], ts_i[1] < ts_i[3], ts_i[1] < ts_i[2],
                       ts_i[0] < ts_i[4], ts_i[0] < ts_i[3], ts_i[0] < ts_i[2],
                       ts_i[0] < ts_i[1]};

        unique casez({ready_i, reqs_i, cmp})
          16'b0_?????_??????????: grants_o = 5'b00000;
          16'b1_00000_??????????: grants_o = 5'b00000;
          16'b1_00001_??????????: grants_o = 5'b00001;
          16'b1_00010_??????????: grants_o = 5'b00010;
          16'b1_00100_??????????: grants_o = 5'b00100;
          16'b1_01000_??????????: grants_o = 5'b01000;
          16'b1_10000_??????????: grants_o = 5'b10000;
          16'b1_00011_?????????1: grants_o = 5'b00001;
          16'b1_00101_????????1?: grants_o = 5'b00001;
          16'b1_01001_???????1??: grants_o = 5'b00001;
          16'b1_10001_??????1???: grants_o = 5'b00001;
          16'b1_00011_?????????0: grants_o = 5'b00010;
          16'b1_00110_?????1????: grants_o = 5'b00010;
          16'b1_01010_????1?????: grants_o = 5'b00010;
          16'b1_10010_???1??????: grants_o = 5'b00010;
          16'b1_00101_????????0?: grants_o = 5'b00100;
          16'b1_00110_?????0????: grants_o = 5'b00100;
          16'b1_01100_??1???????: grants_o = 5'b00100;
          16'b1_10100_?1????????: grants_o = 5'b00100;
          16'b1_01001_???????0??: grants_o = 5'b01000;
          16'b1_01010_????0?????: grants_o = 5'b01000;
          16'b1_01100_??0???????: grants_o = 5'b01000;
          16'b1_11000_1?????????: grants_o = 5'b01000;
          16'b1_10001_??????0???: grants_o = 5'b10000;
          16'b1_10010_???0??????: grants_o = 5'b10000;
          16'b1_10100_?0????????: grants_o = 5'b10000;
          16'b1_11000_0?????????: grants_o = 5'b10000;
          16'b1_00111_????????11: grants_o = 5'b00001;
          16'b1_01011_???????1?1: grants_o = 5'b00001;
          16'b1_10011_??????1??1: grants_o = 5'b00001;
          16'b1_01101_???????11?: grants_o = 5'b00001;
          16'b1_10101_??????1?1?: grants_o = 5'b00001;
          16'b1_11001_??????11??: grants_o = 5'b00001;
          16'b1_00111_?????1???0: grants_o = 5'b00010;
          16'b1_01011_????1????0: grants_o = 5'b00010;
          16'b1_10011_???1?????0: grants_o = 5'b00010;
          16'b1_01110_????11????: grants_o = 5'b00010;
          16'b1_10110_???1?1????: grants_o = 5'b00010;
          16'b1_11010_???11?????: grants_o = 5'b00010;
          16'b1_00111_?????0??0?: grants_o = 5'b00100;
          16'b1_01101_??1?????0?: grants_o = 5'b00100;
          16'b1_10101_?1??????0?: grants_o = 5'b00100;
          16'b1_01110_??1??0????: grants_o = 5'b00100;
          16'b1_10110_?1???0????: grants_o = 5'b00100;
          16'b1_11100_?11???????: grants_o = 5'b00100;
          16'b1_01011_????0??0??: grants_o = 5'b01000;
          16'b1_01101_??0????0??: grants_o = 5'b01000;
          16'b1_11001_1??????0??: grants_o = 5'b01000;
          16'b1_01110_??0?0?????: grants_o = 5'b01000;
          16'b1_11010_1???0?????: grants_o = 5'b01000;
          16'b1_11100_1?0???????: grants_o = 5'b01000;
          16'b1_10011_???0??0???: grants_o = 5'b10000;
          16'b1_10101_?0????0???: grants_o = 5'b10000;
          16'b1_11001_0?????0???: grants_o = 5'b10000;
          16'b1_10110_?0?0??????: grants_o = 5'b10000;
          16'b1_11010_0??0??????: grants_o = 5'b10000;
          16'b1_11100_00????????: grants_o = 5'b10000;
          16'b1_01111_???????111: grants_o = 5'b00001;
          16'b1_11101_??????111?: grants_o = 5'b00001;
          16'b1_11011_??????11?1: grants_o = 5'b00001;
          16'b1_10111_??????1?11: grants_o = 5'b00001;
          16'b1_01111_????11???0: grants_o = 5'b00010;
          16'b1_11110_???111????: grants_o = 5'b00010;
          16'b1_11011_???11????0: grants_o = 5'b00010;
          16'b1_10111_???1?1???0: grants_o = 5'b00010;
          16'b1_01111_??1??0??0?: grants_o = 5'b00100;
          16'b1_11110_?11??0????: grants_o = 5'b00100;
          16'b1_11101_?11?????0?: grants_o = 5'b00100;
          16'b1_10111_?1???0??0?: grants_o = 5'b00100;
          16'b1_01111_??0?0??0??: grants_o = 5'b01000;
          16'b1_11110_1?0?0?????: grants_o = 5'b01000;
          16'b1_11101_1?0????0??: grants_o = 5'b01000;
          16'b1_11011_1???0??0??: grants_o = 5'b01000;
          16'b1_10111_?0?0??0???: grants_o = 5'b10000;
          16'b1_11011_0??0??0???: grants_o = 5'b10000;
          16'b1_11101_00????0???: grants_o = 5'b10000;
          16'b1_11110_00?0??????: grants_o = 5'b10000;
          16'b1_11111_??????1111: grants_o = 5'b00001;
          16'b1_11111_???111???0: grants_o = 5'b00010;
          16'b1_11111_?11??0??0?: grants_o = 5'b00100;
          16'b1_11111_1?0?0??0??: grants_o = 5'b01000;
          16'b1_11111_00?0??0???: grants_o = 5'b10000;
          default:
            begin
              $display("error: %b", {ready_i, reqs_i, cmp});
              grants_o = 5'b00000;
            end
        endcase
      end
endmodule
