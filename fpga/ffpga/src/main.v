`timescale 1ns / 1ps

// Simple Charlieplex LED Controller
// Controls 105 LEDs using 11 GPIO pins
// Lights one LED at a time in sequence

(* top *) module top(
    (* clkbuf_inhibit *) input i_clk,
    input i_nreset,
    output o_osc_ctrl_en,

    // 11 Data pins
    output reg CHARLIEPLEX_PIN_0,
    output reg CHARLIEPLEX_PIN_1,
    output reg CHARLIEPLEX_PIN_2,
    output reg CHARLIEPLEX_PIN_3,
    output reg CHARLIEPLEX_PIN_4,
    output reg CHARLIEPLEX_PIN_5,
    output reg CHARLIEPLEX_PIN_6,
    output reg CHARLIEPLEX_PIN_7,
    output reg CHARLIEPLEX_PIN_8,
    output reg CHARLIEPLEX_PIN_9,
    output reg CHARLIEPLEX_PIN_10,

    // 11 Output Enable pins (1 = output, 0 = high-Z)
    output CHARLIEPLEX_OE_0,
    output CHARLIEPLEX_OE_1,
    output CHARLIEPLEX_OE_2,
    output CHARLIEPLEX_OE_3,
    output CHARLIEPLEX_OE_4,
    output CHARLIEPLEX_OE_5,
    output CHARLIEPLEX_OE_6,
    output CHARLIEPLEX_OE_7,
    output CHARLIEPLEX_OE_8,
    output CHARLIEPLEX_OE_9,
    output CHARLIEPLEX_OE_10
);

    // Enable the on-chip oscillator
    assign o_osc_ctrl_en = 1'b1;

    // Reset synchronizer
    reg [2:0] r_rst = 3'b000;
    wire w_reset;

    always @(posedge i_clk) begin
        r_rst[0] <= i_nreset;
        r_rst[1] <= r_rst[0];
        r_rst[2] <= ~r_rst[1];
    end

    assign w_reset = r_rst[2];

    // Counter to slow down the LED sequence
    // 25-bit counter at 50MHz = ~0.67 second per LED
    reg [24:0] slow_counter = 0;
    reg [6:0] current_led = 0;  // Which LED to light (0-104)

    // OE control registers
    reg [10:0] oe_pins = 11'b0;

    // Assign OE outputs
    assign {CHARLIEPLEX_OE_10, CHARLIEPLEX_OE_9, CHARLIEPLEX_OE_8,
            CHARLIEPLEX_OE_7,  CHARLIEPLEX_OE_6, CHARLIEPLEX_OE_5,
            CHARLIEPLEX_OE_4,  CHARLIEPLEX_OE_3, CHARLIEPLEX_OE_2,
            CHARLIEPLEX_OE_1,  CHARLIEPLEX_OE_0} = oe_pins;

    // Main counter - increments every clock
    always @(posedge i_clk) begin
        if (w_reset) begin
            slow_counter <= 25'd0;
            current_led <= 7'd0;
        end else begin
            slow_counter <= slow_counter + 1;

            // When counter overflows, move to next LED
            if (slow_counter == 0) begin
                if (current_led < 104)
                    current_led <= current_led + 1;
                else
                    current_led <= 0;  // Loop back to first LED
            end
        end
    end

    // LED control logic
    // For each LED, set the appropriate pins HIGH/LOW/Hi-Z
    always @(posedge i_clk) begin
        // Default: all pins to high-Z (disabled) and LOW
        oe_pins <= 11'b0;

        {CHARLIEPLEX_PIN_10, CHARLIEPLEX_PIN_9, CHARLIEPLEX_PIN_8,
         CHARLIEPLEX_PIN_7,  CHARLIEPLEX_PIN_6, CHARLIEPLEX_PIN_5,
         CHARLIEPLEX_PIN_4,  CHARLIEPLEX_PIN_3, CHARLIEPLEX_PIN_2,
         CHARLIEPLEX_PIN_1,  CHARLIEPLEX_PIN_0} <= 11'b0;

        // Light up the current LED
        // Each LED needs one pin HIGH (anode) and one pin LOW (cathode)
        // All other pins must be high-Z
        case (current_led)
            // Pin0 is cathode for LEDs 0-9
            0: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            1: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            2: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            3: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            4: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            5: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            6: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            7: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            8: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end
            9: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 0; end

            // Pin1 is cathode for LEDs 10-19
            10: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            11: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            12: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            13: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            14: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            15: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            16: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            17: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            18: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end
            19: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 0; end

            // Pin2 is cathode for LEDs 20-29
            20: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            21: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            22: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            23: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            24: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            25: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            26: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            27: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            28: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end
            29: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 0; end

            // Pin3 is cathode for LEDs 30-39
            30: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            31: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            32: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            33: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            34: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            35: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            36: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            37: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            38: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end
            39: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 0; end

            // Pin4 is cathode for LEDs 40-49
            40: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            41: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            42: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            43: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            44: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            45: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            46: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            47: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            48: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end
            49: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 0; end

            // Pin5 is cathode for LEDs 50-59
            50: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            51: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            52: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            53: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            54: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            55: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            56: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            57: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            58: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end
            59: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 0; end

            // Pin6 is cathode for LEDs 60-69
            60: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            61: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            62: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            63: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            64: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            65: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            66: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            67: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            68: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end
            69: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 0; end

            // Pin7 is cathode for LEDs 70-79
            70: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            71: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            72: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            73: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            74: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            75: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            76: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            77: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            78: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end
            79: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 0; end

            // Pin8 is cathode for LEDs 80-89
            80: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            81: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            82: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            83: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            84: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            85: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            86: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            87: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            88: begin oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end
            89: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 0; end

            // Pin9 is cathode for LEDs 90-99
            90: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            91: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            92: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            93: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            94: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            95: begin oe_pins[5] <= 1; CHARLIEPLEX_PIN_5 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            96: begin oe_pins[6] <= 1; CHARLIEPLEX_PIN_6 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            97: begin oe_pins[7] <= 1; CHARLIEPLEX_PIN_7 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            98: begin oe_pins[8] <= 1; CHARLIEPLEX_PIN_8 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end
            99: begin oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 1; oe_pins[9] <= 1; CHARLIEPLEX_PIN_9 <= 0; end

            // Pin10 is cathode for LEDs 100-104
            100: begin oe_pins[0] <= 1; CHARLIEPLEX_PIN_0 <= 1; oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 0; end
            101: begin oe_pins[1] <= 1; CHARLIEPLEX_PIN_1 <= 1; oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 0; end
            102: begin oe_pins[2] <= 1; CHARLIEPLEX_PIN_2 <= 1; oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 0; end
            103: begin oe_pins[3] <= 1; CHARLIEPLEX_PIN_3 <= 1; oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 0; end
            104: begin oe_pins[4] <= 1; CHARLIEPLEX_PIN_4 <= 1; oe_pins[10] <= 1; CHARLIEPLEX_PIN_10 <= 0; end

            default: begin
                // All pins high-Z (safe default)
            end
        endcase
    end

endmodule
