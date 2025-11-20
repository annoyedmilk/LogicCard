// ================================================================
//  DEMO:
//  Charlieplex 105-LED 15x7 Matrix + Ripple Effect Animation
//  With Button Controls
// ================================================================

(* top *)
module Demo #(
    parameter IN_CLK_HZ  = 50_000_000,
    parameter REFRESH_HZ = 1_000
) (
    (* iopad_external_pin *)
    input nreset,
    (* iopad_external_pin, clkbuf_inhibit *)
    input clk,
    (* iopad_external_pin *)
    output osc_en,

    // Button inputs (active high)
    (* iopad_external_pin *) input BTN1,  // Invert pattern
    (* iopad_external_pin *) input BTN2,  // Speed up
    (* iopad_external_pin *) input BTN3,  // Speed down
    (* iopad_external_pin *) input BTN4,  // Pause/Play

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

    // Bundle pins
    wire [10:0] oe_pins;
    wire [10:0] charlieplex_pins;

    assign CHARLIEPLEX_OE_0   = oe_pins[0];
    assign CHARLIEPLEX_PIN_0  = charlieplex_pins[0];
    assign CHARLIEPLEX_OE_1   = oe_pins[1];
    assign CHARLIEPLEX_PIN_1  = charlieplex_pins[1];
    assign CHARLIEPLEX_OE_2   = oe_pins[2];
    assign CHARLIEPLEX_PIN_2  = charlieplex_pins[2];
    assign CHARLIEPLEX_OE_3   = oe_pins[3];
    assign CHARLIEPLEX_PIN_3  = charlieplex_pins[3];
    assign CHARLIEPLEX_OE_4   = oe_pins[4];
    assign CHARLIEPLEX_PIN_4  = charlieplex_pins[4];
    assign CHARLIEPLEX_OE_5   = oe_pins[5];
    assign CHARLIEPLEX_PIN_5  = charlieplex_pins[5];
    assign CHARLIEPLEX_OE_6   = oe_pins[6];
    assign CHARLIEPLEX_PIN_6  = charlieplex_pins[6];
    assign CHARLIEPLEX_OE_7   = oe_pins[7];
    assign CHARLIEPLEX_PIN_7  = charlieplex_pins[7];
    assign CHARLIEPLEX_OE_8   = oe_pins[8];
    assign CHARLIEPLEX_PIN_8  = charlieplex_pins[8];
    assign CHARLIEPLEX_OE_9   = oe_pins[9];
    assign CHARLIEPLEX_PIN_9  = charlieplex_pins[9];
    assign CHARLIEPLEX_OE_10  = oe_pins[10];
    assign CHARLIEPLEX_PIN_10 = charlieplex_pins[10];

    // Debounced button signals and edge detection
    wire btn1_db, btn2_db, btn3_db, btn4_db;
    wire btn1_press, btn2_press, btn3_press, btn4_press;

    // Debounce all buttons
    button_debounce #(.CLK_HZ(IN_CLK_HZ)) db1 (.clk(clk), .nreset(nreset), .btn_in(BTN1), .btn_out(btn1_db));
    button_debounce #(.CLK_HZ(IN_CLK_HZ)) db2 (.clk(clk), .nreset(nreset), .btn_in(BTN2), .btn_out(btn2_db));
    button_debounce #(.CLK_HZ(IN_CLK_HZ)) db3 (.clk(clk), .nreset(nreset), .btn_in(BTN3), .btn_out(btn3_db));
    button_debounce #(.CLK_HZ(IN_CLK_HZ)) db4 (.clk(clk), .nreset(nreset), .btn_in(BTN4), .btn_out(btn4_db));

    // Edge detection for button presses
    edge_detect ed1 (.clk(clk), .nreset(nreset), .signal(btn1_db), .edge_pulse(btn1_press));
    edge_detect ed2 (.clk(clk), .nreset(nreset), .signal(btn2_db), .edge_pulse(btn2_press));
    edge_detect ed3 (.clk(clk), .nreset(nreset), .signal(btn3_db), .edge_pulse(btn3_press));
    edge_detect ed4 (.clk(clk), .nreset(nreset), .signal(btn4_db), .edge_pulse(btn4_press));

    // LED Scanner with button controls
    led_scanner #(
        .IN_CLK_HZ(IN_CLK_HZ),
        .REFRESH_HZ(REFRESH_HZ)
    ) scanner (
        .clk(clk),
        .nreset(nreset),
        .btn_invert(btn1_press),
        .btn_speed_up(btn2_press),
        .btn_speed_down(btn3_press),
        .btn_pause(btn4_press),
        .oe_pins(oe_pins),
        .charlieplex_pins(charlieplex_pins)
    );

endmodule


// ================================================================
//  Button Debouncer (20ms debounce time)
// ================================================================
module button_debounce #(
    parameter CLK_HZ = 50_000_000
)(
    input clk,
    input nreset,
    input btn_in,
    output reg btn_out
);
    localparam DEBOUNCE_MS = 20;
    localparam CNT_MAX     = (CLK_HZ / 1_000) * DEBOUNCE_MS;
    localparam CNT_WIDTH   = $clog2(CNT_MAX + 1);

    reg [CNT_WIDTH-1:0] counter;
    reg btn_sync_0, btn_sync_1;

    always @(posedge clk) begin
        if (!nreset) begin
            btn_sync_0 <= 0;
            btn_sync_1 <= 0;
            btn_out    <= 0;
            counter    <= 0;
        end else begin
            // Synchronizer
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;

            // Debounce logic
            if (btn_sync_1 == btn_out) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
                if (counter >= CNT_MAX) begin
                    btn_out <= btn_sync_1;
                    counter <= 0;
                end
            end
        end
    end
endmodule


// ================================================================
//  Edge Detector (rising edge)
// ================================================================
module edge_detect (
    input clk,
    input nreset,
    input signal,
    output reg edge_pulse
);
    reg signal_delayed;

    always @(posedge clk) begin
        if (!nreset) begin
            signal_delayed <= 0;
            edge_pulse     <= 0;
        end else begin
            signal_delayed <= signal;
            edge_pulse     <= signal && !signal_delayed;
        end
    end
endmodule


// ================================================================
//  Ripple Pattern Generator
// ================================================================
module ripple_effect (
    input clk,
    input nreset,
    input [6:0] led_index,
    input invert,
    input paused,
    input [22:0] speed_divisor,
    output reg led_on
);
    localparam MAX_LED      = 104;
    localparam RIPPLE_WIDTH = 2;

    reg [6:0]  ripple_pos;
    reg [22:0] slowcnt;

    // Ripple position update
    always @(posedge clk) begin
        if (!nreset) begin
            slowcnt    <= 0;
            ripple_pos <= 0;
        end else begin
            if (!paused) begin
                if (slowcnt >= speed_divisor) begin
                    slowcnt    <= 0;
                    ripple_pos <= (ripple_pos >= MAX_LED) ? 0 : ripple_pos + 1;
                end else begin
                    slowcnt <= slowcnt + 1;
                end
            end
        end
    end

    // LED ON logic with optional invert
    always @(*) begin
        led_on = 1'b0;
        if (led_index >= (ripple_pos - RIPPLE_WIDTH))
            if (led_index <= (ripple_pos + RIPPLE_WIDTH))
                led_on = 1'b1;

        if (invert)
            led_on = ~led_on;
    end
endmodule


// ================================================================
//  LED Scanner
// ================================================================
module led_scanner #(
    parameter IN_CLK_HZ  = 50_000_000,
    parameter REFRESH_HZ = 1_000
)(
    input clk,
    input nreset,
    input btn_invert,
    input btn_speed_up,
    input btn_speed_down,
    input btn_pause,
    output reg [10:0] oe_pins,
    output reg [10:0] charlieplex_pins
);

    localparam LED_COUNT     = 105;
    localparam LINE_SCAN_HZ  = REFRESH_HZ * LED_COUNT;
    localparam CNT_MAX       = IN_CLK_HZ / LINE_SCAN_HZ - 1;
    localparam CNT_WIDTH     = $clog2(CNT_MAX + 1);

    reg [CNT_WIDTH-1:0] counter;
    reg [6:0] led_index;

    // Button state registers
    reg invert_state;
    reg paused_state;
    reg [22:0] speed_divisor;

    // Speed levels: 0=slowest, 4=fastest
    localparam [22:0] SPEED_0 = 1_000_000;
    localparam [22:0] SPEED_1 = 500_000;
    localparam [22:0] SPEED_2 = 250_000;
    localparam [22:0] SPEED_3 = 100_000;
    localparam [22:0] SPEED_4 = 50_000;
    reg [2:0] speed_level;

    // Button control logic
    always @(posedge clk) begin
        if (!nreset) begin
            invert_state <= 0;
            paused_state <= 0;
            speed_level  <= 1;  // Start at medium speed
        end else begin
            if (btn_invert)
                invert_state <= ~invert_state;

            if (btn_pause)
                paused_state <= ~paused_state;

            if (btn_speed_up && speed_level < 4)
                speed_level <= speed_level + 1;

            if (btn_speed_down && speed_level > 0)
                speed_level <= speed_level - 1;
        end
    end

    // Speed divisor lookup
    always @(*) begin
        case (speed_level)
            0: speed_divisor = SPEED_0;
            1: speed_divisor = SPEED_1;
            2: speed_divisor = SPEED_2;
            3: speed_divisor = SPEED_3;
            4: speed_divisor = SPEED_4;
            default: speed_divisor = SPEED_1;
        endcase
    end

    // Ripple pattern
    wire led_on;
    ripple_effect pattern(
        .clk(clk),
        .nreset(nreset),
        .led_index(led_index),
        .invert(invert_state),
        .paused(paused_state),
        .speed_divisor(speed_divisor),
        .led_on(led_on)
    );

    // LED scanning
    always @(posedge clk) begin
        if (!nreset) begin
            counter          <= 0;
            led_index        <= 0;
            oe_pins          <= 0;
            charlieplex_pins <= 0;
        end else begin

            if (counter >= CNT_MAX) begin
                counter   <= 0;
                led_index <= (led_index >= LED_COUNT-1) ? 0 : led_index + 1;
            end else begin
                counter <= counter + 1;
            end

            // Default pins off
            oe_pins          <= 11'b0;
            charlieplex_pins <= 11'b0;

            if (led_on) begin
                // LED mapping case statement
                case (led_index)

                // Pin0 cathode (LEDs 0-9)
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

                // Pin1 cathode (LEDs 10-19)
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

                // Pin2 cathode (LEDs 20-29)
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

                // Pin3 cathode (LEDs 30-39)
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

                // Pin4 cathode (LEDs 40-49)
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

                // Pin5 cathode (LEDs 50-59)
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

                // Pin6 cathode (LEDs 60-69)
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

                // Pin7 cathode (LEDs 70-79)
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

                // Pin8 cathode (LEDs 80-89)
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

                // Pin9 cathode (LEDs 90-99)
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

                // Pin10 cathode (LEDs 100-104)
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
