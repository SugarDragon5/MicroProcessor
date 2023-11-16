module BTB (
    input wire clk,
    //read
    input wire [15:0] PC,
    output wire [5:0] tag,
    output wire [15:0] NPC_predict,
    //write
    input wire we,
    input wire [15:0] PC_actual,
    input wire [15:0] NPC_actual
);
    //入出力では生のPCをやり取りする
    //内部では下2bit(必ず0)を切り捨てる
    parameter BTB_SIZE = 256;   // tag: 6bit[15:10], index: 8bit[9:2], always zero: 2bit[1:0] (total 16bit)
    reg [19:0] mem[0:BTB_SIZE-1];   //tag(6bit) + NPC[15:2](14bit)
    wire [7:0] w_addr, r_addr;
    wire [19:0] r_data;
    assign w_addr=PC_actual[9:2];
    assign r_addr=PC[9:2];
    assign tag=r_data[19:14];
    assign NPC_predict={r_data[13:0], 2'b00};
    always @(negedge clk) begin
        if(we) begin
            mem[w_addr] <= {PC_actual[15:10], NPC_actual[15:2]};
        end
    end
    assign r_data = mem[r_addr];
endmodule