// ================================================================
//  DEMO: Simple Blinking LED
//  Proper two-pin LED control for Charlieplex configuration
// ================================================================

(* top *)
module DemoSimpleBlinking #(
    parameter IN_CLK_HZ = 50_000_000,  // 50MHz input clock
    parameter BLINK_HZ  = 2            // 2Hz = blink twice per second
) (
    (* iopad_external_pin *)
    input nreset,
    (* iopad_external_pin, clkbuf_inhibit *)
    input clk,
    (* iopad_external_pin *)
    output osc_en,

    // LED1 control pins
    (* iopad_external_pin *)
    output led1_anode_oe,      // Anode output enable
    (* iopad_external_pin *)
    output led1_anode,         // Anode signal (HIGH = LED on)

    (* iopad_external_pin *)
    output led1_cathode_oe,    // Cathode output enable
    (* iopad_external_pin *)
    output led1_cathode        // Cathode signal (LOW = LED on)
);

    // Enable oscillator
    assign osc_en = 1'b1;

    // Enable both anode and cathode outputs
    assign led1_anode_oe   = 1'b1;
    assign led1_cathode_oe = 1'b1;

    // Cathode held at ground (common for single LED)
    assign led1_cathode = 1'b0;

    // Instantiate blinker for anode control
    blinker #(
        .IN_CLK_HZ(IN_CLK_HZ),
        .BLINK_HZ(BLINK_HZ)
    ) blinker_led1 (
        .clk(clk),
        .nreset(nreset),
        .out(led1_anode)
    );

endmodule


// ================================================================
//  Blinker Module
//  Toggles output at specified frequency
// ================================================================
module blinker #(
    parameter IN_CLK_HZ = 50_000_000,
    parameter BLINK_HZ  = 2
) (
    input clk,
    input nreset,
    output reg out
);

    // Calculate counter max for desired blink frequency
    localparam CNT_MAX   = IN_CLK_HZ / (2 * BLINK_HZ) - 1;
    localparam CNT_WIDTH = $clog2(CNT_MAX + 1);

    reg [CNT_WIDTH-1:0] counter;

    // Toggle logic
    always @(posedge clk) begin
        if (!nreset) begin
            counter <= 0;
            out     <= 0;
        end else begin
            // Count up to CNT_MAX, then toggle output
            if (counter >= CNT_MAX) begin
                counter <= 0;
                out     <= ~out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
