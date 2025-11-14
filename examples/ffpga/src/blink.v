// Simple Blinking LED with Cathode Control
// Proper two-pin LED control for Charlieplex configuration
(* top *)
module DemoSimpleBlinking #(
    parameter IN_CLK_HZ = 50000000,  // 50MHz
    parameter BLINK_HZ = 2           // 2Hz = blink twice per second
) (
    (* iopad_external_pin *)
    input nreset,
    (* iopad_external_pin, clkbuf_inhibit *)
    input clk,
    (* iopad_external_pin *)
    output osc_en,
    
    // LED1 Anode (HIGH when LED is on)
    (* iopad_external_pin *)
    output led1_anode_oe,
    (* iopad_external_pin *)
    output led1_anode,
    
    // LED1 Cathode (LOW when LED is on)
    (* iopad_external_pin *)
    output led1_cathode_oe,
    (* iopad_external_pin *)
    output led1_cathode
);

    // OSC config
    assign osc_en = 1'b1;
    
    // Output Enable for both anode and cathode
    assign led1_anode_oe = 1'b1;   // Enable anode output
    assign led1_cathode_oe = 1'b1;  // Enable cathode output
    
    // Cathode is always LOW (ground)
    assign led1_cathode = 1'b0;
    
    // Simple blinker
    blinker #(
        .IN_CLK_HZ(IN_CLK_HZ),
        .BLINK_HZ(BLINK_HZ)
    ) blinker_led1 (
        .clk(clk),
        .nreset(nreset),
        .out(led1_anode)  // Connect to anode
    );

endmodule

// Simple Blinker module
module blinker #(
    parameter IN_CLK_HZ = 50000000,
    parameter BLINK_HZ = 2
) (
    input clk,
    input nreset,
    output reg out
);

    // Calculate counter width for desired blink frequency
    localparam CNT_MAX = IN_CLK_HZ / (2 * BLINK_HZ) - 1;
    localparam CNT_WIDTH = $clog2(CNT_MAX + 1);
    
    reg [CNT_WIDTH-1:0] counter;
    
    always @(posedge clk) begin
        if (!nreset) begin
            counter <= 0;
            out <= 0;
        end else begin
            if (counter >= CNT_MAX) begin
                counter <= 0;
                out <= ~out;  // Toggle LED state
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule