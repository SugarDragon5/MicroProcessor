module ROM(
    input wire clk,
    input wire [13:0] r1_addr,
    input wire [13:0] r2_addr,
    output reg [31:0] r1_data,
    output reg [31:0] r2_data
);
    //64Kib = 32bit * 16384 (アドレス: 14bit)
    (* ram_style = "block" *) reg [31:0] mem[0:32767];

    initial begin
        $readmemh(`CODEHEX, mem);
    end
    
    always @(negedge clk) begin
        r1_data <= mem[r1_addr];
        r2_data <= mem[r2_addr];
    end

endmodule
