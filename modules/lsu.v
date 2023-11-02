module LoadStoreUnit (
    input wire [31:0] alu_result,   // ALUの演算結果
    input wire [31:0] regdata2,     // レジスタデータ2
    input wire is_load,             // ロード命令の有無
    input wire is_store,            // ストア命令の有無
    input wire [31:0] mem_load_value,   // メモリからロードした値
    output reg [31:0] reg_write_value,  // レジスタに書き込む値
    output reg [31:0] mem_address,  // 書き込むメモリアドレス
    output reg [31:0] mem_write_value,  // メモリに書き込む値
);
    assign reg_write_value=is_load?load_value:alu_result;
    assign mem_address=alu_result;  //要確認
    assign mem_write_value=regdata2;   //要確認
endmodule