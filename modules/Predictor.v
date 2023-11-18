module Predictor (
    input wire clk,
    input wire rst,
    //write
    input wire [15:0] PC_actual,
    input wire [15:0] NPC_actual,
    input wire is_taken_actual,
    //read
    input wire [15:0] PC,
    output wire [15:0] NPC_predict
);
    wire [15:0] NPC_predict_btb;
    BTB btb1(
        .clk(clk),
        .rst(rst),
        .we(is_taken_actual),
        .PC_actual(PC_actual),
        .NPC_actual(NPC_actual),
        .PC(PC),
        .NPC_predict(NPC_predict_btb)
    );

    wire is_taken_predict;
    PHT pht1(
        .clk(clk),
        .rst(rst),
        .PC_actual(PC_actual),
        .is_taken_actual(is_taken_actual),
        .PC(PC),
        .is_taken_predict(is_taken_predict)
    );
    assign NPC_predict = is_taken_predict?NPC_predict_btb:PC+4;
endmodule