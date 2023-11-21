`include "define.v"
`include "testdata.v"

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
    wire [31:0] iword_IF;
    //BTB出力
    wire [31:0] npc_predict_IF;

//IDステージ
    reg [31:0] pc_ID;
    //デコーダ入出力
    reg [31:0] iword_ID;
    wire [4:0] srcreg1_num_ID,srcreg2_num_ID,dstreg_num_ID;
    wire [31:0] imm_ID;
    wire [5:0] alucode_ID;
    wire [1:0] aluop1_type_ID,aluop2_type_ID;
    wire reg_we_ID,is_load_ID,is_store_ID,is_halt_ID;
    wire [1:0] ram_read_size_ID,ram_write_size_ID;
    wire ram_read_signed_ID;
    wire is_multiclock_ID;
    //レジスタ読み込み
    wire [31:0] regdata1_ID,regdata2_ID;
    //オペランドスイッチャー
    wire [31:0] oprl_ID,oprr_ID;
    //フォワーディング
    wire is_reg1_fwd_EE,is_reg2_fwd_EE; //EX -> EXのフォワーディング
    wire is_oprl_fwd_EE,is_oprr_fwd_EE; //EX -> EXのフォワーディング
    wire is_reg1_fwd_ME,is_reg2_fwd_ME; //MA -> EXのフォワーディング
    wire is_oprl_fwd_ME,is_oprr_fwd_ME; //MA -> EXのフォワーディング
    //ストール判定
    wire is_stall_DE;

//EXステージ
    reg [31:0] pc_EX;
    reg [31:0] iword_EX;
    //ALU入力 = posedgeでIDステージから受け取る
    reg [5:0] alucode_EX;
    reg [31:0] imm_EX;
    reg [31:0] oprl_EX,oprr_EX;
    //ALU出力
    wire [31:0] alu_result_EX;
    wire br_taken_EX;
    //NPCGen入力候補
    wire [31:0] npc_default_EX;
    wire [31:0] npc_branch_EX;
    wire [31:0] npc_jalr_EX;
    
    //NPCGen出力
    wire [31:0] npc_EX;
    //その他 ID-> EX で受け取るデータ
    reg [4:0] dstreg_num_EX;
    reg reg_we_EX,is_load_EX,is_store_EX,is_halt_EX;
    reg [1:0] ram_read_size_EX,ram_write_size_EX;
    reg ram_read_signed_EX;
    reg [31:0] regdata1_EX;
    reg [31:0] regdata2_EX;   
    //マルチクロック命令
    reg is_multiclock_EX;
    reg is_multiplier_input_EX;
    wire done_multiplier_EX;
    wire [31:0] multi_result_EX;
    assign npc_default_EX=pc_EX+4;
    assign npc_branch_EX=pc_EX+imm_EX;
    assign npc_jalr_EX=regdata1_EX+imm_EX;

//MAステージ
    reg [31:0] pc_MA;
    reg [31:0] iword_MA;
    reg [5:0] alucode_MA;
    reg [31:0] alu_result_MA;
    //その他 EX-> MA で受け取るデータ
    reg [4:0] dstreg_num_MA;
    reg reg_we_MA,is_load_MA,is_store_MA,is_halt_MA;
    reg [1:0] ram_read_size_MA,ram_write_size_MA;
    reg ram_read_signed_MA;
    reg [31:0] regdata2_MA;
    //LSU
    wire ram_we_MA;
    wire [31:0] mem_address_MA,mem_write_value_MA;
    assign ram_we_MA=is_store_MA;
    assign mem_address_MA=(is_store_MA||is_load_MA)?alu_result_MA:0;
    assign mem_write_value_MA=is_store_MA?regdata2_MA:0;
    //RAM
    wire [31:0] mem_load_value_MA;  // negedge でRAMから受け取る
    wire [31:0] reg_write_value_MA;
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
    assign reg_write_value_MA=calc_reg_write_value(
        is_load_MA,
        alucode_MA,
        alu_result_MA,
        mem_address_MA,
        hc_OUT_data,
        mem_load_value_MA
    );


//RWステージ
    //レジスタ書き込みはnegedgeで行う
    reg [31:0] pc_RW;
    reg [31:0] reg_write_value_RW;
    reg [4:0] dstreg_num_RW;
    reg reg_we_RW;

//モジュールインスタンス
    //ROM: IFステージ
    //posedgeでaddrが代入され、negedgeでdataをfetch
    ROM rom1(
        .clk(clk),
        .r_addr(pc_IF[15:2]),
        .r_data(iword_IF)
    );
    //Predictor: IFステージ
    Predictor predictor1(
        .clk(clk),
        .rst(rst),
        .PC(pc_IF[15:0]),
        .NPC_predict(npc_predict_IF),
        .PC_actual(pc_EX[15:0]),
        .NPC_actual(npc_EX[15:0]),
        .is_taken_actual(br_taken_EX)
    );
    //Decoder: IDステージ
    //posedgeでiwordが代入され、そのまま計算が走る
    decoder decoder1(
        .ir(iword_ID),
        .srcreg1_num(srcreg1_num_ID),
        .srcreg2_num(srcreg2_num_ID),
        .dstreg_num(dstreg_num_ID),
        .imm(imm_ID),
        .alucode(alucode_ID),
        .aluop1_type(aluop1_type_ID),
        .aluop2_type(aluop2_type_ID),
        .reg_we(reg_we_ID),
        .is_load(is_load_ID),
        .is_store(is_store_ID),
        .is_halt(is_halt_ID),
        .is_multiclock(is_multiclock_ID),
        .ram_read_size(ram_read_size_ID),
        .ram_write_size(ram_write_size_ID),
        .ram_read_signed(ram_read_signed_ID)
    );
    //RegisterFile: IDステージ, RWステージ
    //読み込みはリアルタイム。posedge→Decoder→RF
    //書き込みはnegedgeで行う。
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
    //OPSwitcher: IDステージ
    //Decoderで計算したデータを入力
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
    //ALU: EXステージ
    //posedgeでデータ入力→計算
    alu alu1(
        .alucode(alucode_EX),
        .op1(oprl_EX),
        .op2(oprr_EX),
        .alu_result(alu_result_EX),
        .br_taken(br_taken_EX)
    );

    //multiclockalu: EXステージ
    //乗除算器
    multiclockalu multiclockalu1(
        .clk(clk),
        .rst(is_multiplier_input_EX),
        .alucode(alucode_EX),
        .op1(oprl_EX),
        .op2(oprr_EX),
        .result(multi_result_EX),
        .done(done_multiplier_EX)
    );

    //NPCGenerator: EXステージ
    //decoder, aluの計算結果から分岐先を計算
    NPCGenerator NPCGen1(
        .pc(pc_EX),
        .alucode(alucode_EX),
        .npc_default(npc_default_EX),
        .npc_branch(npc_branch_EX),
        .npc_jalr(npc_jalr_EX),
        .br_taken(br_taken_EX),
        .npc(npc_EX)
    );
    //RAM: MAステージ
    //posedgeでinputをうけ、negedgeでデータ入出力
    RAM ram1(
        .clk(clk),
        .we(ram_we_MA),
        .r_addr(mem_address_MA),
        .r_data(mem_load_value_MA),
        .w_addr(mem_address_MA),
        .w_data(mem_write_value_MA),
        .write_mode(ram_write_size_MA),
        .read_mode(ram_read_size_MA),
        .read_signed(ram_read_signed_MA)
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

    //ID -> EX でMA待ちストールを行うか
    assign is_stall_DE=(is_load_EX&&(srcreg1_num_ID==dstreg_num_EX||srcreg2_num_ID==dstreg_num_EX));
    //EX -> EX のフォワーディングを行うか
    assign is_reg1_fwd_EE=(srcreg1_num_ID!=0&&srcreg1_num_ID==dstreg_num_EX);
    assign is_reg2_fwd_EE=(srcreg2_num_ID!=0&&srcreg2_num_ID==dstreg_num_EX);
    assign is_oprl_fwd_EE=(aluop1_type_ID==`OP_TYPE_REG&&is_reg1_fwd_EE);
    assign is_oprr_fwd_EE=(aluop2_type_ID==`OP_TYPE_REG&&is_reg2_fwd_EE);
    //MA -> EX のフォワーディングを行うか
    assign is_reg1_fwd_ME=(srcreg1_num_ID!=0&&srcreg1_num_ID==dstreg_num_MA);
    assign is_reg2_fwd_ME=(srcreg2_num_ID!=0&&srcreg2_num_ID==dstreg_num_MA);
    assign is_oprl_fwd_ME=(aluop1_type_ID==`OP_TYPE_REG&&is_reg1_fwd_ME);
    assign is_oprr_fwd_ME=(aluop2_type_ID==`OP_TYPE_REG&&is_reg2_fwd_ME);

    // Memory Accessステージに以下のような記述を追加
    assign uart_IN_data = mem_write_value_MA[7:0];  // ストアするデータをモジュールへ入力
    assign uart_we = ((mem_address_MA == `UART_ADDR) && (is_store_MA == `ENABLE)) ? 1'b1 : 1'b0;  // シリアル通信用アドレスへのストア命令実行時に送信開始信号をアサート
    assign uart_tx = uart_OUT_data;  // シリアル通信モジュールの出力はFPGA外部へと出力

    //for debug
    `ifdef COREMARK_UART_DEBUG
        always @(posedge uart_we) begin
            $write("%c", uart_IN_data);  // シリアル通信モジュールへのストア命令実行時に送信データを表示
        end
    `endif
    `ifdef DEBUG_BRANCH_PREDICT
        integer prediction_miss;
        initial begin
            prediction_miss=0;
        end
    `endif
    //ステージ遷移
    always @(posedge clk) begin
        if(rst)begin
            pc_IF<='h8000;
            pc_ID<='h7FFC;
            pc_EX<='h7FF8;
            pc_MA<='h0000;
            pc_RW<='h0000;
        end else begin
            if(pc_EX!=0 && pc_ID!=0 && npc_EX!=pc_ID)begin
                //分岐予測失敗 = ID, EXをnopに、IFに分岐先を代入
                //IFステージ
                pc_IF<=npc_EX;
                //IDステージ
                pc_ID<=0;
                iword_ID<=0;
                //EXステージ
                pc_EX<=0;
                iword_EX<=0;
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
                `ifdef DEBUG_BRANCH_PREDICT
                    prediction_miss=prediction_miss+1;
                    $display("prediction miss %d / total clk %d",prediction_miss,hc_OUT_data);
                `endif
            end else if(is_stall_DE)begin
                //メモリ待ちストール
                //IF, IDステージは変えない
                //EXステージ: nopに
                pc_EX<=0;
                iword_EX<=0;
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
            end else if(is_multiclock_EX)begin
                //マルチクロック命令実行中
                is_multiplier_input_EX<=0;
                if(done_multiplier_EX)begin
                    //IFステージ
                    pc_IF<=npc_predict_IF;
                    //IDステージ
                    pc_ID<=pc_IF;
                    iword_ID<=iword_IF;
                    //EXステージ
                    pc_EX<=pc_ID;
                    iword_EX<=iword_ID;
                    alucode_EX<=alucode_ID;
                    imm_EX<=imm_ID;
                    if(is_oprl_fwd_EE)oprl_EX<=multi_result_EX;
                    else if(is_oprl_fwd_ME)oprl_EX<=reg_write_value_MA;
                    else oprl_EX<=oprl_ID;
                    if(is_oprr_fwd_EE)oprr_EX<=multi_result_EX;
                    else if(is_oprr_fwd_ME)oprr_EX<=reg_write_value_MA;
                    else oprr_EX<=oprr_ID;
                    if(is_reg1_fwd_EE)regdata1_EX<=multi_result_EX;
                    else if(is_reg1_fwd_ME)regdata1_EX<=reg_write_value_MA;
                    else regdata1_EX<=regdata1_ID;
                    if(is_reg2_fwd_EE)regdata2_EX<=multi_result_EX;
                    else if(is_reg2_fwd_ME)regdata2_EX<=reg_write_value_MA;
                    else regdata2_EX<=regdata2_ID;
                    dstreg_num_EX<=dstreg_num_ID;
                    reg_we_EX<=reg_we_ID;
                    is_load_EX<=is_load_ID;
                    is_store_EX<=is_store_ID;
                    is_halt_EX<=is_halt_ID;
                    ram_read_size_EX<=ram_read_size_ID;
                    ram_write_size_EX<=ram_write_size_ID;
                    ram_read_signed_EX<=ram_read_signed_ID;
                    is_multiclock_EX<=is_multiclock_ID;
                end
            end else begin
                //ストールなし・通常命令。ステージを進める
                //IFステージ
                pc_IF<=npc_predict_IF;
                //IDステージ
                pc_ID<=pc_IF;
                iword_ID<=iword_IF;
                //EXステージ
                pc_EX<=pc_ID;
                iword_EX<=iword_ID;
                alucode_EX<=alucode_ID;
                imm_EX<=imm_ID;
                if(is_oprl_fwd_EE)oprl_EX<=alu_result_EX;
                else if(is_oprl_fwd_ME)oprl_EX<=reg_write_value_MA;
                else oprl_EX<=oprl_ID;
                if(is_oprr_fwd_EE)oprr_EX<=alu_result_EX;
                else if(is_oprr_fwd_ME)oprr_EX<=reg_write_value_MA;
                else oprr_EX<=oprr_ID;
                if(is_reg1_fwd_EE)regdata1_EX<=alu_result_EX;
                else if(is_reg1_fwd_ME)regdata1_EX<=reg_write_value_MA;
                else regdata1_EX<=regdata1_ID;
                if(is_reg2_fwd_EE)regdata2_EX<=alu_result_EX;
                else if(is_reg2_fwd_ME)regdata2_EX<=reg_write_value_MA;
                else regdata2_EX<=regdata2_ID;
                dstreg_num_EX<=dstreg_num_ID;
                reg_we_EX<=reg_we_ID;
                is_load_EX<=is_load_ID;
                is_store_EX<=is_store_ID;
                is_halt_EX<=is_halt_ID;
                ram_read_size_EX<=ram_read_size_ID;
                ram_write_size_EX<=ram_write_size_ID;
                ram_read_signed_EX<=ram_read_signed_ID;
                is_multiclock_EX<=is_multiclock_ID;
                if(is_multiclock_ID)begin
                    is_multiplier_input_EX<=1;
                end else begin
                    is_multiplier_input_EX<=0;
                end
            end
            //MAステージ: 分岐の有無に無関係
            if(is_multiclock_EX)begin
                if(!done_multiplier_EX)begin
                    //計算中 = ストールさせる
                    pc_MA<=0;
                    iword_MA<=0;
                    alucode_MA<=`ALU_NOP;
                    alu_result_MA<=0;
                    dstreg_num_MA<=0;
                    reg_we_MA<=`REG_NONE;
                    is_load_MA<=`DISABLE;
                    is_store_MA<=`DISABLE;
                    is_halt_MA<=`DISABLE;
                    ram_read_size_MA<=`RAM_MODE_NONE;
                    ram_write_size_MA<=`RAM_MODE_NONE;
                    ram_read_signed_MA<=`RAM_MODE_UNSIGNED;
                    regdata2_MA<=0;
                end else begin
                    //計算終了 = 乗算器の結果を代入
                    pc_MA<=pc_EX;
                    iword_MA<=iword_EX;
                    alucode_MA<=alucode_EX;
                    alu_result_MA<=multi_result_EX;
                    dstreg_num_MA<=dstreg_num_EX;
                    reg_we_MA<=reg_we_EX;
                    is_load_MA<=is_load_EX;
                    is_store_MA<=is_store_EX;
                    is_halt_MA<=is_halt_EX;
                    ram_read_size_MA<=ram_read_size_EX;
                    ram_write_size_MA<=ram_write_size_EX;
                    ram_read_signed_MA<=ram_read_signed_EX;
                    regdata2_MA<=regdata2_EX;
                end
            end else begin
                //通常命令
                pc_MA<=pc_EX;
                iword_MA<=iword_EX;
                alucode_MA<=alucode_EX;
                alu_result_MA<=alu_result_EX;
                dstreg_num_MA<=dstreg_num_EX;
                reg_we_MA<=reg_we_EX;
                is_load_MA<=is_load_EX;
                is_store_MA<=is_store_EX;
                is_halt_MA<=is_halt_EX;
                ram_read_size_MA<=ram_read_size_EX;
                ram_write_size_MA<=ram_write_size_EX;
                ram_read_signed_MA<=ram_read_signed_EX;
                regdata2_MA<=regdata2_EX;
            end
            //RWステージ: 分岐の有無に無関係
            pc_RW<=pc_MA;
            reg_write_value_RW<=reg_write_value_MA;
            dstreg_num_RW<=dstreg_num_MA;
            reg_we_RW<=reg_we_MA;

            //for debug
            `ifdef COREMARK_TRACE
                if(pc_MA[15:0])begin
                    $write("0x%4x: 0x%8x",pc_MA[15:0],iword_MA);
                    if(reg_we_MA)begin
                        $write(" # x%02d = 0x%8x",dstreg_num_MA,reg_write_value_MA);
                    end else $write(" # (no destination)");
                    if(is_store_MA)begin
                        if(ram_write_size_MA==`RAM_MODE_BYTE)$write("; mem[0x%08x] <- 0x%02x",mem_address_MA,mem_write_value_MA[7:0]);
                        else if(ram_write_size_MA==`RAM_MODE_HALF)$write("; mem[0x%08x] <- 0x%04x",mem_address_MA,mem_write_value_MA[15:0]);
                        else if(ram_write_size_MA==`RAM_MODE_WORD)$write("; mem[0x%08x] <- 0x%08x",mem_address_MA,mem_write_value_MA);
                    end else if(is_load_MA)begin
                        if(ram_read_size_MA==`RAM_MODE_BYTE)$write(";            0x%02x <- mem[0x%08x]",mem_load_value_MA[7:0],mem_address_MA);
                        if(ram_read_size_MA==`RAM_MODE_HALF)$write(";          0x%04x <- mem[0x%08x]",mem_load_value_MA[15:0],mem_address_MA);
                        if(ram_read_size_MA==`RAM_MODE_WORD)$write(";      0x%08x <- mem[0x%08x]",mem_load_value_MA,mem_address_MA);
                    end
                    $write("\n");
                end
            `endif
        end
    end

endmodule