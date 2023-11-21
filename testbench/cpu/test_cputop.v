module cpu_tb;
    reg sysclk;
    reg cpu_resetn;

    parameter CYCLE = 10;

    always #(CYCLE/2) sysclk = ~sysclk;

    CPUTop cpu0(
       .sysclk(sysclk),
       .nrst(cpu_resetn)
    );
    
    integer i;
    initial begin
        $dumpfile("tb_cputop.vcd");
        $dumpvars(0, cpu_tb);
        for(i=0;i<32;i++)begin
            $dumpvars(1,cpu0.register1.regfile[i]);
        end
        for(i=0;i<256;i++)begin
            $dumpvars(1,cpu0.predictor1.btb1.mem[i]);
        end
        for(i=0;i<256;i++)begin
            $dumpvars(1,cpu0.predictor1.pht1.mem[i]);
        end
    end

    initial begin
        #10     sysclk     = 1'd0;
                cpu_resetn    = 1'd0;
        #24 cpu_resetn = 1'd1;
        #200000 $finish;
    end

endmodule
