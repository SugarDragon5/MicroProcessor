module NPCGenerator (
    input wire [31:0] pc,  //現在のプログラムカウンタ
    input wire [5:0] alucode,  //ALUコード
    input wire [31:0] imm,  //即値
    input wire [31:0] reg1dat,  //レジスタ1のデータ
    input wire br_taken,  //分岐の有無
    output wire [31:0] npc  //次クロックのプログラムカウンタ
);

    function [31:0] NPC;
        input [31:0] pc;
        input [5:0] alucode;
        input [31:0] imm;
        input [31:0] reg1dat;
        input br_taken;
        if(alucode==`ALU_JALR)begin
            NPC=reg1dat+imm;
        end else if(br_taken)begin
            NPC=pc+imm;
        end else begin
            NPC=pc+4;
        end
    endfunction
    assign npc=NPC(pc,alucode,imm,reg1dat,br_taken);
endmodule