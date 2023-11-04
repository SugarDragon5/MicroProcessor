module cpu_tb;
    reg sysclk;
    reg cpu_resetn;

    parameter CYCLE = 10;

    always #(CYCLE/2) sysclk = ~sysclk;

    CPUTop cpu0(
       .clk(sysclk),
       .rst(~cpu_resetn)
    );
    
    initial begin
        $dumpfile("tb_cputop.vcd");
        $dumpvars(0, cpu_tb);
    end

    initial begin
        #10     sysclk     = 1'd0;
                cpu_resetn    = 1'd0;
        #(CYCLE) cpu_resetn = 1'd1;
        #200000 $finish;
    end

endmodule
