module alu(
    input wire [5:0] alucode,       // 演算種別
    input wire [31:0] op1,          // 入力データ1
    input wire [31:0] op2,          // 入力データ2
    output reg [31:0] alu_result,   // 演算結果
    output reg br_taken             // 分岐の有無
);

    assign alu_result=alucode==`ALU_ADD?op1+op2:0;
    assign br_taken=alucode==`ALU_ADD?0:0;
endmodule