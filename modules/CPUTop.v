module CPUTop (
    input wire clk,
    input wire rst
);
    //プログラムカウンタ変数
    wire [31:0] pc,npc;
    PC PC1(
        .clk(clk),
        .rst(rst),
        .npc(npc),
        .pc(pc)
    );
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
    wire reg_we,is_load,is_store,is_halt;
    decoder decoder1(
        .ir(iword),
        .srcreg1_num(srcreg1_num),
        .srcreg2_num(srcreg2_num),
        .dstreg_num(dstreg_num),
        .imm(imm),
        .alucode(alucode),
        .aluop1_type(aluop1_type),
        .aluop2_type(aluop2_type),
        .reg_we(reg_we),
        .is_load(is_load),
        .is_store(is_store),
        .is_halt(is_halt)
    );
    //レジスタファイル
    wire [31:0] reg_write_value;
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
    RAM ram1(
        .clk(clk),
        .we(is_store),
        .r_addr(mem_address[16:3]),
        .r_data(mem_load_value),
        .w_addr(mem_address[16:3]),
        .w_data(mem_write_value)
    );
endmodule