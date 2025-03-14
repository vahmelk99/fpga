// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [2:0] gpio
);
    // logic random;
    // always_comb
    //     case (countdown[0])
    //     1: random = 3;
    //     0: random = 2;
    //     endcase
    //------------------------------------------------------------------------
    //
    //  Screen, object and color constants

    localparam screen_width  = 480,
               screen_height = 272,

               wx            = 5,
               wy            = 100,
               min_wy        = 50,
               br            = 14,
               d_speed       = 1,
               start_speed   = 1,
               max_speed     = 4, 
               start_0_x     = 7,
               start_0_y     = screen_height     / 2 - wy / 2,
               
               start_1_x     = screen_width - 7 - wx,
               start_1_y     = screen_height     / 2 - wy / 2,

               start_b_x     = screen_width / 2 - br / 2,
               start_b_y     = screen_height / 2 - br / 2,

               help_r        = 20,
               help_x_start  = screen_width / 2 - help_r / 2, 
               help_y_start  = screen_height / 2 - help_r / 2,

               max_red       = 31,
               max_green     = 63,
               max_blue      = 31;

    //------------------------------------------------------------------------
    //
    //  Pulse generator, 50 times a second


    logic enable;

    strobe_gen # (.clk_mhz (27), .strobe_hz (100))
    i_strobe_gen (clock, reset, enable);
    //------------------------------------------------------------------------
    //
    //  Finite State Machine (FSM) for the game

    localparam [2:0]
        STATE_START = 0,
        STATE_AIM   = 1,
        STATE_SHOOT = 2,
        STATE_WON   = 3,
        STATE_LOST  = 4;

    logic [2:0] state, new_state;

    //------------------------------------------------------------------------

    // Conditions to change the state - declarations

    logic out_of_screen_2, out_of_screen_1, launch, timeout;

    //------------------------------------------------------------------------

    always_comb
    begin
        new_state = state;

        case (state)

        STATE_START : new_state =                   STATE_AIM;

        STATE_AIM   : new_state =   out_of_screen_2 ? STATE_LOST
                                  : out_of_screen_1 ? STATE_WON
                                  : launch          ? STATE_SHOOT
                                  :                   STATE_AIM;

        STATE_SHOOT : new_state =   out_of_screen_2 ? STATE_LOST
                                  : out_of_screen_1 ? STATE_WON
                                  :                   STATE_SHOOT;

        STATE_WON   : new_state =   timeout       ? STATE_START
                                  :                 STATE_WON;

        STATE_LOST  : new_state =   timeout       ? STATE_START
                                  :                 STATE_LOST;

        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clock)
        if (reset)
            state <= STATE_START;
        else if (enable)
            state <= new_state;

    //------------------------------------------------------------------------
    //
    //  Computing new object coordinates
    logic [8:0] x0,  y0,  x1,  y1,
                x0r, y0r, x1r, y1r,
                xb,  yb,  xbr, ybr,
                s1,  s2,  bdx, bdy, 
                dir_y, dir_x, paddle_height, 
                hardness, hardness_counter;

    wire left0  = key [7];
    wire right0 = key [5];

    wire left1  = key [2];
    wire right1 = key [0];

    always_comb
    begin
        x0 = x0r;
        y0 = y0r;
        x1 = x1r;
        y1 = y1r;

        if (state == STATE_START)
        begin
            x0 = start_0_x;
            y0 = start_0_y;
            x1 = start_1_x;
            y1 = start_1_y;
        end
        else
        begin
            // x0 = x0 + 1;

            if (state == STATE_SHOOT)
            begin
                if (y1 + right1 * bdy - left1 * bdy < screen_height - paddle_height & y1 + right1 * bdy - left1 * bdy > 0 )
                    y1 = y1 + right1 * bdy - left1 * bdy;
                if (y0 + right0 * bdy - left0 * bdy < screen_height - paddle_height & y0 + right0 * bdy - left0 * bdy > 0 )
                    y0 = y0 + right0 * bdy - left0 * bdy;

            end
        end
    end

    //------------------------------------------------------------------------
    //
    //  Updating object coordinates

    always_ff @ (posedge clock)
        if (reset)
        begin
            x0r <= 0;
            y0r <= 0;
            x1r <= 0;
            y1r <= 0;
            xbr <= 0;
            ybr <= 0;
            s1  <= 0;
            s2  <= 0;
            dir_y <= 1;
            dir_x <= 1;
            bdy <= start_speed;
            bdx <= start_speed;
            xb <= start_b_x;
            yb <= start_b_y;
            paddle_height <= wy;
            hardness_counter <= 0;
            hardness <= 0;
        end
        else if (enable)
        begin
            x0r <= x0;
            y0r <= y0;
            x1r <= x1;
            y1r <= y1;
            xbr <= xb;
            ybr <= yb;
            if (state == STATE_START | state == STATE_LOST | state == STATE_WON)
            begin
                xb <= start_b_x;
                yb <= start_b_y;
                bdy <= start_speed;
                bdx <= start_speed;
                hardness_counter <= 0;
                hardness <= 0;
                paddle_height <= wy;
            end
            else if (state == STATE_SHOOT)
            begin
                if (countdown[8:0] == '0)
                begin 
                    if(paddle_height - (wy - min_wy) / 8 > min_wy)
                        paddle_height <= paddle_height - (wy - min_wy) / 8;
                    hardness <= hardness + 2 ** hardness_counter;
                    hardness_counter <= hardness_counter + 1;
                    if(hardness_counter == 4 | hardness_counter == 8)
                    begin
                    if(bdy + d_speed < max_speed)
                        bdy = bdy + d_speed;
                    end
                end
                else if (countdown[5:0] == '0)
                begin
                    
                end
                if (yb + br >= screen_height )  
                    dir_y = 0; 
                if (yb - bdy <= 0) 
                    dir_y = 1; 
                yb <= dir_y ? yb + bdy : yb - bdy;
                // paddle hit
                if (y1 < yb & yb < y1 + paddle_height & xb + br >= x1 & xb + br < screen_width) 
                    dir_x = 0; 
                if (y0 < yb & yb < y0 + paddle_height & xb <= x0 + wx & xb > 0) 
                    dir_x = 1; 
                xb <= dir_x ? xb + bdx : xb - bdx;
                if (xb + br >= screen_width )  
                    dir_x = 0; 
                if (xb - bdx <= 0) 
                    dir_x = 1; 
            end
            if (xb + br >= screen_width & state != STATE_LOST & state != STATE_WON)
                s1 <= s1 + 1;
            if (xb <= 0 & state != STATE_LOST & state != STATE_WON)
                s2 <= s2 + 1;

        end

    //------------------------------------------------------------------------
    //
    // Conditions to change the state - implementations

    assign out_of_screen_1 = xb + br >= screen_width;
    assign out_of_screen_2 = xb <= 0;
    assign launch = key[1] & key[6];

    //------------------------------------------------------------------------
    //
    // Timeout condition

    logic [7:0] timer;
    logic [32:0] countdown;

    always_ff @ (posedge clock)
        if (reset)
        begin
            timer <= 0;
            countdown <= 2**32 - 1;
        end
        else if (state == STATE_START)
        begin
            timer <= 0;
            countdown <= 2**32 - 1;
        end
        else if (state == STATE_SHOOT)
        begin
            timer <= 100;
            if (enable)
                countdown <= countdown - 1;
        end
        else if (enable)
        begin
            timer <= timer - 1;
            // countdown <= countdown - 1;
        end

        // if (reset)
        // else if (state == STATE_START) 
        //     countdown <= 255;
        // else (enable)
        //     countdown <= countdown - 1;


    assign timeout = (timer == 0);

    //------------------------------------------------------------------------
    //
    //  Determine pixel color

    //------------------------------------------------------------------------

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        // verilator lint_off CASEINCOMPLETE

        case (state)

        STATE_WON:
        begin
                blue = max_blue;
                red = max_red;
        end

        STATE_LOST:
        begin
            red = max_red;
            green = max_green;
        end

        default:
        begin
            if (  x >= x0 & x < x0 + wx
                & y >= y0 & y < y0 + paddle_height)
            begin
                blue = max_blue;
                red = max_red;
            end

            if (  x >= x1 & x < x1 + wx
                & y >= y1 & y < y1 + paddle_height)
            begin
                red = max_red;
                green = max_green;
            end

            if ( (x - xb - br / 2) ** 2 + (y - yb - br / 2) ** 2 < (br / 2) ** 2 )
            begin
                if(hardness_counter <= 4)
                begin
                    red = max_red;
                    green = max_green;
                    blue = max_blue;
                end
                else if(hardness_counter <= 8)
                begin
                    blue = max_blue;
                end
                else
                begin
                    red = max_red;
                end
            end
        end

        endcase

        // verilator lint_on CASEINCOMPLETE
    end

    //------------------------------------------------------------------------
    //
    //  Output to LED and 7-segment display

    assign led = hardness;

    wire [31:0] number = { 7'b0, s1, 7'b0, s2 };
    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock    ),
        .rst      ( reset    ),
        .number   ( number   ),
        .dots     ( '0       ),  // This syntax means "all 0s in the context"
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

endmodule
