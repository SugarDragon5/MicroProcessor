module multiclockalu (
    input wire clk,
    input wire is_multiclock_input,
    input wire [5:0] alucode,
    input wire [31:0] op1,
    input wire [31:0] op2,
    output wire [31:0] result,
    output wire done
);
    integer i;
    reg [63:0] pipereg[0:5];
    reg [5:0] is_working;
    always @(negedge clk ) begin
        if(is_multiclock_input)begin
            is_working[0]<=1;
            case(alucode)
                `ALU_MUL: pipereg[0]<=op1*op2;
                `ALU_MULH: pipereg[0]<=$signed(op1)*$signed(op2);
                `ALU_MULHSU: pipereg[0]<=$signed(op1)*$signed(op2);
                `ALU_MULHU: pipereg[0]<=op1*op2;
                `ALU_DIV: pipereg[0]<=$signed(op1)/$signed(op2);
                `ALU_DIVU: pipereg[0]<=op1/op2;
                `ALU_REM: pipereg[0]<=$signed(op1)%$signed(op2);
                `ALU_REMU: pipereg[0]<=op1%op2;
                default: pipereg[0]<=0;
            endcase
        end else begin
            is_working[0]<=0;
        end
        for(i=0;i<5;i++)begin
            is_working[i+1]<=is_working[i];
            pipereg[i+1]<=pipereg[i];
        end
    end

    function [31:0] get_result;
        input [63:0] result;
        input [5:0] alucode;
        begin
            case(alucode)
                `ALU_MUL: get_result=result[31:0];
                `ALU_MULH: get_result=result[63:32];
                `ALU_MULHSU: get_result=result[63:32];
                `ALU_MULHU: get_result=result[63:32];
                `ALU_DIV: get_result=result[31:0];
                `ALU_DIVU: get_result=result[31:0];
                `ALU_REM: get_result=result[31:0];
                `ALU_REMU: get_result=result[31:0];
                default: get_result=0;
            endcase
        end
    endfunction

    assign result=get_result(pipereg[5],alucode);
    assign done=is_working[5];
endmodule