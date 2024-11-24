module wack_a_mole(
    input wire clk,             // Clock input
    input wire reset,           // Reset switch
    input wire [8:0] switches,  // 9 switches for whacking moles
    output reg [8:0] leds,      // 9 LEDs representing holes
    output reg [6:0] seg,       // 7-segment display for score
    output reg game_over        // Signal to indicate the game is paused
);

    // Internal signals
    reg [25:0] counter;         // 26-bit counter for clock divider (1 second)
    reg one_sec_pulse;          // 1-second pulse signal
    reg [3:0] mole_pos;         // Mole position (0 to 8)
    reg [3:0] score;            // Player score (0 to 9)
    reg [4:0] time_counter;     // Time counter to track 30 seconds
	 reg [1:0] res_count;
    // LFSR-based random number generator for mole position
    reg [3:0] lfsr;             // 4-bit LFSR
    wire feedback;              // Feedback bit for LFSR

	 
	 initial begin
	 res_count = 2'd00;
	 end
    // Clock Divider to generate 1-second pulse
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            one_sec_pulse <= 0;
				res_count = res_count + 1;
        end else if (counter == 50000000) begin // Assuming a 50MHz clock
            one_sec_pulse <= 1;
            counter <= 0;
        end else begin
            one_sec_pulse <= 0;
            counter <= counter + 1;
        end
    end

    // Time Counter (Track time for 30 seconds)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            time_counter <= 0;  // Reset time
        end else if (one_sec_pulse && time_counter < 30) begin
            time_counter <= time_counter + 1;
        end	`																																			`1`11`1``	7
    end

    // LFSR logic for random mole position generation
    assign feedback = lfsr[3] ^ lfsr[2]; // Feedback function using XOR

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= 4'b1010 + res_count;  // Seed the LFSR with a non-zero value
        end else if (one_sec_pulse && !game_over) begin
            lfsr <= {lfsr[2:0], feedback};  // Shift the LFSR
        end
    end

    // Map the LFSR value to mole positions (0 to 8)
    always @(*) begin
        mole_pos = lfsr % 9;  // Map LFSR output to range 0 to 8
    end

    // LED Control (One LED on based on mole position)
    always @(*) begin
        leds = 9'b000000000;     // Turn off all LEDs by default
        leds[mole_pos] = 1;      // Turn on the LED corresponding to the mole position
    end

    // Score Counter (Check if the correct switch is pressed once per second)
    reg prev_switch;            // Stores the previous state of the switch for debounce

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            score <= 0;           // Reset score
            prev_switch <= 0;
        end else if (one_sec_pulse && switches[mole_pos] && !game_over && !prev_switch) begin
            // Increment score once per second when the correct switch is pressed and game is not over
            if (score < 9)        
                score <= score + 1;
            prev_switch <= 1;     // Set prev_switch to prevent repeated scoring within the same second
        end else if (!switches[mole_pos]) begin
            prev_switch <= 0;     // Reset prev_switch if the correct switch is released
        end
    end

    // Game Over Logic (Stop game when score reaches 9 or time exceeds 30 seconds)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            game_over <= 0;       // Reset game state
        end else if (score == 9 || time_counter >= 30) begin
            game_over <= 1;       // Pause game if score reaches 9 or time exceeds 30 seconds
        end
    end

    // 7-Segment Display for Score
    always @(*) begin
        case(score)
            4'd0: seg = 7'b1000000;  // Display 0
            4'd1: seg = 7'b1111001;  // Display 1
            4'd2: seg = 7'b0100100;  // Display 2
            4'd3: seg = 7'b0110000;  // Display 3
            4'd4: seg = 7'b0011001;  // Display 4
            4'd5: seg = 7'b0010010;  // Display 5
            4'd6: seg = 7'b0000010;  // Display 6
            4'd7: seg = 7'b1111000;  // Display 7
            4'd8: seg = 7'b0000000;  // Display 8
            4'd9: seg = 7'b0010000;  // Display 9
            default: seg = 7'b1111111; // Blank display for invalid numbers
        endcase
    end

endmodule
