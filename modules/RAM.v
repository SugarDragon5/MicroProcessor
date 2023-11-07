module RAM(clk, we, r_addr, r_data, w_addr, w_data, write_mode, read_mode, read_signed); 
    //64Kib = 32bit * 16384
    //アドレスは16bitで受け取る
    input clk,we;
    input [1:0] write_mode, read_mode;  // 0:byte, 1:halfword, 2:word
    input read_signed;  // 0:unsigned, 1:signed
    input  [31:0] r_addr, w_addr;
    input  [31:0] w_data;
    output reg [31:0] r_data;
    reg [31:0] mem [65536];

    integer i;
    initial begin
        $readmemh(`DATAHEX, mem);
    end

    always @(posedge clk) begin
        if(we)begin
            case(write_mode)
                `RAM_MODE_BYTE:begin
                    case(w_addr[1:0])
                        0: mem[w_addr[31:2]][7:0] <= w_data[7:0];
                        1: mem[w_addr[31:2]][15:8] <= w_data[7:0];
                        2: mem[w_addr[31:2]][23:16] <= w_data[7:0];
                        3: mem[w_addr[31:2]][31:24] <= w_data[7:0];
                    endcase
                end
                `RAM_MODE_HALF:begin
                    case(w_addr[1:0])
                        0: mem[w_addr[31:2]][15:0] <= w_data[15:0];
                        1: mem[w_addr[31:2]][23:8] <= w_data[15:0];
                        2: mem[w_addr[31:2]][31:16] <= w_data[15:0];
                    endcase
                end
                `RAM_MODE_WORD:begin
                    mem[w_addr[31:2]] <= w_data;
                end
            endcase
        end else begin
            //読み出し
            case(read_mode)
                `RAM_MODE_BYTE:begin
                    case(r_addr[1:0])
                        0: begin
                            if(read_signed)r_data <= {{24{mem[r_addr[31:2]][7]}},mem[r_addr[31:2]][7:0]};
                            else r_data <= {24'b0,mem[r_addr[31:2]][7:0]};
                        end
                        1: begin
                            if(read_signed)r_data <= {{24{mem[r_addr[31:2]][15]}},mem[r_addr[31:2]][15:8]};
                            else r_data <= {24'b0,mem[r_addr[31:2]][15:8]};
                        end
                        2: begin
                            if(read_signed)r_data <= {{24{mem[r_addr[31:2]][23]}},mem[r_addr[31:2]][23:16]};
                            else r_data <= {24'b0,mem[r_addr[31:2]][23:16]};
                        end
                        3: begin
                            if(read_signed)r_data <= {{24{mem[r_addr[31:2]][31]}},mem[r_addr[31:2]][31:24]};
                            else r_data <= {24'b0,mem[r_addr[31:2]][31:24]};
                        end
                    endcase
                end
                `RAM_MODE_HALF:begin
                    case(r_addr[1:0])
                        0: begin
                            if(read_signed)r_data <= {{16{mem[r_addr[31:2]][15]}},mem[r_addr[31:2]][15:0]};
                            else r_data <= {16'b0,mem[r_addr[31:2]][15:0]};
                        end
                        1: begin
                            if(read_signed)r_data <= {{16{mem[r_addr[31:2]][23]}},mem[r_addr[31:2]][23:8]};
                            else r_data <= {16'b0,mem[r_addr[31:2]][23:8]};
                        end
                        2: begin
                            if(read_signed)r_data <= {{16{mem[r_addr[31:2]][31]}},mem[r_addr[31:2]][31:16]};
                            else r_data <= {16'b0,mem[r_addr[31:2]][31:16]};
                        end
                    endcase
                end
                `RAM_MODE_WORD:begin
                    r_data <= mem[r_addr[31:2]];
                end
            endcase
        end
    end
endmodule
