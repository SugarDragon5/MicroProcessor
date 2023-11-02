//
// npc test bench
//

`define assert(name, signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %s : signal is '0x%x' but expected '0x%x'!", name, signal, value); \
            $finish; \
        end else begin \
            $display("    signal == value"); \
        end

`define test(name, ex_npc) \
        $display("%s:", name); \
        $display("    alucode: 0x%x, imm: 0x%x, reg1: 0x%x, br_taken: %b", alucode, imm, reg1dat,br_taken); \
        `assert("npc", npc, ex_npc) \
        $display("%s test passed\n", name); \

module npc_tb;
    reg [31:0] pc;
    reg [5:0] alucode;
    reg [31:0] imm;
    reg [31:0] reg1dat;
    reg br_taken;
    wire [31:0] npc;

    NPCGenerator npcgen(
        .pc(pc),
        .alucode(alucode),
        .imm(imm),
        .reg1dat(reg1dat),
        .br_taken(br_taken),
        .npc(npc)
    );

    initial begin
        //normal operation
        pc=32'd0;
        alucode=`ALU_ADD;
        imm=32'd0;
        reg1dat=32'd0;
        br_taken=`DISABLE;
        #10;
        `test("ALU_ADD", pc+4)

        //branch operation
        pc=32'd0;
        alucode=`ALU_BEQ;
        imm=32'd314;
        reg1dat=32'd0;
        br_taken=`ENABLE;
        #10;
        `test("ALU_BEQ_ENABLE", pc+imm)

        pc=32'd0;
        alucode=`ALU_BEQ;
        imm=32'd0;
        reg1dat=32'd0;
        br_taken=`DISABLE;
        #10;
        `test("ALU_BEQ_DISABLE", pc+4)

        //jump operation
        pc=32'd0;
        alucode=`ALU_JAL;
        imm=32'd1592;
        reg1dat=32'd0;
        br_taken=`ENABLE;
        #10;
        `test("ALU_JAL", imm)

        pc=32'd0;
        alucode=`ALU_JALR;
        imm=32'd6535;
        reg1dat=32'd8979;
        br_taken=`ENABLE;
        #10;
        `test("ALU_JALR", reg1dat+imm)
    end

endmodule