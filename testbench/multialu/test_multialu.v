`default_nettype none

`define assert(name, signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %s : signal is '0x%x' but expected '0x%x'!", name, signal, value); \
            $finish; \
        end else begin \
            $display("    signal == value"); \
        end

`define test(name, ex_result) \
        $display("%s:", name); \
        $display("    code: 0x%x, op1: 0x%x, op2: 0x%x", alucode, op1, op2); \
        `assert("result", result, ex_result) \
        $display("%s test passed\n", name); \

module tb_multiclockalu;
reg clk;

reg rst;
reg [5:0] alucode;
reg [31:0] op1;
reg [31:0] op2;
wire [31:0] result;
wire done;
reg [31:0] ans;

multiclockalu multiclockalu1(
    .clk(clk),
    .rst(rst),
    .alucode(alucode),
    .op1(op1),
    .op2(op2),
    .result(result),
    .done(done)
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

integer i;
initial begin
    $dumpfile("tb_multiclockalu.vcd");
    $dumpvars(0, tb_multiclockalu);
end

initial begin
    clk<=1'b0;
    //MUL Test1
    alucode<=`ALU_MUL;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MUL Test1 [small case]", 32'h1126e8a6);

    //MUL Test2
    alucode<=`ALU_MUL;
    op1<=32'h27182818;
    op2<=32'h45904523;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MUL Test2 [large case]", 32'he09bf348);
    

    //MUL Test4
    //a: 12345678, b: -9876543
    //dec: -121932619631154
    //hex: 0xffff911a598535ce ->ans: 0x598535ce
    //bin: 1111111111111111100100010001101001011001100001010011010111001110

    alucode<=`ALU_MUL;
    op1<=12345678;
    op2<=-9876543;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MUL Test3 [pos * neg (large)]", 32'h598535ce);

    //MULH Test1
    alucode<=`ALU_MULH;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULH Test1 [small case]", 32'h00000000);
    
    //MULH Test2
    alucode<=`ALU_MULH;
    op1<=32'h27182818;  //d655894552 <2147483647 -> positive
    op2<=32'h45904523;  //d1167082787 <2147483647 -> positive
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULH Test2 [pos * pos]", 32'h0a9f8af3);

    //MULH Test3
    alucode<=`ALU_MULH;
    op1<=-4;
    op2<=7;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULH Test3 [neg * pos (small)]", 32'hffffffff);

    //MULH Test4
    //a: 12345678, b: -9876543
    //dec: -121932619631154
    //hex: 0xffff911a598535ce
    //bin: 1111111111111111100100010001101001011001100001010011010111001110

    alucode<=`ALU_MULH;
    op1<=12345678;
    op2<=-9876543;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULH Test4 [pos * neg (large)]", 32'hffff911a);

    //MULHSU Test1
    alucode<=`ALU_MULHSU;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULHSU Test1 [small case]", 32'h00000000);

    //MULHSU Test2
    //dec: 53024283244601010
    //hex: 0x00bc614dff439eb2
    //bin: 0000000010111100011000010100110111111111010000111001111010110010
    alucode<=`ALU_MULHSU;
    op1<=12345678;
    op2<=4294967295;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULHSU Test2 [pos * pos (large)]", 32'h00bc614d);

    //MULHSU Test2
    //a: 4294967295(->-1), b: 12345678
    //dec: -12345678
    //hex: 0xffffffffff439eb2
    //bin: 1111111111111111111111111111111111111111010000111001111010110010
    alucode<=`ALU_MULHSU;
    op1<=-1;
    op2<=1234578;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULHSU Test2 [neg * pos (large)]", 32'hffffffff);

    //MULHU Test1
    alucode<=`ALU_MULHU;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULHU Test1 [small case]", 32'h00000000);

    //MULHU Test2
    //dec: 53024283244601010
    //hex: 0x00bc614dff439eb2
    //bin: 0000000010111100011000010100110111111111010000111001111010110010
    alucode<=`ALU_MULHU;
    op1<=12345678;
    op2<=4294967295;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("MULHU Test2 [pos * pos (large)]", 32'h00bc614d);
    
    
    //DIV Test1
    alucode<=`ALU_DIV;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("DIV Test1 [small case]", 32'h00000000);

    //DIV Test2
    alucode<=`ALU_DIV;
    op1<=32'h27182818;
    op2<=32'h00001234;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("DIV Test2 [large case]", 32'h000225cd);
    
    //DIV Test3
    alucode<=`ALU_DIV;
    op1<=-20;
    op2<=7;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("DIV Test3 [neg / pos (small)]", -2);

    //DIV Test4
    alucode<=`ALU_DIV;
    op1<=10;
    op2<=0;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("DIV Test4 [div by zero]", -1);

    //DIVU Test1
    alucode<=`ALU_DIVU;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("DIVU Test1 [small case]", 32'h00000000);

    //DIVU Test2
    alucode<=`ALU_DIVU;
    op1<=4294967295;
    op2<=1234;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("DIVU Test2 [large case]", 32'h000351bcc);

    //REM Test1
    alucode<=`ALU_REM;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("REM Test1 [small case]", 32'h00003141);

    //REM Test2
    alucode<=`ALU_REM;
    op1<=32'h27182818;
    op2<=32'h00001234;
    rst<=1'b1;
    #10;rst<=1'b0;
    ans<=$signed(op1)%$signed(op2);
    #500;`test("REM Test2 [large case]", ans);

    //REM Test3
    alucode<=`ALU_REM;
    op1<=-20;
    op2<=7;
    rst<=1'b1;
    #10;rst<=1'b0;
    ans<=$signed(op1)%$signed(op2);
    #500;`test("REM Test3 [neg / pos (small)]", ans);

    //REM Test4
    alucode<=`ALU_REM;
    op1<=-32;
    op2<=-7;
    rst<=1'b1;
    #10;rst<=1'b0;
    ans<=$signed(op1)%$signed(op2);
    #500;`test("REM Test4 [neg / neg (small)]", ans);

    //REM Test5
    alucode<=`ALU_REM;
    op1<=10;
    op2<=0;
    rst<=1'b1;
    #10;rst<=1'b0;
    #500;`test("REM Test5 [rem by zero]", op1);

    //REMU Test1
    alucode<=`ALU_REMU;
    op1<=32'h00003141;
    op2<=32'h00005926;
    rst<=1'b1;
    #10;rst<=1'b0;
    ans<=op1%op2;
    #500;`test("REMU Test1 [small case]", ans);
    
    //REMU Test2
    alucode<=`ALU_REMU;
    op1<=4294967295;
    op2<=1234;
    rst<=1'b1;
    #10;rst<=1'b0;
    ans<=op1%op2;
    #500;`test("REMU Test2 [large case]", ans);



    $display("All tests passed!");
    $finish(2);
end

endmodule
`default_nettype wire