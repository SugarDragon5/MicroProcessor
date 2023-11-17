module BTB (
    input wire clk,
    input wire rst,
    //write
    input wire we,
    input wire [15:0] PC_actual,
    input wire [15:0] NPC_actual,
    //read
    input wire [15:0] PC,
    output wire [15:0] NPC_predict
);
    //入出力では生のPCをやり取りする
    //内部では下2bit(必ず0)を切り捨てる
    parameter BTB_SIZE = 256;   // tag: 6bit[15:10], index: 8bit[9:2], always zero: 2bit[1:0] (total 16bit)
    integer i;
    reg [19:0] mem[0:BTB_SIZE-1];   // valid(1bit) + tag(6bit) + NPC[15:2](14bit)
    reg [BTB_SIZE-1:0] mem_valid;
    wire [7:0] w_addr, r_addr;
    wire [19:0] r_data;
    wire r_valid;
    wire [5:0] tag_input, tag_mem;
    assign w_addr=PC_actual[9:2];
    assign r_addr=PC[9:2];
    assign tag_input=PC[15:10];
    assign tag_mem=r_data[19:14];
    assign NPC_predict=(r_valid&&tag_input==tag_mem)?{r_data[13:0], 2'b00}:PC+4;
    always @(negedge clk) begin
        if(we) begin
            mem[w_addr] <= {PC_actual[15:10], NPC_actual[15:2]};
            mem_valid[w_addr] <= 1;
        end
    end
    always @(posedge rst) begin
        mem_valid <= 0;
    end        
    assign r_data = mem[r_addr];
    assign r_valid = mem_valid[r_addr];
endmodule