module RAM(clk, we, r_addr, r_data, w_addr, w_data); 
    //64Kib = 32bit * 16384 (アドレス: 14bit)
    input clk,we;
    input  [13:0] r_addr, w_addr;
    input  [31:0] w_data;
    output reg [31:0] r_data;
    reg [31:0] mem [24576];

    initial begin
        $readmemh(`DATAHEX, mem);
    end

    always @(posedge clk) begin
        if(we) mem[w_addr] <= w_data;
        r_data <= mem[r_addr];
    end
endmodule
