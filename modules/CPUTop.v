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

//Hardware Counter
    wire [31:0] hc_OUT_data;
    hardware_counter hardware_counter0(
        .CLK_IP(clk),
        .RST_IP(rst),
        .COUNTER_OP(hc_OUT_data)
    );

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
    //フォワーディング
    wire is_reg1_fwd_ID,is_reg2_fwd_ID;
    assign is_reg1_fwd_ID=(srcreg1_num_ID!=0&&srcreg1_num_ID==dstreg_num_EX);
    assign is_reg2_fwd_ID=(srcreg2_num_ID!=0&&srcreg2_num_ID==dstreg_num_EX);
    wire is_oprl_fwd_ID,is_oprr_fwd_ID;
    assign is_oprl_fwd_ID=(aluop1_type_ID==`OP_TYPE_REG&&is_reg1_fwd_ID);
    assign is_oprr_fwd_ID=(aluop2_type_ID==`OP_TYPE_REG&&is_reg2_fwd_ID);

//EXステージ
    reg [31:0] pc_EX;
    //ALU入力 = posedgeでIDステージから受け取る
    reg [5:0] alucode_EX;
    reg [31:0] imm_EX;
    reg [31:0] oprl_EX,oprr_EX;
    //ALU出力
    wire [31:0] alu_result_EX;
    wire br_taken_EX;
    //NPCGen入力
    reg [31:0] regdata1_EX;
    //NPCGen出力
    wire [31:0] npc_EX;
    //その他 ID-> EX で受け取るデータ
    reg [4:0] dstreg_num_EX;
    reg reg_we_EX,is_load_EX,is_store_EX,is_halt_EX;
    reg [1:0] ram_read_size_EX,ram_write_size_EX;
    reg ram_read_signed_EX;
    reg [31:0] regdata2_EX;
    //LSU
    wire ram_we_EX;
    wire [31:0] mem_address_EX,mem_write_value_EX;
    assign ram_we_EX=is_store_EX;
    assign mem_address_EX=(is_store||is_load)?alu_result_EX:0;
    assign mem_write_value_EX=is_store_EX?regdata2_EX:0;
    //RAM
    wire [31:0] mem_load_value_EX;  // negedge でRAMから受け取る
    wire [31:0] reg_write_value_EX;
    //レジスタOutput
    function [31:0] calc_reg_write_value(
        input is_load,
        input [5:0] alucode,
        input [31:0] alu_result,
        input [31:0] mem_address,
        input [31:0] hc_data,
        input [31:0] mem_load_value
    );
    begin
        if(is_load)begin
            if(alucode==`ALU_LW&&mem_address==`HARDWARE_COUNTER_ADDR)begin
                calc_reg_write_value=hc_data;
            end else begin
                calc_reg_write_value=mem_load_value;
            end
        end else begin
            calc_reg_write_value=alu_result;
        end
    end
    endfunction
    assign reg_write_value_EX=calc_reg_write_value(
        is_load_EX,
        alucode_EX,
        alu_result_EX,
        mem_address_EX,
        hc_OUT_data,
        mem_load_value_EX
    );
    //TODO: フォワーディングの計算

//RWステージ
    //レジスタ書き込みはnegedgeで行う
    reg [31:0] pc_RW;
    reg [31:0] reg_write_value_RW;
    reg [4:0] dstreg_num_RW;
    reg reg_we_RW;

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
        .dstreg_num(dstreg_num_RW),
        .write_value(reg_write_value_RW),
        .reg_we(reg_we_RW)
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
    alu alu1(
        .alucode(alucode_EX),
        .op1(oprl_EX),
        .op2(oprr_EX),
        .alu_result(alu_result_EX),
        .br_taken(br_taken_EX)
    );
    NPCGenerator NPCGen1(
        .pc(pc_EX),
        .alucode(alucode_EX),
        .imm(imm_EX),
        .reg1dat(regdata1_EX),
        .br_taken(br_taken_EX),
        .npc(npc_EX)
    );
    //RAM
    RAM ram1(
        .clk(clk),
        .we(ram_we_EX),
        .r_addr(mem_address_EX),
        .r_data(mem_load_value_EX),
        .w_addr(mem_address_EX),
        .w_data(mem_write_value_EX),
        .write_mode(ram_write_size_EX),
        .read_mode(ram_read_size_EX),
        .read_signed(ram_read_signed_EX)
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
    assign uart_IN_data = mem_write_value_EX[7:0];  // ストアするデータをモジュールへ入力
    assign uart_we = ((mem_address_EX == `UART_ADDR) && (is_store_EX == `ENABLE)) ? 1'b1 : 1'b0;  // シリアル通信用アドレスへのストア命令実行時に送信開始信号をアサート
    assign uart_tx = uart_OUT_data;  // シリアル通信モジュールの出力はFPGA外部へと出力

    //for debug
    `ifdef COREMARK_UART_DEBUG
        always @(posedge uart_we) begin
            $write("%c", uart_IN_data);  // シリアル通信モジュールへのストア命令実行時に送信データを表示
        end
    `endif

    //ステージ遷移
    always @(posedge clk) begin
        if(rst)begin
            pc_IF<='h8000;
            pc_ID<=0;
            pc_EX<=0;
            pc_MA<=0;
            pc_RW<=0;
        end else begin
            if(br_taken_EX)begin
                //分岐アリ = ID, EXをnopに、IFに分岐先を代入
                //IFステージ
                pc_IF<=npc_EX;
                //IDステージ
                pc_ID<=0;
                iword_ID<=0;
                //EXステージ
                pc_EX<=0;
                alucode_EX<=`ALU_NOP;
                imm_EX<=0;
                oprl_EX<=0;
                oprr_EX<=0;
                regdata1_EX<=0;
                regdata2_EX<=0;
                dstreg_num_EX<=0;
                reg_we_EX<=`REG_NONE;
                is_load_EX<=`DISABLE;
                is_store_EX<=`DISABLE;
                is_halt_EX<=`DISABLE;
                ram_read_size_EX<=`RAM_MODE_NONE;
                ram_write_size_EX<=`RAM_MODE_NONE;
                ram_read_signed_EX<=`RAM_MODE_UNSIGNED;
            end else begin
                //IFステージ
                pc_IF<=pc_IF+4;
                //IDステージ
                pc_ID<=pc_IF;
                iword_ID<=iword_IF;
                //EXステージ
                pc_EX<=pc_ID;
                alucode_EX<=alucode_ID;
                imm_EX<=imm_ID;
                if(is_oprl_fwd_ID)oprl_EX<=reg_write_value_EX;
                else oprl_EX<=oprl_ID;
                if(is_oprr_fwd_ID)oprr_EX<=reg_write_value_EX;
                else oprr_EX<=oprr_ID;
                if(is_reg1_fwd_ID)regdata1_EX<=reg_write_value_EX;
                else regdata1_EX<=regdata1_ID;
                if(is_reg2_fwd_ID)regdata2_EX<=reg_write_value_EX;
                else regdata2_EX<=regdata2_ID;
                dstreg_num_EX<=dstreg_num_ID;
                reg_we_EX<=reg_we_ID;
                is_load_EX<=is_load_ID;
                is_store_EX<=is_store_ID;
                is_halt_EX<=is_halt_ID;
                ram_read_size_EX<=ram_read_size_ID;
                ram_write_size_EX<=ram_write_size_ID;
                ram_read_signed_EX<=ram_read_signed_ID;
            end
            //RWステージ: 分岐の有無に無関係
            pc_RW<=pc_EX;
            reg_write_value_RW<=reg_write_value_EX;
            dstreg_num_RW<=dstreg_num_EX;
            reg_we_RW<=reg_we_EX;
        end
    end
endmodule