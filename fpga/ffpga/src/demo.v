// ================================================================
//  DEMO:
//  Charlieplex 105-LED 15x7 Matrix + Ripple Effect Animation
// ================================================================

(* top *)
module DemoSimpleRipple #(
    parameter IN_CLK_HZ   = 50_000_000,
    parameter REFRESH_HZ  = 1000     // Full scan refresh
) (
    (* iopad_external_pin *)
    input nreset,
    (* iopad_external_pin, clkbuf_inhibit *)
    input clk,
    (* iopad_external_pin *)
    output osc_en,

    // Charlieplex pins (11 pins)
    (* iopad_external_pin *) output CHARLIEPLEX_OE_0,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_0,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_1,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_1,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_2,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_2,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_3,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_3,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_4,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_4,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_5,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_5,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_6,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_6,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_7,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_7,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_8,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_8,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_9,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_9,
    (* iopad_external_pin *) output CHARLIEPLEX_OE_10,
    (* iopad_external_pin *) output CHARLIEPLEX_PIN_10
);

assign osc_en = 1'b1;

// Bundle pins for cleaner wiring
wire [10:0] oe_pins;
wire [10:0] charlieplex_pins;

assign CHARLIEPLEX_OE_0  = oe_pins[0];
assign CHARLIEPLEX_PIN_0 = charlieplex_pins[0];
assign CHARLIEPLEX_OE_1  = oe_pins[1];
assign CHARLIEPLEX_PIN_1 = charlieplex_pins[1];
assign CHARLIEPLEX_OE_2  = oe_pins[2];
assign CHARLIEPLEX_PIN_2 = charlieplex_pins[2];
assign CHARLIEPLEX_OE_3  = oe_pins[3];
assign CHARLIEPLEX_PIN_3 = charlieplex_pins[3];
assign CHARLIEPLEX_OE_4  = oe_pins[4];
assign CHARLIEPLEX_PIN_4 = charlieplex_pins[4];
assign CHARLIEPLEX_OE_5  = oe_pins[5];
assign CHARLIEPLEX_PIN_5 = charlieplex_pins[5];
assign CHARLIEPLEX_OE_6  = oe_pins[6];
assign CHARLIEPLEX_PIN_6 = charlieplex_pins[6];
assign CHARLIEPLEX_OE_7  = oe_pins[7];
assign CHARLIEPLEX_PIN_7 = charlieplex_pins[7];
assign CHARLIEPLEX_OE_8  = oe_pins[8];
assign CHARLIEPLEX_PIN_8 = charlieplex_pins[8];
assign CHARLIEPLEX_OE_9  = oe_pins[9];
assign CHARLIEPLEX_PIN_9 = charlieplex_pins[9];
assign CHARLIEPLEX_OE_10 = oe_pins[10];
assign CHARLIEPLEX_PIN_10 = charlieplex_pins[10];


// ================================================================
//  LED Scanner + Ripple Effect
// ================================================================
led_scanner #(
    .IN_CLK_HZ(IN_CLK_HZ),
    .REFRESH_HZ(REFRESH_HZ)
) scanner (
    .clk(clk),
    .nreset(nreset),
    .oe_pins(oe_pins),
    .charlieplex_pins(charlieplex_pins)
);

endmodule


// ================================================================
//  Ripple Pattern Generator
//  Simple moving band 
// ================================================================
module ripple_effect (
    input clk,
    input nreset,
    input [6:0] led_index,   // 0–104
    output reg led_on
);
    localparam MAX_LED      = 104;
    localparam RIPPLE_WIDTH = 2;

    // slow ripple position counter
    reg [6:0] ripple_pos;
    reg [22:0] slowcnt;

    always @(posedge clk) begin
        if (!nreset) begin
            slowcnt    <= 0;
            ripple_pos <= 0;
        end else begin
            if (slowcnt >= 500_000) begin
                slowcnt <= 0;

                if (ripple_pos >= MAX_LED)
                    ripple_pos <= 0;
                else
                    ripple_pos <= ripple_pos + 1;

            end else begin
                slowcnt <= slowcnt + 1;
            end
        end
    end

    // LED ON logic (comparison only)
    always @(*) begin
        led_on = 1'b0;

        if (led_index >= (ripple_pos - RIPPLE_WIDTH))
            if (led_index <= (ripple_pos + RIPPLE_WIDTH))
                led_on = 1'b1;
    end
endmodule



// ================================================================
//  LED Scanner
// ================================================================
module led_scanner #(
    parameter IN_CLK_HZ = 50000000,
    parameter REFRESH_HZ = 1000
)(
    input clk,
    input nreset,
    output reg [10:0] oe_pins,
    output reg [10:0] charlieplex_pins
);

    localparam LED_COUNT = 105;

    localparam LINE_SCAN_HZ = REFRESH_HZ * LED_COUNT;
    localparam CNT_MAX = IN_CLK_HZ / LINE_SCAN_HZ - 1;
    localparam CNT_WIDTH = $clog2(CNT_MAX + 1);

    reg [CNT_WIDTH-1:0] counter;
    reg [6:0] led_index;  // 0..104

    // Ripple pattern
    wire led_on;
    ripple_effect pattern(
        .clk(clk),
        .nreset(nreset),
        .led_index(led_index),
        .led_on(led_on)
    );

    always @(posedge clk) begin
        if (!nreset) begin
            counter <= 0;
            led_index <= 0;
            oe_pins <= 0;
            charlieplex_pins <= 0;
        end else begin

            // timing
            if (counter >= CNT_MAX) begin
                counter <= 0;

                if (led_index >= LED_COUNT-1)
                    led_index <= 0;
                else
                    led_index <= led_index + 1;

            end else begin
                counter <= counter + 1;
            end

            // default pins off
            oe_pins <= 11'b0;
            charlieplex_pins <= 11'b0;

            if (led_on) begin
                // -----------------------------
                // Existing LED case-map
                // -----------------------------
                case (led_index)

                // Pin0 is cathode for LEDs 0-9
                0: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                1: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                2: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                3: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                4: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                5: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                6: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                7: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                8: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end
                9: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[0] <= 1; charlieplex_pins[0] <= 0; end

                // Pin1 is cathode for LEDs 10-19
                10: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                11: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                12: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                13: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                14: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                15: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                16: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                17: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                18: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end
                19: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[1] <= 1; charlieplex_pins[1] <= 0; end

                // Pin2 is cathode for LEDs 20-29
                20: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                21: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                22: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                23: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                24: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                25: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                26: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                27: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                28: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end
                29: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[2] <= 1; charlieplex_pins[2] <= 0; end

                // Pin3 is cathode for LEDs 30-39
                30: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                31: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                32: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                33: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                34: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                35: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                36: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                37: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                38: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end
                39: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[3] <= 1; charlieplex_pins[3] <= 0; end

                // Pin4 is cathode for LEDs 40-49
                40: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                41: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                42: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                43: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                44: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                45: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                46: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                47: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                48: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end
                49: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[4] <= 1; charlieplex_pins[4] <= 0; end

                // Pin5 is cathode for LEDs 50-59
                50: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                51: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                52: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                53: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                54: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                55: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                56: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                57: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                58: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end
                59: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[5] <= 1; charlieplex_pins[5] <= 0; end

                // Pin6 is cathode for LEDs 60-69
                60: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                61: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                62: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                63: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                64: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                65: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                66: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                67: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                68: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end
                69: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[6] <= 1; charlieplex_pins[6] <= 0; end

                // Pin7 is cathode for LEDs 70-79
                70: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                71: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                72: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                73: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                74: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                75: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                76: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                77: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                78: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end
                79: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[7] <= 1; charlieplex_pins[7] <= 0; end

                // Pin8 is cathode for LEDs 80-89
                80: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                81: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                82: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                83: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                84: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                85: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                86: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                87: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                88: begin oe_pins[9] <= 1; charlieplex_pins[9] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end
                89: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[8] <= 1; charlieplex_pins[8] <= 0; end

                // Pin9 is cathode for LEDs 90-99
                90: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                91: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                92: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                93: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                94: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                95: begin oe_pins[5] <= 1; charlieplex_pins[5] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                96: begin oe_pins[6] <= 1; charlieplex_pins[6] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                97: begin oe_pins[7] <= 1; charlieplex_pins[7] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                98: begin oe_pins[8] <= 1; charlieplex_pins[8] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end
                99: begin oe_pins[10] <= 1; charlieplex_pins[10] <= 1; oe_pins[9] <= 1; charlieplex_pins[9] <= 0; end

                // Pin10 is cathode for LEDs 100-104 (only 5 LEDs to reach 105 total)
                100: begin oe_pins[0] <= 1; charlieplex_pins[0] <= 1; oe_pins[10] <= 1; charlieplex_pins[10] <= 0; end
                101: begin oe_pins[1] <= 1; charlieplex_pins[1] <= 1; oe_pins[10] <= 1; charlieplex_pins[10] <= 0; end
                102: begin oe_pins[2] <= 1; charlieplex_pins[2] <= 1; oe_pins[10] <= 1; charlieplex_pins[10] <= 0; end
                103: begin oe_pins[3] <= 1; charlieplex_pins[3] <= 1; oe_pins[10] <= 1; charlieplex_pins[10] <= 0; end
                104: begin oe_pins[4] <= 1; charlieplex_pins[4] <= 1; oe_pins[10] <= 1; charlieplex_pins[10] <= 0; end

                default: begin end
                endcase
            end
        end
    end

endmodule
