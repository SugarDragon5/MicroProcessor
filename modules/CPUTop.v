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
                    ram_we<=is_store;
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
                            $write(" # x%2d = 0x%8x",dstreg_num,reg_write_value);
                        end else $write(" # (no destination)");
                        $write("\n");
                    `endif
                end
            endcase
        end
        
    end
endmodule