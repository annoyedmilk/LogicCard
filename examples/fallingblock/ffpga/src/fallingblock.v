// ================================================================
//  DODGE - Falling Objects Game for forgeFPGA
//  15x7 LED Matrix + 4 Buttons
//  Player (bottom) dodges falling bars (5-wide)
//  BTN1=LEFT, BTN4=RIGHT, BTN2/BTN3=Restart when game over
//  Optimized for 140 CLBs
// ================================================================

(* top *)
module fallingblock #(
    parameter IN_CLK_HZ  = 50_000_000,
    parameter REFRESH_HZ = 1_000
) (
    (* iopad_external_pin *)
    input nreset,
    (* iopad_external_pin, clkbuf_inhibit *)
    input clk,
    (* iopad_external_pin *)
    output osc_en,

    // Button inputs
    (* iopad_external_pin *) input BTN1,  // Left
    (* iopad_external_pin *) input BTN2,  // Restart
    (* iopad_external_pin *) input BTN3,  // Restart
    (* iopad_external_pin *) input BTN4,  // Right

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

    // ============================================================
    // Clock divider
    // ============================================================
    reg [22:0] slow_cnt;
    wire game_tick = (slow_cnt == 0);
    wire blink = slow_cnt[19];

    always @(posedge clk) begin
        if (!nreset)
            slow_cnt <= 0;
        else
            slow_cnt <= (slow_cnt >= 8_333_333 - 1) ? 0 : slow_cnt + 1;
    end

    // ============================================================
    // Button sync and edge detect
    // ============================================================
    reg [3:0] btn_sync0, btn_sync1, btn_prev;
    wire [3:0] btn_press = btn_sync1 & ~btn_prev;

    always @(posedge clk) begin
        if (!nreset) begin
            btn_sync0 <= 0;
            btn_sync1 <= 0;
            btn_prev  <= 0;
        end else begin
            btn_sync0 <= {BTN4, BTN3, BTN2, BTN1};
            btn_sync1 <= btn_sync0;
            if (game_tick)
                btn_prev <= btn_sync1;
        end
    end

    wire btn_left    = btn_press[0];
    wire btn_restart = btn_press[1] | btn_press[2];
    wire btn_right   = btn_press[3];

    // ============================================================
    // LFSR for random spawning
    // ============================================================
    reg [10:0] lfsr;
    wire lfsr_fb = lfsr[10] ^ lfsr[8];

    always @(posedge clk) begin
        if (!nreset)
            lfsr <= 11'b10101100111;
        else
            lfsr <= {lfsr[9:0], lfsr_fb};
    end

    wire [3:0] rand_x = (lfsr[3:0] < 4'd13) ? lfsr[3:0] + 4'd1 : 4'd7;

    // ============================================================
    // Game state - 3 falling objects
    // ============================================================
    localparam PLAYER_Y = 6;

    reg [3:0] player_x;
    reg game_over;

    reg [3:0] obj0_x, obj1_x, obj2_x;
    reg [2:0] obj0_y, obj1_y, obj2_y;
    reg obj0_active, obj1_active, obj2_active;

    reg [2:0] spawn_timer;

    // ============================================================
    // LED Scanner
    // ============================================================
    localparam LED_COUNT = 105;
    localparam CNT_MAX = IN_CLK_HZ / (REFRESH_HZ * LED_COUNT) - 1;

    reg [8:0] scan_cnt;
    reg [6:0] led_index;

    always @(posedge clk) begin
        if (!nreset) begin
            scan_cnt  <= 0;
            led_index <= 0;
        end else begin
            if (scan_cnt >= CNT_MAX) begin
                scan_cnt  <= 0;
                led_index <= (led_index >= LED_COUNT - 1) ? 0 : led_index + 1;
            end else begin
                scan_cnt <= scan_cnt + 1;
            end
        end
    end

    // ============================================================
    // LED index to X,Y
    // ============================================================
    reg [3:0] query_x;
    reg [2:0] query_y;

    always @(*) begin
        if (led_index < 15)       begin query_y = 0; query_x = led_index[3:0]; end
        else if (led_index < 30)  begin query_y = 1; query_x = led_index - 15; end
        else if (led_index < 45)  begin query_y = 2; query_x = led_index - 30; end
        else if (led_index < 60)  begin query_y = 3; query_x = led_index - 45; end
        else if (led_index < 75)  begin query_y = 4; query_x = led_index - 60; end
        else if (led_index < 90)  begin query_y = 5; query_x = led_index - 75; end
        else                      begin query_y = 6; query_x = led_index - 90; end
    end

    // ============================================================
    // Bar hit detection (shared for display and collision)
    // 5-wide bar: check if x is within range [obj_x-2, obj_x+2]
    // ============================================================
    wire in_bar0 = obj0_active && (query_x + 2 >= obj0_x) && (query_x <= obj0_x + 2);
    wire in_bar1 = obj1_active && (query_x + 2 >= obj1_x) && (query_x <= obj1_x + 2);
    wire in_bar2 = obj2_active && (query_x + 2 >= obj2_x) && (query_x <= obj2_x + 2);

    wire is_obj0 = in_bar0 && (query_y == obj0_y);
    wire is_obj1 = in_bar1 && (query_y == obj1_y);
    wire is_obj2 = in_bar2 && (query_y == obj2_y);

    // Collision: player hit by bar at bottom row
    wire hit0 = obj0_active && (obj0_y == PLAYER_Y) && (player_x + 2 >= obj0_x) && (player_x <= obj0_x + 2);
    wire hit1 = obj1_active && (obj1_y == PLAYER_Y) && (player_x + 2 >= obj1_x) && (player_x <= obj1_x + 2);
    wire hit2 = obj2_active && (obj2_y == PLAYER_Y) && (player_x + 2 >= obj2_x) && (player_x <= obj2_x + 2);
    wire collision = hit0 | hit1 | hit2;

    // ============================================================
    // Game logic
    // ============================================================
    always @(posedge clk) begin
        if (!nreset) begin
            player_x <= 7;
            game_over <= 0;
            obj0_active <= 0; obj1_active <= 0; obj2_active <= 0;
            obj0_x <= 0; obj0_y <= 0;
            obj1_x <= 0; obj1_y <= 0;
            obj2_x <= 0; obj2_y <= 0;
            spawn_timer <= 0;
        end else if (game_tick) begin
            if (game_over) begin
                if (btn_restart || btn_left || btn_right) begin
                    player_x <= 7;
                    game_over <= 0;
                    obj0_active <= 0; obj1_active <= 0; obj2_active <= 0;
                    spawn_timer <= 0;
                end
            end else begin
                if (collision) begin
                    game_over <= 1;
                end else begin
                    // Move player
                    if (btn_left && player_x > 0)
                        player_x <= player_x - 1;
                    if (btn_right && player_x < 14)
                        player_x <= player_x + 1;

                    // Update falling objects
                    if (obj0_active) begin
                        if (obj0_y >= 6) obj0_active <= 0;
                        else obj0_y <= obj0_y + 1;
                    end
                    if (obj1_active) begin
                        if (obj1_y >= 6) obj1_active <= 0;
                        else obj1_y <= obj1_y + 1;
                    end
                    if (obj2_active) begin
                        if (obj2_y >= 6) obj2_active <= 0;
                        else obj2_y <= obj2_y + 1;
                    end

                    // Spawn new objects
                    spawn_timer <= spawn_timer + 1;
                    if (spawn_timer == 0) begin
                        if (!obj0_active) begin
                            obj0_active <= 1; obj0_x <= rand_x; obj0_y <= 0;
                        end else if (!obj1_active) begin
                            obj1_active <= 1; obj1_x <= rand_x; obj1_y <= 0;
                        end else if (!obj2_active) begin
                            obj2_active <= 1; obj2_x <= rand_x; obj2_y <= 0;
                        end
                    end
                end
            end
        end
    end

    // ============================================================
    // LED output logic
    // ============================================================
    wire is_player = (query_x == player_x) && (query_y == PLAYER_Y);
    wire is_object = is_obj0 | is_obj1 | is_obj2;
    wire led_on = game_over ? ((is_player | is_object) & blink) : (is_player | is_object);

    // ============================================================
    // Charlieplex pin mapping
    // ============================================================
    reg [3:0] cathode;
    reg [3:0] pos_in_group;
    reg [3:0] anode;

    always @(*) begin
        if (led_index < 10)       begin cathode = 0;  pos_in_group = led_index; end
        else if (led_index < 20)  begin cathode = 1;  pos_in_group = led_index - 10; end
        else if (led_index < 30)  begin cathode = 2;  pos_in_group = led_index - 20; end
        else if (led_index < 40)  begin cathode = 3;  pos_in_group = led_index - 30; end
        else if (led_index < 50)  begin cathode = 4;  pos_in_group = led_index - 40; end
        else if (led_index < 60)  begin cathode = 5;  pos_in_group = led_index - 50; end
        else if (led_index < 70)  begin cathode = 6;  pos_in_group = led_index - 60; end
        else if (led_index < 80)  begin cathode = 7;  pos_in_group = led_index - 70; end
        else if (led_index < 90)  begin cathode = 8;  pos_in_group = led_index - 80; end
        else if (led_index < 100) begin cathode = 9;  pos_in_group = led_index - 90; end
        else                      begin cathode = 10; pos_in_group = led_index - 100; end

        anode = (pos_in_group < cathode) ? pos_in_group : pos_in_group + 1;
    end

    // One-hot conversion
    reg [10:0] cathode_oh;
    reg [10:0] anode_oh;

    always @(*) begin
        cathode_oh = 11'b1 << cathode;
        anode_oh = 11'b1 << anode;
    end

    // Drive charlieplex outputs
    reg [10:0] oe_pins;
    reg [10:0] charlieplex_pins;

    always @(posedge clk) begin
        if (!nreset) begin
            oe_pins <= 11'b0;
            charlieplex_pins <= 11'b0;
        end else begin
            if (led_on) begin
                oe_pins <= cathode_oh | anode_oh;
                charlieplex_pins <= anode_oh;
            end else begin
                oe_pins <= 11'b0;
                charlieplex_pins <= 11'b0;
            end
        end
    end

    // Output assignments
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

endmodule
