module alu(
    input wire [5:0] alucode,       // 演算種別
    input wire [31:0] op1,          // 入力データ1
    input wire [31:0] op2,          // 入力データ2
    output wire [31:0] alu_result,   // 演算結果
    output wire br_taken             // 分岐の有無
);

    function [63:0] SRA1;
        input [31:0] a;
        input [4:0] b;

        SRA1=({{32{a[31]}},a}>>b);
    endfunction
    function [31:0] SRA2;
        input [63:0] a;
        SRA2=a[31:0];
    endfunction

    assign alu_result = alucode==`ALU_ADD ? op1+op2
        :alucode==`ALU_SUB ? op1-op2
        :alucode==`ALU_SLT ? ($signed(op1)<$signed(op2)?32'b1:32'b0)
        :alucode==`ALU_SLTU ? (op1<op2?32'b1:32'b0)
        :alucode==`ALU_XOR ? op1^op2
        :alucode==`ALU_OR ? op1|op2
        :alucode==`ALU_AND ? op1&op2
        :alucode==`ALU_SLL ? (op1<<op2[4:0])
        :alucode==`ALU_SRL ? (op1>>op2[4:0])
        :alucode==`ALU_SRA ? SRA2(SRA1(op1,op2[4:0]))
        :alucode==`ALU_JAL ? op2+4
        :alucode==`ALU_JALR ? op2+4
        :alucode==`ALU_BEQ ? 0
        :alucode==`ALU_BNE ? 0
        :alucode==`ALU_BLT ? 0
        :alucode==`ALU_BGE ? 0
        :alucode==`ALU_BGEU ? 0
        :alucode==`ALU_BLTU ? 0
        :alucode==`ALU_LB ? op1+op2
        :alucode==`ALU_LH ? op1+op2
        :alucode==`ALU_LW ? op1+op2
        :alucode==`ALU_LBU ? op1+op2
        :alucode==`ALU_LHU ? op1+op2
        :alucode==`ALU_SB ? op1+op2
        :alucode==`ALU_SH ? op1+op2
        :alucode==`ALU_SW ? op1+op2
        :alucode==`ALU_LUI ? op2
        :0;
    assign br_taken= alucode==`ALU_ADD ? `DISABLE
        :alucode==`ALU_SUB ? `DISABLE
        :alucode==`ALU_SLT ? `DISABLE
        :alucode==`ALU_SLTU ? `DISABLE
        :alucode==`ALU_XOR ? `DISABLE
        :alucode==`ALU_OR ? `DISABLE
        :alucode==`ALU_AND ? `DISABLE
        :alucode==`ALU_SLL ? `DISABLE
        :alucode==`ALU_SRL ? `DISABLE
        :alucode==`ALU_SRA ? `DISABLE
        :alucode==`ALU_JAL ? `ENABLE
        :alucode==`ALU_JALR ? `ENABLE
        :alucode==`ALU_BEQ ? (op1==op2)
        :alucode==`ALU_BNE ? (op1!=op2)
        :alucode==`ALU_BLT ? ($signed(op1)<$signed(op2))
        :alucode==`ALU_BLTU ? (op1<op2)
        :alucode==`ALU_BGE ? ($signed(op1)>=$signed(op2))
        :alucode==`ALU_BGEU ? (op1>=op2)
        :alucode==`ALU_LB ? `DISABLE
        :alucode==`ALU_LH ? `DISABLE
        :alucode==`ALU_LW ? `DISABLE
        :alucode==`ALU_LBU ? `DISABLE
        :alucode==`ALU_LHU ? `DISABLE
        :alucode==`ALU_SB ? `DISABLE
        :alucode==`ALU_SH ? `DISABLE
        :alucode==`ALU_SW ? `DISABLE
        :alucode==`ALU_LUI ? `DISABLE:0;

endmodule