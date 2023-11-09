module OperandSwitcher (
    input [1:0]	aluop1_type,  // ALUの入力タイプ
    input [1:0]	aluop2_type,  // ALUの入力タイプ
    input [31:0] pc,
    input [31:0] regdata1,
    input [31:0] regdata2,
    input [31:0] imm,
    output [31:0] oprl,
    output [31:0] oprr
);
    function [31:0] OPR;
        input [1:0] aluop_type;
        input [31:0] pc;
        input [31:0] regdata;
        input [31:0] imm;
        case(aluop_type)
            `OP_TYPE_NONE:OPR=0;
            `OP_TYPE_REG:OPR=regdata;
            `OP_TYPE_IMM:OPR=imm;
            `OP_TYPE_PC:OPR=pc;
        endcase
    endfunction
    assign oprl=OPR(aluop1_type,pc,regdata1,imm);
    assign oprr=OPR(aluop2_type,pc,regdata2,imm);
endmodule