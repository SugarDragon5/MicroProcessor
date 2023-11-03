module PC (
    clk,rst,npc,pc
);
    input wire clk,rst;
    input wire [31:0] npc;  //次クロックのプログラムカウンタ
    output reg [31:0] pc;   //現在のプログラムカウンタ
    always @(posedge clk) begin
        if(rst)begin
            pc<='h8000;
        end else begin
            pc<=npc;
        end
    end
endmodule

module NPCGenerator (
    pc,         //現在のプログラムカウンタ
    alucode,    //ALUコード
    imm,        //即値
    reg1dat,    //レジスタ1のデータ
    br_taken,   //分岐の有無
    npc         //次クロックのプログラムカウンタ
);
    input wire [31:0] pc;
    input wire [5:0] alucode;
    input wire [31:0] imm;
    input wire [31:0] reg1dat;
    input wire br_taken;
    output wire [31:0] npc;
    
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