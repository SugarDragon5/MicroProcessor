module CPUTop (
    input wire sysclk,
    input wire nrst,
    output wire uart_tx
);
//クロック・リセット信号
    wire clk;
    wire rst;
    assign clk=sysclk;
    assign rst = ~nrst;

//IFステージ
    reg [31:0] pc_IF;
    reg [31:0] iword_IF;

//IDステージ
    reg [31:0] pc_ID;
    //デコーダ入出力
    reg [31:0] iword_ID:
    wire [4:0] srcreg1_num_ID,srcreg2_num_ID,dstreg_num_ID;
    wire [31:0] imm_ID;
    wire [5:0] alucode_ID;
    wire [1:0] aluop1_type_ID,aluop2_type_ID;
    wire reg_we_ID,is_load_ID,is_store_ID,is_halt_ID;
    wire [1:0] ram_read_size_ID,ram_write_size_ID;
    wire ram_read_signed_ID;
    //レジスタ読み込み
    wire [31:0] regdata1_ID,regdata2_ID;
    //オペランドスイッチャー
    wire [31:0] oprl_ID,oprr_ID;


    ROM rom1(
        .clk(clk),
        .r_addr(pc_IF[15:2]),
        .r_data(iword_IF)
    );
    decoder decoder1(
        .ir(iword_ID),
        .srcreg1_num(srcreg1_num_ID),
        .srcreg2_num(srcreg2_num_ID),
        .dstreg_num(dstreg_num_ID),
        .imm(imm_ID),
        .alucode(alucode_ID),
        .aluop1_type(aluop1_type_ID),
        .aluop2_type(aluop2_type_ID),
        .reg_we(reg_we_state_ID),
        .is_load(is_load_ID),
        .is_store(is_store_ID),
        .is_halt(is_halt_ID),
        .ram_read_size(ram_read_size_ID),
        .ram_write_size(ram_write_size_ID),
        .ram_read_signed(ram_read_signed_ID)
    );
    RegisterFile register1(
        .clk(clk),
        //読み込み : IDステージ
        .srcreg1_num(srcreg1_num_ID),
        .srcreg2_num(srcreg2_num_ID),
        .regdata1(regdata1_ID),
        .regdata2(regdata2_ID),
        //書き込み : RWステージ
        .dstreg_num(dstreg_num),
        .write_value(reg_write_value),
        .reg_we(reg_we)
    );
    OperandSwitcher ops1(
        .aluop1_type(aluop1_type_ID),
        .aluop2_type(aluop2_type_ID),
        .pc(pc_ID),
        .regdata1(regdata1_ID),
        .regdata2(regdata2_ID),
        .imm(imm_ID),
        .oprl(oprl_ID),
        .oprr(oprr_ID)
    );
    NPCGenerator NPCGen1(
        .pc(pc),
        .alucode(alucode),
        .imm(imm),
        .reg1dat(regdata1),
        .br_taken(br_taken),
        .npc(npc)
    );
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
            pc_IF<='h8000;
            pc_ID<=0;
            pc_EX<=0;
            pc_MA<=0;
            pc_RW<=0;
        end else begin
            //IFステージ
            if(分岐あり)pc_IF<=分岐先;
            else pc_IF<=pc_IF+4;
            //IDステージ
            if(分岐あり)begin
                //分岐予測に失敗しているのでリセット
                pc_ID<=0;
                iword_ID<=0;
            end else begin
                pc_ID<=pc_IF;
                iword_ID<=iword_IF;
            end
            //EXステージ
            if(分岐あり)begin
                //分岐予測に失敗しているのでリセット
                pc_EX<=0;
                iword_EX<=0;
            end else begin
                pc_EX<=pc_ID;
                iword_EX<=iword_ID;
            end
        end
        
    end
endmodule