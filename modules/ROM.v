module ROM(clk, r_addr, r_data);
    //64Kib = 32bit * 16384 (アドレス: 14bit)
    input clk;
    input  [13:0] r_addr;
    output reg [31:0] r_data;
    (* ram_style = "block" *) reg [31:0] mem[0:32767];

    initial begin
        $readmemh(`CODEHEX, mem);
    end
    
    always @(negedge clk) begin
        r_data <= mem[r_addr];
    end

endmodule
