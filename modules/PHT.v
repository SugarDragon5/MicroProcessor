module PHT (
    input wire clk,
    input wire rst,
    //write
    input wire [15:0] PC_actual,
    input wire is_taken_actual,
    //read
    input wire [15:0] PC,
    output wire is_taken_predict
);
    //状態 00(強くnot taken予測), 01(弱くnot taken予測), 10(弱くtaken予測), 11(強くtaken予測)
    parameter PHT_SIZE = 256;
    integer i;
    reg [1:0] mem[0:PHT_SIZE-1];    //state: 2bit.
    //読み出し部
    wire [7:0] r_addr;
    wire [1:0] r_data;
    assign r_addr=PC[9:2];
    assign r_data=mem[r_addr];
    assign is_taken_predict=
        (r_data==`PHT_TAKEN_STRONG||r_data==`PHT_TAKEN_WEAK)?1'b1:1'b0;
    //更新部
    wire [7:0] w_addr;
    wire [1:0] w_data_current;  //更新前
    wire [1:0] w_data_next;     //更新後
    assign w_addr=PC_actual[9:2];
    assign w_data_current=mem[w_addr];
    function [1:0] calc_next_state;
        input [1:0] current_state;
        input is_taken;
        begin
            if(is_taken)begin
                case(current_state)
                `PHT_NOT_TAKEN_STRONG: begin
                    calc_next_state = `PHT_NOT_TAKEN_WEAK;
                end
                `PHT_NOT_TAKEN_WEAK: begin
                    calc_next_state = `PHT_TAKEN_WEAK;
                end
                `PHT_TAKEN_WEAK: begin
                    calc_next_state = `PHT_TAKEN_STRONG;
                end
                `PHT_TAKEN_STRONG: begin
                    calc_next_state = `PHT_TAKEN_STRONG;
                end
                default: begin
                    calc_next_state = `PHT_TAKEN_WEAK;
                end
                endcase
            end else begin
                case(current_state)
                `PHT_NOT_TAKEN_STRONG: begin
                    calc_next_state = `PHT_NOT_TAKEN_STRONG;
                end
                `PHT_NOT_TAKEN_WEAK: begin
                    calc_next_state = `PHT_NOT_TAKEN_STRONG;
                end
                `PHT_TAKEN_WEAK: begin
                    calc_next_state = `PHT_NOT_TAKEN_WEAK;
                end
                `PHT_TAKEN_STRONG: begin
                    calc_next_state = `PHT_TAKEN_WEAK;
                end
                default: begin
                    calc_next_state = `PHT_NOT_TAKEN_WEAK;
                end
                endcase
            end
        end
    endfunction
    assign w_data_next=calc_next_state(w_data_current, is_taken_actual);

    always @(negedge clk) begin
        mem[w_addr] <= w_data_next;
    end
endmodule