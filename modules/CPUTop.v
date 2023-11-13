module CPUTop (
    input wire sysclk,
    input wire nrst,
    output wire uart_tx
);
    //リセット信号
    wire clk;
    wire rst;
    assign clk=sysclk;
    assign rst = ~nrst;
    //ステージ変数
    reg [3:0] stage;
    //プログラムカウンタ変数
    reg [31:0] pc;
    wire [31:0] npc;
    wire [31:0] regdata1,regdata2;
    wire [31:0] imm;
    wire br_taken;
    wire [5:0] alucode;
    NPCGenerator NPCGen1(
        .pc(pc),
        .alucode(alucode),
        .imm(imm),
        .reg1dat(regdata1),
        .br_taken(br_taken),
        .npc(npc)
    );
    //ROM
    wire [31:0] iword;
    ROM rom1(
        .clk(clk),
        .r_addr(pc[15:2]),
        .r_data(iword)
    );
    //命令デコーダ
    reg decoder_reset;
    wire [4:0] srcreg1_num,srcreg2_num,dstreg_num;
    wire [1:0] aluop1_type,aluop2_type;
    wire reg_we_state,is_load,is_store,is_halt;
    wire [1:0] ram_read_size,ram_write_size;
    wire ram_read_signed;
    decoder decoder1(
        .clk(clk),
        .rst(rst|decoder_reset),
        .ir(iword),
        .srcreg1_num(srcreg1_num),
        .srcreg2_num(srcreg2_num),
        .dstreg_num(dstreg_num),
        .imm(imm),
        .alucode(alucode),
        .aluop1_type(aluop1_type),
        .aluop2_type(aluop2_type),
        .reg_we(reg_we_state),
        .is_load(is_load),
        .is_store(is_store),
        .is_halt(is_halt),
        .ram_read_size(ram_read_size),
        .ram_write_size(ram_write_size),
        .ram_read_signed(ram_read_signed)
    );
    //レジスタファイル
    wire [31:0] reg_write_value;
    reg reg_we;
    RegisterFile register1(
        .clk(clk),
        .srcreg1_num(srcreg1_num),
        .srcreg2_num(srcreg2_num),
        .dstreg_num(dstreg_num),
        .write_value(reg_write_value),
        .reg_we(reg_we),
        .regdata1(regdata1),
        .regdata2(regdata2)
    );
    //オペランドスイッチャー
    wire [31:0] oprl,oprr;
    OperandSwitcher ops1(
        .aluop1_type(aluop1_type),
        .aluop2_type(aluop2_type),
        .pc(pc),
        .regdata1(regdata1),
        .regdata2(regdata2),
        .imm(imm),
        .oprl(oprl),
        .oprr(oprr)
    );
    //ALU
    reg alu_reset;
    wire [31:0] alu_result;
    alu alu1(
        .clk(clk),
        .rst(rst|alu_reset),
        .alucode(alucode),
        .op1(oprl),
        .op2(oprr),
        .alu_result(alu_result),
        .br_taken(br_taken)
    );
    //LSU
    wire [31:0] mem_load_value;
    wire [31:0] mem_address,mem_write_value;
    wire [31:0] hc_OUT_data;

    LoadStoreUnit LSU1(
        .alu_result(alu_result),
        .regdata2(regdata2),
        .is_load(is_load),
        .is_store(is_store),
        .mem_load_value(
            (alucode==`ALU_LW&&mem_address==`HARDWARE_COUNTER_ADDR)?hc_OUT_data:mem_load_value
        ),
        .reg_write_value(reg_write_value),
        .mem_address(mem_address),
        .mem_write_value(mem_write_value)
    );
    //RAM
    reg ram_we;
    RAM ram1(
        .clk(clk),
        .we(ram_we),
        .r_addr(mem_address),
        .r_data(mem_load_value),
        .w_addr(mem_address),
        .w_data(mem_write_value),
        .write_mode(ram_write_size),
        .read_mode(ram_read_size),
        .read_signed(ram_read_signed)
    );
    //UArt
    wire [7:0] uart_IN_data;
    wire uart_we;
    wire uart_OUT_data;

    uart uart0(
        .uart_tx(uart_OUT_data),
        .uart_wr_i(uart_we),
        .uart_dat_i(uart_IN_data),
        .sys_clk_i(clk),
        .sys_rst_i(rst)
    );

    // Memory Accessステージに以下のような記述を追加
    assign uart_IN_data = mem_write_value[7:0];  // ストアするデータをモジュールへ入力
    assign uart_we = ((mem_address == `UART_ADDR) && (is_store == `ENABLE)) ? 1'b1 : 1'b0;  // シリアル通信用アドレスへのストア命令実行時に送信開始信号をアサート
    assign uart_tx = uart_OUT_data;  // シリアル通信モジュールの出力はFPGA外部へと出力


    //for debug
    `ifdef COREMARK_UART_DEBUG
        always @(posedge uart_we) begin
            $write("%c", uart_IN_data);  // シリアル通信モジュールへのストア命令実行時に送信データを表示
        end
    `endif

    //Hardware Counter

    hardware_counter hardware_counter0(
        .CLK_IP(clk),
        .RST_IP(rst),
        .COUNTER_OP(hc_OUT_data)
    );


    //ステージ遷移
    always @(posedge clk) begin
        if(rst)begin
            stage<=`IF_STAGE;
            pc<='h8000;
        end else begin
            case(stage)
                //命令フェッチクロック
                `IF_STAGE:begin
                    //PCの更新→デコーダが走る
                    stage <= `RR_STAGE;
                    decoder_reset<=1;
                end
                //レジスタ・データ準備クロック
                `RR_STAGE:begin
                    //デコーダが計算した値をもとに、レジスタからデータを読み出す
                    stage <= `EX_STAGE;
                    decoder_reset<=0;
                    alu_reset<=1;
                    `ifdef COREMARK_TRACE
                        $write("0x%4x: 0x%8x",pc[15:0],iword);
                    `endif
                end
                //演算クロック
                `EX_STAGE:begin
                    //デコーダ・レジスタの値をもとに、ALUが演算を行う
                    stage <= `MA_STAGE;
                    alu_reset<=0;
                    if((mem_address == `UART_ADDR) && (is_store == `ENABLE))ram_we<=0;
                    else ram_we<=is_store;
                end
                //RAM書き込みクロック
                `MA_STAGE:begin
                    //次クロックにレジスタ書き込みを行うかを書き込む
                    stage <= `RW_STAGE;
                    ram_we<=0;
                    reg_we<=reg_we_state;
                end
                //レジスタ書き込みクロック
                `RW_STAGE:begin
                    stage <= `IF_STAGE;
                    reg_we<=0;
                    pc <= npc;
                    `ifdef COREMARK_TRACE
                        if(reg_we)begin
                            $write(" # x%02d = 0x%8x",dstreg_num,reg_write_value);
                        end else $write(" # (no destination)");
                        if(is_store)begin
                            if(ram_write_size==`RAM_MODE_BYTE)$write("; mem[0x%08x] <- 0x%02x",mem_address,mem_write_value[7:0]);
                            else if(ram_write_size==`RAM_MODE_HALF)$write("; mem[0x%08x] <- 0x%04x",mem_address,mem_write_value[15:0]);
                            else if(ram_write_size==`RAM_MODE_WORD)$write("; mem[0x%08x] <- 0x%08x",mem_address,mem_write_value);
                        end else if(is_load)begin
                            if(ram_read_size==`RAM_MODE_BYTE)$write(";            0x%02x <- mem[0x%08x]",mem_load_value[7:0],mem_address);
                            if(ram_read_size==`RAM_MODE_HALF)$write(";          0x%04x <- mem[0x%08x]",mem_load_value[15:0],mem_address);
                            if(ram_read_size==`RAM_MODE_WORD)$write(";      0x%08x <- mem[0x%08x]",mem_load_value,mem_address);
                        end
                        $write("\n");
                    `endif
                end
            endcase
        end
        
    end
endmodule