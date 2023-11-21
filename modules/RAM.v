module RAM(clk, we, r_addr, r_data, w_addr, w_data, write_mode, read_mode, read_signed); 
    //64Kib = 32bit * 16384
    //アドレスは16bitで受け取る
    input wire clk,we;
    input wire [1:0] write_mode, read_mode;  // 0:byte, 1:halfword, 2:word
    input wire read_signed;  // 0:unsigned, 1:signed
    input wire  [31:0] r_addr, w_addr;
    input wire  [31:0] w_data;
    output wire [31:0] r_data;
    wire [31:0] w_data_gen;
    wire [3:0] we_byte;
    reg [31:0] r_data_raw;

    (* ram_style = "block" *) reg [31:0] mem [0:32767];

    integer i;
    initial begin
        $readmemh(`DATAHEX, mem);
    end

    reg [31:0] r_addr_reg;
    reg [1:0] write_mode_reg, read_mode_reg;
    reg read_signed_reg;
    always @(posedge clk) begin
        r_addr_reg <= r_addr;
        write_mode_reg <= write_mode;
        read_mode_reg <= read_mode;
        read_signed_reg <= read_signed;
    end

    always @(posedge clk) begin
        if(we_byte[0])mem[w_addr[31:2]][7:0] <= w_data_gen[7:0];
        if(we_byte[1])mem[w_addr[31:2]][15:8] <= w_data_gen[15:8];
        if(we_byte[2])mem[w_addr[31:2]][23:16] <= w_data_gen[23:16];
        if(we_byte[3])mem[w_addr[31:2]][31:24] <= w_data_gen[31:24];
    end

    always @(posedge clk) begin
        //読み出し
        r_data_raw <= mem[r_addr[31:2]];
    end

    //読み出しデータの処理
    function [31:0] calc_r_data;
        input [31:0] r_data_raw;
        input [31:0] r_addr;
        input [1:0] read_mode;
        input read_signed;
        begin
            case(read_mode)
            `RAM_MODE_BYTE:begin
                case(r_addr[1:0])
                    0: begin
                        if(read_signed)calc_r_data = {{24{r_data_raw[7]}},r_data_raw[7:0]};
                        else calc_r_data = {24'b0,r_data_raw[7:0]};
                    end
                    1: begin
                        if(read_signed)calc_r_data = {{24{r_data_raw[15]}},r_data_raw[15:8]};
                        else calc_r_data = {24'b0,r_data_raw[15:8]};
                    end
                    2: begin
                        if(read_signed)calc_r_data = {{24{r_data_raw[23]}},r_data_raw[23:16]};
                        else calc_r_data = {24'b0,r_data_raw[23:16]};
                    end
                    3: begin
                        if(read_signed)calc_r_data = {{24{r_data_raw[31]}},r_data_raw[31:24]};
                        else calc_r_data = {24'b0,r_data_raw[31:24]};
                    end
                    default:begin
                        //Nothing to do
                    end
                endcase
            end
            `RAM_MODE_HALF:begin
                case(r_addr[1:0])
                    0: begin
                        if(read_signed)calc_r_data = {{16{r_data_raw[15]}},r_data_raw[15:0]};
                        else calc_r_data = {16'b0,r_data_raw[15:0]};
                    end
                    1: begin
                        if(read_signed)calc_r_data = {{16{r_data_raw[23]}},r_data_raw[23:8]};
                        else calc_r_data = {16'b0,r_data_raw[23:8]};
                    end
                    2: begin
                        if(read_signed)calc_r_data = {{16{r_data_raw[31]}},r_data_raw[31:16]};
                        else calc_r_data = {16'b0,r_data_raw[31:16]};
                    end
                    default:begin
                        //Nothing to do
                    end
                endcase
            end
            `RAM_MODE_WORD:begin
                calc_r_data = r_data_raw;
            end
            default:begin
                //Nothing to do
            end
        endcase
    end        
    endfunction
    assign r_data = calc_r_data(r_data_raw, r_addr_reg, read_mode_reg, read_signed_reg);

    //書き込みデータの処理
    function [3:0] calc_we;
        input we;
        input [1:0] write_mode;
        input [31:0] w_addr;
        begin
            if(we)begin
                case(write_mode)
                    `RAM_MODE_BYTE:begin
                        case(w_addr[1:0])
                            0: calc_we=4'b0001;
                            1: calc_we=4'b0010;
                            2: calc_we=4'b0100;
                            3: calc_we=4'b1000;
                            default: begin
                                //Nothing to do
                                calc_we=0;
                            end
                        endcase
                    end
                    `RAM_MODE_HALF:begin
                        case(w_addr[1:0])
                            0: calc_we=4'b0011;
                            1: calc_we=4'b0110;
                            2: calc_we=4'b1100;
                            default: begin
                                //Nothing to do
                                calc_we=0;
                            end
                        endcase
                    end
                    `RAM_MODE_WORD:begin
                        calc_we=4'b1111;
                    end
                    default:begin
                        //Nothing to do
                        calc_we=0;
                    end
                endcase
            end else begin
                calc_we = 0;
            end
        end
    endfunction

    assign we_byte = calc_we(we, write_mode, w_addr);

    function [31:0] calc_w_data_gen;
        input we;
        input [1:0] write_mode;
        input [31:0] w_addr;
        input [31:0] w_data;
        begin
            if(we)begin
                case(write_mode)
                    `RAM_MODE_BYTE:begin
                        case(w_addr[1:0])
                            0: calc_w_data_gen = {24'b0,w_data[7:0]};
                            1: calc_w_data_gen = {16'b0,w_data[7:0],8'b0};
                            2: calc_w_data_gen = {8'b0,w_data[7:0],16'b0};
                            3: calc_w_data_gen = {w_data[7:0],24'b0};
                            default: begin
                                //Nothing to do
                                calc_w_data_gen = 0;
                            end
                        endcase
                    end
                    `RAM_MODE_HALF:begin
                        case(w_addr[1:0])
                            0: calc_w_data_gen = {16'b0,w_data[15:0]};
                            1: calc_w_data_gen = {8'b0,w_data[15:0],8'b0};
                            2: calc_w_data_gen = {w_data[15:0],16'b0};
                            default: begin
                                //Nothing to do
                                calc_w_data_gen = 0;
                            end
                        endcase
                    end
                    `RAM_MODE_WORD:begin
                        calc_w_data_gen = w_data;
                    end
                    default:begin
                        //Nothing to do
                        calc_w_data_gen = 0;
                    end
                endcase
            end else begin
                calc_w_data_gen = 0;
            end
        end        
    endfunction
    assign w_data_gen = calc_w_data_gen(we, write_mode, w_addr, w_data);
endmodule
