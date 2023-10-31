module decoder(
    input  wire [31:0]  ir,           // 機械語命令列
    output wire  [4:0]	srcreg1_num,  // ソースレジスタ1番号
    output wire  [4:0]	srcreg2_num,  // ソースレジスタ2番号
    output wire  [4:0]	dstreg_num,   // デスティネーションレジスタ番号
    output wire [31:0]	imm,          // 即値
    output reg   [5:0]	alucode,      // ALUの演算種別
    output reg   [1:0]	aluop1_type,  // ALUの入力タイプ
    output reg   [1:0]	aluop2_type,  // ALUの入力タイプ
    output reg	     	reg_we,       // レジスタ書き込みの有無
    output reg		is_load,      // ロード命令判定フラグ
    output reg		is_store,     // ストア命令判定フラグ
    output reg          is_halt
);


endmodule