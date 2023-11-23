module Predictor (
    input wire clk,
    input wire rst,
    //write
    input wire [15:0] PC_actual,
    input wire [2:0] history_actual,
    input wire [15:0] NPC_actual,
    input wire is_taken_actual,
    //read
    input wire [15:0] PC,
    input wire [2:0] history,
    output wire [15:0] NPC_predict,
    output wire is_taken_predict
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

    PHT pht1(
        .clk(clk),
        .rst(rst),
        .PC_actual(PC_actual),
        .history_actual(history_actual),
        .is_taken_actual(is_taken_actual),
        .PC(PC),
        .history(history),
        .is_taken_predict(is_taken_predict)
    );
    assign NPC_predict = is_taken_predict?NPC_predict_btb:PC+4;
endmodule