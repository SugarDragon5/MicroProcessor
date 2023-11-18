module multiplier (
    input wire clk,
    input wire [5:0] alucode,
    input wire [31:0] op1,
    input wire [31:0] op2,
    output reg [31:0] result,
    output reg done
);
    reg [63:0] pipereg[0:5];
    always @(negedge clk ) begin
        case(alucode)
            `ALU_MUL: pipereg[0]<=op1*op2;
            `ALU_MULH: pipereg[0]<=$signed(op1)*$signed(op2);
            `ALU_MULHSU: pipereg[0]<=$signed(op1)*op2;
            `ALU_MULHU: pipereg[0]<=op1*op2;
            `ALU_DIV: pipereg[0]<=$signed(op1)/$signed(op2);
            `ALU_DIVU: pipereg[0]<=op1/op2;
            `ALU_REM: pipereg[0]<=$signed(op1)%$signed(op2);
            `ALU_REMU: pipereg[0]<=op1%op2;
        endcase
        done<=1;
    end
    assign result=pipereg[0];
endmodule