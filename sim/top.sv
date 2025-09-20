module top(input logic clk);
    initial begin
        $display("Top module initialized");
    end

    // реагируем на фронты такта, без использования `#` delays
    always_ff @(posedge clk) begin
        $display("Top module saw rising edge at time %0t", $time);
    end
endmodule
