module cpu_tb;
    reg sysclk;
    reg cpu_resetn;

    parameter CYCLE = 10;

    always #(CYCLE/2) sysclk = ~sysclk;

    CPUTop cpu0(
       .clk(sysclk),
       .rst(~cpu_resetn)
    );
    
    integer i;
    initial begin
        $dumpfile("tb_cputop.vcd");
        $dumpvars(0, cpu_tb);
        for(i=0;i<32;i++)begin
            $dumpvars(1,cpu0.register1.regfile[i]);
        end
    end

    initial begin
        #10     sysclk     = 1'd0;
                cpu_resetn    = 1'd0;
        #(CYCLE) cpu_resetn = 1'd1;
        #200000 $finish;
    end

endmodule
