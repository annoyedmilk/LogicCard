`timescale 1ns / 1ps

module top(
    input CLK,  // 50MHz clock
    // GPIO Data outputs
    output CHRLY_1, CHRLY_2, CHRLY_3, CHRLY_4, CHRLY_5, CHRLY_6,
    output CHRLY_7, CHRLY_8, CHRLY_9, CHRLY_10, CHRLY_11,
    // GPIO Output Enable (OE) outputs - High = Output, Low = Input/Hi-Z
    output CHRLY_1_OE, CHRLY_2_OE, CHRLY_3_OE, CHRLY_4_OE, CHRLY_5_OE, CHRLY_6_OE,
    output CHRLY_7_OE, CHRLY_8_OE, CHRLY_9_OE, CHRLY_10_OE, CHRLY_11_OE
);

    localparam CLK_FREQUENCY = 50E6;
    
    wire [10:0] charlieplex_pins;
    wire [10:0] charlieplex_oe;
    
    // Example: Display a simple pattern (you can modify this)
    // Set bits to 1 for LEDs you want to light up
    reg [104:0] led_display_data = 105'b0;
    
    // Example pattern: Light up all LEDs in first row (LEDs 0-14)
    initial begin
        led_display_data = {90'b0, 15'b111111111111111};
    end
    
    // Map module pins to physical GPIO pins
    assign CHRLY_1 = charlieplex_pins[0];
    assign CHRLY_2 = charlieplex_pins[1];
    assign CHRLY_3 = charlieplex_pins[2];
    assign CHRLY_4 = charlieplex_pins[3];
    assign CHRLY_5 = charlieplex_pins[4];
    assign CHRLY_6 = charlieplex_pins[5];
    assign CHRLY_7 = charlieplex_pins[6];
    assign CHRLY_8 = charlieplex_pins[7];
    assign CHRLY_9 = charlieplex_pins[8];
    assign CHRLY_10 = charlieplex_pins[9];
    assign CHRLY_11 = charlieplex_pins[10];
    
    // Map module OE signals to physical GPIO OE pins
    assign CHRLY_1_OE = charlieplex_oe[0];
    assign CHRLY_2_OE = charlieplex_oe[1];
    assign CHRLY_3_OE = charlieplex_oe[2];
    assign CHRLY_4_OE = charlieplex_oe[3];
    assign CHRLY_5_OE = charlieplex_oe[4];
    assign CHRLY_6_OE = charlieplex_oe[5];
    assign CHRLY_7_OE = charlieplex_oe[6];
    assign CHRLY_8_OE = charlieplex_oe[7];
    assign CHRLY_9_OE = charlieplex_oe[8];
    assign CHRLY_10_OE = charlieplex_oe[9];
    assign CHRLY_11_OE = charlieplex_oe[10];
    
    charlieplex_11pin #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .REFRESH_RATE(100)  // 100Hz refresh rate for full display
    ) charlie_inst (
        .clk(CLK),
        .led_data(led_display_data),
        .pins(charlieplex_pins),
        .pins_oe(charlieplex_oe)
    );

endmodule


module charlieplex_11pin
    #(
        parameter CLK_FREQUENCY = 50E6,
        parameter REFRESH_RATE = 100  // Hz - full frame refresh rate
    )
    (
        input wire clk,
        input wire [104:0] led_data,  // 105 LEDs (0-104)
        output reg [10:0] pins,       // 11 control pins (data)
        output reg [10:0] pins_oe     // 11 Output Enable pins (1=output, 0=input/Hi-Z)
    );
    
    localparam NUM_LEDS = 105;
    localparam NUM_PINS = 11;
    
    // Calculate timing for LED multiplexing
    // Each LED gets lit for a brief time, cycling through all 105
    localparam LED_TIMER_MAX = $rtoi(CLK_FREQUENCY / (REFRESH_RATE * NUM_LEDS));
    
    reg [$clog2(LED_TIMER_MAX)-1:0] led_timer = 0;
    reg [6:0] current_led = 0;  // 0 to 104
    
    // LED multiplexing counter
    always @(posedge clk) begin
        if (led_timer < LED_TIMER_MAX - 1)
            led_timer <= led_timer + 1;
        else begin
            led_timer <= 0;
            if (current_led < NUM_LEDS - 1)
                current_led <= current_led + 1;
            else
                current_led <= 0;
        end
    end
    
    // Charlieplex control logic
    // Determines which pins are HIGH (anode), LOW (cathode), or Hi-Z
    always @(posedge clk) begin
        // Default: all pins tri-state (OE=0)
        pins_oe <= 11'h0;
        pins <= 11'h0;
        
        // Only configure pins if the current LED should be lit
        if (led_data[current_led]) begin
            case (current_led)
                // LEDs 0-9: Anode on pins 1-10, Cathode on pin 0
                0: begin pins_oe <= 11'b00000000011; pins <= 11'b00000000010; end  // LED1:  Pin1=H, Pin0=L
                1: begin pins_oe <= 11'b00000000101; pins <= 11'b00000000100; end  // LED2:  Pin2=H, Pin0=L
                2: begin pins_oe <= 11'b00000001001; pins <= 11'b00000001000; end  // LED3:  Pin3=H, Pin0=L
                3: begin pins_oe <= 11'b00000010001; pins <= 11'b00000010000; end  // LED4:  Pin4=H, Pin0=L
                4: begin pins_oe <= 11'b00000100001; pins <= 11'b00000100000; end  // LED5:  Pin5=H, Pin0=L
                5: begin pins_oe <= 11'b00001000001; pins <= 11'b00001000000; end  // LED6:  Pin6=H, Pin0=L
                6: begin pins_oe <= 11'b00010000001; pins <= 11'b00010000000; end  // LED7:  Pin7=H, Pin0=L
                7: begin pins_oe <= 11'b00100000001; pins <= 11'b00100000000; end  // LED8:  Pin8=H, Pin0=L
                8: begin pins_oe <= 11'b01000000001; pins <= 11'b01000000000; end  // LED9:  Pin9=H, Pin0=L
                9: begin pins_oe <= 11'b10000000001; pins <= 11'b10000000000; end  // LED10: Pin10=H, Pin0=L
                
                // LEDs 10-18: Various anodes, Cathode on pin 1
                10: begin pins_oe <= 11'b00000000011; pins <= 11'b00000000001; end // LED11: Pin0=H, Pin1=L
                11: begin pins_oe <= 11'b00000000110; pins <= 11'b00000000100; end // LED12: Pin2=H, Pin1=L
                12: begin pins_oe <= 11'b00000001010; pins <= 11'b00000001000; end // LED13: Pin3=H, Pin1=L
                13: begin pins_oe <= 11'b00000010010; pins <= 11'b00000010000; end // LED14: Pin4=H, Pin1=L
                14: begin pins_oe <= 11'b00000100010; pins <= 11'b00000100000; end // LED15: Pin5=H, Pin1=L
                15: begin pins_oe <= 11'b00001000010; pins <= 11'b00001000000; end // LED16: Pin6=H, Pin1=L
                16: begin pins_oe <= 11'b00010000010; pins <= 11'b00010000000; end // LED17: Pin7=H, Pin1=L
                17: begin pins_oe <= 11'b00100000010; pins <= 11'b00100000000; end // LED18: Pin8=H, Pin1=L
                18: begin pins_oe <= 11'b01000000010; pins <= 11'b01000000000; end // LED19: Pin9=H, Pin1=L
                19: begin pins_oe <= 11'b10000000010; pins <= 11'b10000000000; end // LED20: Pin10=H, Pin1=L
                
                // LEDs 20-28: Cathode on pin 2
                20: begin pins_oe <= 11'b00000000101; pins <= 11'b00000000001; end // LED21: Pin0=H, Pin2=L
                21: begin pins_oe <= 11'b00000000110; pins <= 11'b00000000010; end // LED22: Pin1=H, Pin2=L
                22: begin pins_oe <= 11'b00000001100; pins <= 11'b00000001000; end // LED23: Pin3=H, Pin2=L
                23: begin pins_oe <= 11'b00000010100; pins <= 11'b00000010000; end // LED24: Pin4=H, Pin2=L
                24: begin pins_oe <= 11'b00000100100; pins <= 11'b00000100000; end // LED25: Pin5=H, Pin2=L
                25: begin pins_oe <= 11'b00001000100; pins <= 11'b00001000000; end // LED26: Pin6=H, Pin2=L
                26: begin pins_oe <= 11'b00010000100; pins <= 11'b00010000000; end // LED27: Pin7=H, Pin2=L
                27: begin pins_oe <= 11'b00100000100; pins <= 11'b00100000000; end // LED28: Pin8=H, Pin2=L
                28: begin pins_oe <= 11'b01000000100; pins <= 11'b01000000000; end // LED29: Pin9=H, Pin2=L
                29: begin pins_oe <= 11'b10000000100; pins <= 11'b10000000000; end // LED30: Pin10=H, Pin2=L
                
                // LEDs 30-38: Cathode on pin 3
                30: begin pins_oe <= 11'b00000001001; pins <= 11'b00000000001; end // LED31: Pin0=H, Pin3=L
                31: begin pins_oe <= 11'b00000001010; pins <= 11'b00000000010; end // LED32: Pin1=H, Pin3=L
                32: begin pins_oe <= 11'b00000001100; pins <= 11'b00000000100; end // LED33: Pin2=H, Pin3=L
                33: begin pins_oe <= 11'b00000011000; pins <= 11'b00000010000; end // LED34: Pin4=H, Pin3=L
                34: begin pins_oe <= 11'b00000101000; pins <= 11'b00000100000; end // LED35: Pin5=H, Pin3=L
                35: begin pins_oe <= 11'b00001001000; pins <= 11'b00001000000; end // LED36: Pin6=H, Pin3=L
                36: begin pins_oe <= 11'b00010001000; pins <= 11'b00010000000; end // LED37: Pin7=H, Pin3=L
                37: begin pins_oe <= 11'b00100001000; pins <= 11'b00100000000; end // LED38: Pin8=H, Pin3=L
                38: begin pins_oe <= 11'b01000001000; pins <= 11'b01000000000; end // LED39: Pin9=H, Pin3=L
                39: begin pins_oe <= 11'b10000001000; pins <= 11'b10000000000; end // LED40: Pin10=H, Pin3=L
                
                // LEDs 40-48: Cathode on pin 4
                40: begin pins_oe <= 11'b00000010001; pins <= 11'b00000000001; end // LED41: Pin0=H, Pin4=L
                41: begin pins_oe <= 11'b00000010010; pins <= 11'b00000000010; end // LED42: Pin1=H, Pin4=L
                42: begin pins_oe <= 11'b00000010100; pins <= 11'b00000000100; end // LED43: Pin2=H, Pin4=L
                43: begin pins_oe <= 11'b00000011000; pins <= 11'b00000001000; end // LED44: Pin3=H, Pin4=L
                44: begin pins_oe <= 11'b00000110000; pins <= 11'b00000100000; end // LED45: Pin5=H, Pin4=L
                45: begin pins_oe <= 11'b00001010000; pins <= 11'b00001000000; end // LED46: Pin6=H, Pin4=L
                46: begin pins_oe <= 11'b00010010000; pins <= 11'b00010000000; end // LED47: Pin7=H, Pin4=L
                47: begin pins_oe <= 11'b00100010000; pins <= 11'b00100000000; end // LED48: Pin8=H, Pin4=L
                48: begin pins_oe <= 11'b01000010000; pins <= 11'b01000000000; end // LED49: Pin9=H, Pin4=L
                49: begin pins_oe <= 11'b10000010000; pins <= 11'b10000000000; end // LED50: Pin10=H, Pin4=L
                
                // LEDs 50-58: Cathode on pin 5
                50: begin pins_oe <= 11'b00000100001; pins <= 11'b00000000001; end // LED51: Pin0=H, Pin5=L
                51: begin pins_oe <= 11'b00000100010; pins <= 11'b00000000010; end // LED52: Pin1=H, Pin5=L
                52: begin pins_oe <= 11'b00000100100; pins <= 11'b00000000100; end // LED53: Pin2=H, Pin5=L
                53: begin pins_oe <= 11'b00000101000; pins <= 11'b00000001000; end // LED54: Pin3=H, Pin5=L
                54: begin pins_oe <= 11'b00000110000; pins <= 11'b00000010000; end // LED55: Pin4=H, Pin5=L
                55: begin pins_oe <= 11'b00001100000; pins <= 11'b00001000000; end // LED56: Pin6=H, Pin5=L
                56: begin pins_oe <= 11'b00010100000; pins <= 11'b00010000000; end // LED57: Pin7=H, Pin5=L
                57: begin pins_oe <= 11'b00100100000; pins <= 11'b00100000000; end // LED58: Pin8=H, Pin5=L
                58: begin pins_oe <= 11'b01000100000; pins <= 11'b01000000000; end // LED59: Pin9=H, Pin5=L
                59: begin pins_oe <= 11'b10000100000; pins <= 11'b10000000000; end // LED60: Pin10=H, Pin5=L
                
                // LEDs 60-68: Cathode on pin 6
                60: begin pins_oe <= 11'b00001000001; pins <= 11'b00000000001; end // LED61: Pin0=H, Pin6=L
                61: begin pins_oe <= 11'b00001000010; pins <= 11'b00000000010; end // LED62: Pin1=H, Pin6=L
                62: begin pins_oe <= 11'b00001000100; pins <= 11'b00000000100; end // LED63: Pin2=H, Pin6=L
                63: begin pins_oe <= 11'b00001001000; pins <= 11'b00000001000; end // LED64: Pin3=H, Pin6=L
                64: begin pins_oe <= 11'b00001010000; pins <= 11'b00000010000; end // LED65: Pin4=H, Pin6=L
                65: begin pins_oe <= 11'b00001100000; pins <= 11'b00000100000; end // LED66: Pin5=H, Pin6=L
                66: begin pins_oe <= 11'b00011000000; pins <= 11'b00010000000; end // LED67: Pin7=H, Pin6=L
                67: begin pins_oe <= 11'b00101000000; pins <= 11'b00100000000; end // LED68: Pin8=H, Pin6=L
                68: begin pins_oe <= 11'b01001000000; pins <= 11'b01000000000; end // LED69: Pin9=H, Pin6=L
                69: begin pins_oe <= 11'b10001000000; pins <= 11'b10000000000; end // LED70: Pin10=H, Pin6=L
                
                // LEDs 70-78: Cathode on pin 7
                70: begin pins_oe <= 11'b00010000001; pins <= 11'b00000000001; end // LED71: Pin0=H, Pin7=L
                71: begin pins_oe <= 11'b00010000010; pins <= 11'b00000000010; end // LED72: Pin1=H, Pin7=L
                72: begin pins_oe <= 11'b00010000100; pins <= 11'b00000000100; end // LED73: Pin2=H, Pin7=L
                73: begin pins_oe <= 11'b00010001000; pins <= 11'b00000001000; end // LED74: Pin3=H, Pin7=L
                74: begin pins_oe <= 11'b00010010000; pins <= 11'b00000010000; end // LED75: Pin4=H, Pin7=L
                75: begin pins_oe <= 11'b00010100000; pins <= 11'b00000100000; end // LED76: Pin5=H, Pin7=L
                76: begin pins_oe <= 11'b00011000000; pins <= 11'b00001000000; end // LED77: Pin6=H, Pin7=L
                77: begin pins_oe <= 11'b00110000000; pins <= 11'b00100000000; end // LED78: Pin8=H, Pin7=L
                78: begin pins_oe <= 11'b01010000000; pins <= 11'b01000000000; end // LED79: Pin9=H, Pin7=L
                79: begin pins_oe <= 11'b10010000000; pins <= 11'b10000000000; end // LED80: Pin10=H, Pin7=L
                
                // LEDs 80-88: Cathode on pin 8
                80: begin pins_oe <= 11'b00100000001; pins <= 11'b00000000001; end // LED81: Pin0=H, Pin8=L
                81: begin pins_oe <= 11'b00100000010; pins <= 11'b00000000010; end // LED82: Pin1=H, Pin8=L
                82: begin pins_oe <= 11'b00100000100; pins <= 11'b00000000100; end // LED83: Pin2=H, Pin8=L
                83: begin pins_oe <= 11'b00100001000; pins <= 11'b00000001000; end // LED84: Pin3=H, Pin8=L
                84: begin pins_oe <= 11'b00100010000; pins <= 11'b00000010000; end // LED85: Pin4=H, Pin8=L
                85: begin pins_oe <= 11'b00100100000; pins <= 11'b00000100000; end // LED86: Pin5=H, Pin8=L
                86: begin pins_oe <= 11'b00101000000; pins <= 11'b00001000000; end // LED87: Pin6=H, Pin8=L
                87: begin pins_oe <= 11'b00110000000; pins <= 11'b00010000000; end // LED88: Pin7=H, Pin8=L
                88: begin pins_oe <= 11'b01100000000; pins <= 11'b01000000000; end // LED89: Pin9=H, Pin8=L
                89: begin pins_oe <= 11'b10100000000; pins <= 11'b10000000000; end // LED90: Pin10=H, Pin8=L
                
                // LEDs 90-98: Cathode on pin 9
                90: begin pins_oe <= 11'b01000000001; pins <= 11'b00000000001; end // LED91: Pin0=H, Pin9=L
                91: begin pins_oe <= 11'b01000000010; pins <= 11'b00000000010; end // LED92: Pin1=H, Pin9=L
                92: begin pins_oe <= 11'b01000000100; pins <= 11'b00000000100; end // LED93: Pin2=H, Pin9=L
                93: begin pins_oe <= 11'b01000001000; pins <= 11'b00000001000; end // LED94: Pin3=H, Pin9=L
                94: begin pins_oe <= 11'b01000010000; pins <= 11'b00000010000; end // LED95: Pin4=H, Pin9=L
                95: begin pins_oe <= 11'b01000100000; pins <= 11'b00000100000; end // LED96: Pin5=H, Pin9=L
                96: begin pins_oe <= 11'b01001000000; pins <= 11'b00001000000; end // LED97: Pin6=H, Pin9=L
                97: begin pins_oe <= 11'b01010000000; pins <= 11'b00010000000; end // LED98: Pin7=H, Pin9=L
                98: begin pins_oe <= 11'b01100000000; pins <= 11'b00100000000; end // LED99: Pin8=H, Pin9=L
                99: begin pins_oe <= 11'b11000000000; pins <= 11'b10000000000; end // LED100: Pin10=H, Pin9=L
                
                // LEDs 100-104: Cathode on pin 10
                100: begin pins_oe <= 11'b10000000001; pins <= 11'b00000000001; end // LED101: Pin0=H, Pin10=L
                101: begin pins_oe <= 11'b10000000010; pins <= 11'b00000000010; end // LED102: Pin1=H, Pin10=L
                102: begin pins_oe <= 11'b10000000100; pins <= 11'b00000000100; end // LED103: Pin2=H, Pin10=L
                103: begin pins_oe <= 11'b10000001000; pins <= 11'b00000001000; end // LED104: Pin3=H, Pin10=L
                104: begin pins_oe <= 11'b10000010000; pins <= 11'b00000010000; end // LED105: Pin4=H, Pin10=L
                
                default: begin
                    pins_oe <= 11'h0;
                    pins <= 11'h0;
                end
            endcase
        end
    end

endmodule