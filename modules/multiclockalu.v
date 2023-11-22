module multiclockalu (
    input wire clk,
    input wire rst,
    input wire [5:0] alucode,
    input wire [31:0] op1,
    input wire [31:0] op2,
    output reg [31:0] result,
    output reg done
);
    reg [5:0] stage;
    reg [5:0] alucode_reg;
    reg [63:0] op1_reg;
    reg [63:0] op2_reg;
    reg [63:0] calc_result;
    reg [63:0] mulreg[0:7];
    reg [1:0] taken_sign;    //符号を取り出したか
    always @(negedge clk) begin
        if(rst)begin
            //例外処理
            if((alucode==`ALU_DIV || alucode==`ALU_DIVU || alucode==`ALU_REM || alucode==`ALU_REMU) && op2==0)begin
                //ゼロ除算
                case(alucode)
                    `ALU_DIV,`ALU_DIVU:result<=32'hffffffff;
                    `ALU_REM,`ALU_REMU:result<=op1;
                endcase
                done<=1;
                done<=1;
                stage<=-1;
            end else if((alucode==`ALU_DIV || alucode==`ALU_REM) && op1==32'h80000000 && op2==32'hffffffff)begin
                //オーバーフロー
                if(alucode==`ALU_DIV)
                    result<=32'h80000000;
                else
                    result<=32'h00000000;
                done<=1;
                stage<=-1;
            end else begin
                //正常処理
                stage<=0;
                alucode_reg<=alucode;
                calc_result<=0;
                for(i=0;i<8;i++)begin
                    mulreg[i]<=0;
                end
                done<=0;
                if((alucode==`ALU_MUL || alucode==`ALU_MULH||alucode==`ALU_MULHSU || alucode==`ALU_DIV || alucode==`ALU_REM) && op1[31])begin
                    //op1を負→正にする必要あり
                    op1_reg<={32'b0,-op1};
                    taken_sign[0]<=1;
                end else begin
                    op1_reg<=op1;
                    taken_sign[0]<=0;
                end
                if((alucode==`ALU_MUL || alucode==`ALU_MULH || alucode==`ALU_DIV || alucode==`ALU_REM) && op2[31])begin
                    //op2を負→正にする必要あり
                    op2_reg<={32'b0,-op2};
                    taken_sign[1]<=1;
                end else begin
                    op2_reg<=op2;
                    taken_sign[1]<=0;
                end
            end
        end else if(stage<32)begin
            if(alucode==`ALU_MUL || alucode==`ALU_MULH || alucode==`ALU_MULHSU || alucode==`ALU_MULHU)begin
                if(stage<4)begin
                    for(i=0;i<8;i++)begin
                        if(op2_reg[stage*8+i])begin
                            mulreg[i]<=mulreg[i]+(op1_reg<<(stage*8+i));
                        end
                    end
                    stage<=stage+1;
                end else if(stage==4)begin
                    mulreg[0]<=mulreg[0]+mulreg[4];
                    mulreg[1]<=mulreg[1]+mulreg[5];
                    mulreg[2]<=mulreg[2]+mulreg[6];
                    mulreg[3]<=mulreg[3]+mulreg[7];
                    stage<=5;
                end else if(stage==5)begin
                    mulreg[0]<=mulreg[0]+mulreg[2];
                    mulreg[1]<=mulreg[1]+mulreg[3];
                    stage<=6;
                end else if(stage==6)begin
                    calc_result<=mulreg[0]+mulreg[1];
                    stage<=32;
                end
            end else if(alucode==`ALU_DIV || alucode==`ALU_DIVU || alucode==`ALU_REM || alucode==`ALU_REMU)begin
                    if((op2_reg<<(31-stage))<=op1_reg)begin
                        calc_result[31-stage]<=1;
                        op1_reg<=op1_reg-(op2_reg<<(31-stage));
                    end
                stage<=stage+1;
            end
        end else if(stage==32)begin
            if(alucode==`ALU_REM)begin
                //余りの符号を調整
                if(taken_sign[0])begin
                    op1_reg<=-op1_reg;
                end
            end else begin
                //積・商の符号を調整
                if(taken_sign[0]^taken_sign[1])begin
                    calc_result<=-calc_result;
                end
            end
            stage<=stage+1;
        end else if(stage==33)begin
            if(alucode==`ALU_MUL)begin
                result<=calc_result[31:0];
            end else if(alucode==`ALU_MULH || alucode==`ALU_MULHSU || alucode==`ALU_MULHU)begin
                result<=calc_result[63:32];
            end else if(alucode==`ALU_DIV || alucode==`ALU_DIVU)begin
                result<=calc_result[31:0];
            end else if(alucode==`ALU_REM || alucode==`ALU_REMU)begin
                result<=op1_reg;
            end
            done<=1;
            stage<=-1;
        end else begin
            //Nothing to do
        end
    end
endmodule