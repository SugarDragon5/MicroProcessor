module MainMemory(clk, we, r_addr, r_data, w_addr, w_data); 
    input clk, we;
    input  [4:0] r_addr, w_addr;
    input  [31:0] w_data;
    output [31:0] r_data;
    reg [31:0] mem [0:31];            // 32bitのレジスタが32個(アドレスは5bit)
    always @(posedge clk) begin
        if(we) mem[w_addr] <= w_data; // クロックと同期して書き込まれる
    end
    assign r_data = mem[r_addr];
endmodule
