module RegisterFile (
    input wire clk,
    input wire [4:0] srcreg1_num,  // ソースレジスタ1番号
    input wire [4:0] srcreg2_num,  // ソースレジスタ2番号
    input wire [4:0] destreg_num,  // デスティネーションレジスタ番号
    input wire [31:0] write_value;  // 書き込みデータ
    input wire reg_we;
    output reg [31:0] regdata1,
    output reg [31:0] regdata2,
);
    reg [31:0] regfile [31:0];
    always @(posedge clk) begin
        if(reg_we) begin
            regfile[destreg_num] <= write_value;
        end
    end
    assign regdata1 = regfile[srcreg1_num];
    assign regdata2 = regfile[srcreg2_num];
    
endmodule