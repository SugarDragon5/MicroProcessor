module NPCGenerator (
    input wire [31:0] pc,  //現在のプログラムカウンタ
    input wire [5:0] alucode,  //ALUコード
    input wire [31:0] npc_default,  //分岐がない場合の次クロックのプログラムカウンタ
    input wire [31:0] npc_branch,  //分岐がある場合の次クロックのプログラムカウンタ
    input wire [31:0] npc_jalr,  //JALRの場合の次クロックのプログラムカウンタ
    input wire br_taken,  //分岐の有無
    output wire [31:0] npc  //次クロックのプログラムカウンタ
);

    function [31:0] NPC;
        input [31:0] pc;
        input [5:0] alucode;
        input [31:0] npc_default_in;
        input [31:0] npc_branch_in;
        input [31:0] npc_jalr_in;
        input br_taken;
        if(alucode==`ALU_JALR)begin
            NPC=npc_jalr_in;
        end else if(br_taken)begin
            NPC=npc_branch_in;
        end else begin
            NPC=npc_default_in;
        end
    endfunction
    assign npc=NPC(pc,alucode,npc_default,npc_branch,npc_jalr,br_taken);
endmodule