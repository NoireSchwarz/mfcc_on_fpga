`timescale 1ns / 1ps

module tb_power_spectrum();

    // 参数定义
    localparam int N = 512; // 与模块默认参数保持一致
    
    // 时钟与复位信号
    logic clk;
    logic reset;
    
    // 输入接口信号
    logic [15:0] in;
    logic s_valid;
    logic s_last;
    logic s_ready;
    
    // 输出接口信号
    logic [31:0] out;
    logic m_ready;
    logic m_valid;
    logic m_last;
    
    // 实例化被测设计 (DUT)
    power_spectrum #(
        .N(N)
    ) dut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out),
        .s_ready(s_ready),
        .s_valid(s_valid),
        .s_last(s_last),
        .m_ready(m_ready),
        .m_valid(m_valid),
        .m_last(m_last)
    );
    
    // 1. 生成时钟信号 (100MHz, 周期为10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 2. 生成测试激励
    initial begin
        // 初始化输入信号
        reset = 1'b1;
        in = 16'h0000;
        s_valid = 1'b0;
        s_last = 1'b0;
        m_ready = 1'b1; // 始终准备好接收输出数据
        
        // 保持复位状态一段时间后释放复位
        #100;
        @(posedge clk);
        reset = 1'b0;
        
        // 等待几个时钟周期
        #50;
        
        // 发送一帧完整的数据 (长度为 N=512)
        for (int i = 0; i < N; i++) begin
            @(posedge clk);
            s_valid = 1'b1;
            
            // 生成测试数据：这里使用简单的递增序列作为示例。
            // 实际测试中，您可以使用系统函数 $sin 生成正弦波，或者从文件读取真实采样数据。
            in = i * 10; 
            
            // 标记帧的最后一个数据
            if (i == N - 1) begin
                s_last = 1'b1;
            end else begin
                s_last = 1'b0;
            end
        end
        
        // 数据发送完毕，拉低有效信号
        @(posedge clk);
        s_valid = 1'b0;
        s_last = 1'b0;
        in = 16'h0000;
        
        // 3. 等待 FFT 和流水线乘法器处理完成
        // 因为乘法器有 7 级流水线延迟，且 FFT 处理需要时间，在此留出充足的仿真时间
        #20000;
        
        // 结束仿真
        $finish;
    end
    
    // 4. 监控输出结果
    initial begin
        // 当输出信号有效时，在控制台打印输出数据
        forever begin
            @(posedge clk);
            if (m_valid) begin
                $display("Time: %0t | Output Valid! out = %d", $time, out);
            end
        end
    end

endmodule