module RegisterFile (
    input wire clk,
    input wire [4:0] srcreg1_num,  // ソースレジスタ1番号
    input wire [4:0] srcreg2_num,  // ソースレジスタ2番号
    input wire [4:0] dstreg_num,  // デスティネーションレジスタ番号
    input wire [31:0] write_value,  // 書き込みデータ
    input wire reg_we,
    output reg [31:0] regdata1,
    output reg [31:0] regdata2
);
    reg [31:0] regfile[31:0];
    integer i;
    initial begin
        for(i=0;i<32;i++)begin
            regfile[i]=0;
        end
    end
    always @(posedge clk) begin
        if(reg_we&&dstreg_num) begin
            //ゼロレジスタ以外への書き込み
            regfile[dstreg_num] <= write_value;
        end
    end
    assign regdata1 = regfile[srcreg1_num];
    assign regdata2 = regfile[srcreg2_num];
    
endmodule