module decoder(
    input  wire [31:0]  ir,           // 機械語命令列
    output wire   [4:0]	srcreg1_num,  // ソースレジスタ1番号
    output wire   [4:0]	srcreg2_num,  // ソースレジスタ2番号
    output wire   [4:0]	dstreg_num,   // デスティネーションレジスタ番号
    output wire  [31:0]	imm,          // 即値
    output wire    [5:0]	alucode,      // ALUの演算種別
    output wire    [1:0]	aluop1_type,  // ALUの入力タイプ
    output wire    [1:0]	aluop2_type,  // ALUの入力タイプ
    output wire 	     	reg_we,       // レジスタ書き込みの有無
    output wire 		is_load,      // ロード命令判定フラグ
    output wire 		is_store,     // ストア命令判定フラグ
    output wire           is_halt,
    output wire [1:0]    ram_read_size,
    output wire [1:0]    ram_write_size,
    output wire          ram_read_signed
);

//ソースレジスタ1
    function [4:0] decode_srcreg1_num;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `LUI: decode_srcreg1_num = 5'd0;
                `AUIPC: decode_srcreg1_num = 5'd0;
                `JAL: decode_srcreg1_num = 5'd0;
                default: decode_srcreg1_num = ir[19:15];
            endcase
        end
    endfunction

//ソースレジスタ2
    function [4:0] decode_srcreg2_num;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `OP: decode_srcreg2_num = ir[24:20];
                `BRANCH: decode_srcreg2_num = ir[24:20];
                `STORE: decode_srcreg2_num = ir[24:20];
                default: decode_srcreg2_num = 5'd0;
            endcase
        end
    endfunction

//デスティネーションレジスタ
    function [4:0] decode_dstreg_num;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `BRANCH: decode_dstreg_num = 5'd0;
                `STORE: decode_dstreg_num = 5'd0;
                default: decode_dstreg_num = ir[11:7];
            endcase
        end
    endfunction

//即値
    function [31:0] decode_imm;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `LUI: decode_imm = {ir[31:12], 12'd0};
                `AUIPC: decode_imm = {ir[31:12], 12'd0};
                `JAL: decode_imm = {{11{ir[31]}},ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
                `JALR: decode_imm = {{20{ir[31]}},ir[31:20]};
                `BRANCH: decode_imm = {{19{ir[31]}},ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
                `LOAD: decode_imm = {{20{ir[31]}},ir[31:20]};
                `STORE: decode_imm = {{20{ir[31]}},ir[31:25], ir[11:7]};
                `OPIMM: begin
                    case(ir[14:12])
                        3'b001: decode_imm = ir[24:20];//SLLI
                        3'b101: decode_imm = ir[24:20];//SRLI, SRAI
                        default: decode_imm = {{20{ir[31]}},ir[31:20]};//Others
                    endcase
                end
                default: decode_imm = 32'd0;
            endcase
        end
    endfunction

//ALUの演算種別
    function [5:0] decode_alucode;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `LUI: decode_alucode = `ALU_LUI;
                `AUIPC: decode_alucode = `ALU_ADD;
                `JAL: decode_alucode = `ALU_JAL;
                `JALR: decode_alucode = `ALU_JALR;
                `BRANCH: begin
                    case (ir[14:12])
                        3'b000: decode_alucode = `ALU_BEQ;
                        3'b001: decode_alucode = `ALU_BNE;
                        3'b100: decode_alucode = `ALU_BLT;
                        3'b101: decode_alucode = `ALU_BGE;
                        3'b110: decode_alucode = `ALU_BLTU;
                        3'b111: decode_alucode = `ALU_BGEU;
                        default: decode_alucode = `ALU_NOP;
                    endcase
                end
                `LOAD: begin
                    case (ir[14:12])
                        3'b000: decode_alucode = `ALU_LB;
                        3'b001: decode_alucode = `ALU_LH;
                        3'b010: decode_alucode = `ALU_LW;
                        3'b100: decode_alucode = `ALU_LBU;
                        3'b101: decode_alucode = `ALU_LHU;
                        default: decode_alucode = `ALU_NOP;
                    endcase
                end
                `STORE: begin
                    case (ir[13:12])
                        2'b00: decode_alucode = `ALU_SB;
                        2'b01: decode_alucode = `ALU_SH;
                        2'b10: decode_alucode = `ALU_SW;
                        default: decode_alucode = `ALU_NOP;
                    endcase
                end
                `OPIMM: begin
                    case (ir[14:12])
                        3'b000: decode_alucode = `ALU_ADD;
                        3'b010: decode_alucode = `ALU_SLT;
                        3'b011: decode_alucode = `ALU_SLTU;
                        3'b100: decode_alucode = `ALU_XOR;
                        3'b110: decode_alucode = `ALU_OR;
                        3'b111: decode_alucode = `ALU_AND;
                        3'b001: decode_alucode = `ALU_SLL;
                        3'b101: begin
                            case (ir[31:25])
                                7'b0000000: decode_alucode = `ALU_SRL;
                                7'b0100000: decode_alucode = `ALU_SRA;
                                default: decode_alucode = `ALU_NOP;
                            endcase
                        end
                        default: decode_alucode = `ALU_NOP;
                    endcase
                end
                `OP: begin
                    case (ir[14:12])
                        3'b000: begin
                            case (ir[31:25])
                                7'b0000000: decode_alucode = `ALU_ADD;
                                7'b0100000: decode_alucode = `ALU_SUB;
                                default: decode_alucode = `ALU_NOP;
                            endcase
                        end
                        3'b001: decode_alucode = `ALU_SLL;
                        3'b010: decode_alucode = `ALU_SLT;
                        3'b011: decode_alucode = `ALU_SLTU;
                        3'b100: decode_alucode = `ALU_XOR;
                        3'b101: begin
                            case (ir[31:25])
                                7'b0000000: decode_alucode = `ALU_SRL;
                                7'b0100000: decode_alucode = `ALU_SRA;
                                default: decode_alucode = `ALU_NOP;
                            endcase
                        end
                        3'b110: decode_alucode = `ALU_OR;
                        3'b111: decode_alucode = `ALU_AND;
                        default: decode_alucode = `ALU_NOP;
                    endcase
                end
                default: decode_alucode = `ALU_NOP;
            endcase
        end
    endfunction

//ALUの入力タイプ1
    function [1:0] decode_aluop1_type;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `LUI: decode_aluop1_type = `OP_TYPE_NONE;
                `AUIPC: decode_aluop1_type = `OP_TYPE_IMM;
                `JAL: decode_aluop1_type = `OP_TYPE_NONE;
                `JALR: decode_aluop1_type = `OP_TYPE_REG;
                `BRANCH: decode_aluop1_type = `OP_TYPE_REG;
                `LOAD: decode_aluop1_type = `OP_TYPE_REG;
                `STORE: decode_aluop1_type = `OP_TYPE_REG;
                `OPIMM: decode_aluop1_type = `OP_TYPE_REG;
                `OP: decode_aluop1_type = `OP_TYPE_REG;
                default: decode_aluop1_type = `OP_TYPE_NONE;
            endcase
        end
    endfunction

//ALUの入力タイプ2
    function [1:0] decode_aluop2_type;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `LUI: decode_aluop2_type = `OP_TYPE_IMM;
                `AUIPC: decode_aluop2_type = `OP_TYPE_PC;
                `JAL: decode_aluop2_type = `OP_TYPE_PC;
                `JALR: decode_aluop2_type = `OP_TYPE_PC;
                `BRANCH: decode_aluop2_type = `OP_TYPE_REG;
                `LOAD: decode_aluop2_type = `OP_TYPE_IMM;
                `STORE: decode_aluop2_type = `OP_TYPE_IMM;
                `OPIMM: decode_aluop2_type = `OP_TYPE_IMM;
                `OP: decode_aluop2_type = `OP_TYPE_REG;
                default: decode_aluop2_type = `OP_TYPE_NONE;
            endcase
        end
    endfunction

//レジスタ書き込みの有無
    function decode_reg_we;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `LUI: decode_reg_we = 1'b1;
                `AUIPC: decode_reg_we = 1'b1;
                `JAL: begin
                    case(ir[11:7])
                        5'b00000: decode_reg_we = 1'b0;
                        default: decode_reg_we = 1'b1;
                    endcase
                end
                `JALR: begin
                    case(ir[11:7])
                        5'b00000: decode_reg_we = 1'b0;
                        default: decode_reg_we = 1'b1;
                    endcase
                end
                `BRANCH: decode_reg_we = 1'b0;
                `LOAD: decode_reg_we = 1'b1;
                `STORE: decode_reg_we = 1'b0;
                `OPIMM: decode_reg_we = 1'b1;
                `OP: decode_reg_we = 1'b1;
                default: decode_reg_we = 1'b0;
            endcase
        end
    endfunction

//ロード命令判定フラグ
    function decode_is_load;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `LOAD: decode_is_load = 1'b1;
                default: decode_is_load = 1'b0;
            endcase
        end
    endfunction

//ストア命令判定フラグ
    function decode_is_store;
        input [31:0] ir;
        begin
            case (ir[6:0])
                `STORE: decode_is_store = 1'b1;
                default: decode_is_store = 1'b0;
            endcase
        end
    endfunction

//RAM読み書き幅指定
    function [1:0] calc_ram_read_size;
        input [5:0] alu_code;
        begin
            case (alu_code)
                `ALU_LB: calc_ram_read_size = `RAM_MODE_BYTE;
                `ALU_LH: calc_ram_read_size = `RAM_MODE_HALF;
                `ALU_LW: calc_ram_read_size = `RAM_MODE_WORD;
                `ALU_LBU: calc_ram_read_size = `RAM_MODE_BYTE;
                `ALU_LHU: calc_ram_read_size = `RAM_MODE_HALF;
                default: calc_ram_read_size = `RAM_MODE_NONE;
            endcase
        end
    endfunction

    function calc_ram_read_signed;
        input [5:0] alu_code;
        begin
            case (alu_code)
                `ALU_LB: calc_ram_read_signed = 1'b1;
                `ALU_LH: calc_ram_read_signed = 1'b1;
                `ALU_LW: calc_ram_read_signed = 1'b1;
                `ALU_LBU: calc_ram_read_signed = 1'b0;
                `ALU_LHU: calc_ram_read_signed = 1'b0;
                default: calc_ram_read_signed = 1'b0;
            endcase
        end
    endfunction

    function [1:0] calc_ram_write_size;
        input [5:0] alu_code;
        begin
            case (alu_code)
                `ALU_SB: calc_ram_write_size = `RAM_MODE_BYTE;
                `ALU_SH: calc_ram_write_size = `RAM_MODE_HALF;
                `ALU_SW: calc_ram_write_size = `RAM_MODE_WORD;
                default: calc_ram_write_size = `RAM_MODE_NONE;
            endcase
        end
    endfunction



    assign srcreg1_num = decode_srcreg1_num(ir);
    assign srcreg2_num = decode_srcreg2_num(ir);
    assign dstreg_num = decode_dstreg_num(ir);
    assign imm = decode_imm(ir);
    assign alucode = decode_alucode(ir);
    assign aluop1_type = decode_aluop1_type(ir);
    assign aluop2_type = decode_aluop2_type(ir);
    assign reg_we = decode_reg_we(ir);
    assign is_load = decode_is_load(ir);
    assign is_store = decode_is_store(ir);
    assign ram_read_size = calc_ram_read_size(alucode);
    assign ram_read_signed = calc_ram_read_signed(alucode);
    assign ram_write_size = calc_ram_write_size(alucode);

endmodule