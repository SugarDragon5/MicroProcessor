//
// hardware counter
//


module hardware_counter(
    input CLK_IP,
    input RST_IP,
    output [31:0] COUNTER_OP
);

    reg [31:0] cycles;

    always @(posedge CLK_IP) begin
        if(RST_IP)begin
            cycles <= 32'd0;
        end else begin
            cycles <= cycles + 1;
        end
    end

    assign COUNTER_OP = cycles;

endmodule