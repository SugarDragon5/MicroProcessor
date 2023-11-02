module PC (
    clk,npc,pc
);
    input wire clk;
    input wire [31:0] npc;
    output reg [31:0] pc;
    always @(posedge clk) begin
        pc <= npc;
    end
endmodule

module NPCGenerator (
    pc,alucode,imm,reg1dat,result,npc
);
    input wire [31:0] pc;
    input wire [5:0] alucode;
    input wire [31:0] imm;
    input wire [31:0] reg1dat;
    input wire [31:0] br_taken;
    output reg [31:0] npc;
    
    function [31:0] NPC;
        input [31:0] pc;
        input [5:0] alucode;
        input [31:0] imm;
        input [31:0] reg1dat;
        input [31:0] br_taken;
        if(alucode==`ALU_JALR)begin
            NPC=reg1dat+imm;
        end else if(br_taken)begin
            NPC=pc+imm;
        end else begin
            NPC=pc+4;
        end
    endfunction
    assign npc=NPC(pc,imm,reg1dat,result);
endmodule