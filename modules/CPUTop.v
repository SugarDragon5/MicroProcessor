module CPUTop (
    input wire clk,
    input wire rst
);
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
    wire [4:0] srcreg1_num,srcreg2_num,dstreg_num;
    wire [1:0] aluop1_type,aluop2_type;
    wire reg_we_state,is_load,is_store,is_halt;
    decoder decoder1(
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
        .is_halt(is_halt)
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
    wire [31:0] alu_result;
    alu alu1(
        .alucode(alucode),
        .op1(oprl),
        .op2(oprr),
        .alu_result(alu_result),
        .br_taken(br_taken)
    );
    //LSU
    wire [31:0] mem_load_value;
    wire [31:0] mem_address,mem_write_value;
    LoadStoreUnit LSU1(
        .alu_result(alu_result),
        .regdata2(regdata2),
        .is_load(is_load),
        .is_store(is_store),
        .mem_load_value(mem_load_value),
        .reg_write_value(reg_write_value),
        .mem_address(mem_address),
        .mem_write_value(mem_write_value)
    );
    //RAM
    reg we;
    RAM ram1(
        .clk(clk),
        .we(we),
        .r_addr(mem_address[16:3]),
        .r_data(mem_load_value),
        .w_addr(mem_address[16:3]),
        .w_data(mem_write_value)
    );

    always @(posedge clk) begin
        if(rst)begin
            stage<=`IF_STAGE;
            pc<='h7FFC;
        end else begin
            case(stage)
                //命令フェッチクロック
                `IF_STAGE:begin
                    //PCの更新→デコーダが走る
                    stage <= `RR_STAGE;
                    pc <= npc;
                end
                //レジスタ・データ準備クロック
                `RR_STAGE:begin
                    //デコーダが計算した値をもとに、レジスタからデータを読み出す
                    stage <= `EX_STAGE;
                end
                //演算クロック
                `EX_STAGE:begin
                    //デコーダ・レジスタの値をもとに、ALUが演算を行う
                    stage <= `MA_STAGE;
                end
                //RAM書き込みクロック
                `MA_STAGE:begin
                    stage <= `RW_STAGE;
                    //次クロックにレジスタ書き込みを行うかを書き込む
                    reg_we<=reg_we_state;
                end
                //レジスタ書き込みクロック
                `RW_STAGE:begin
                    stage <= `IF_STAGE;
                    reg_we<=0;
                end
            endcase
        end
        
    end
endmodule