-- test a larger screen with scrolling camera
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity player_test is
    port (
        clk, reset : std_logic;
        btn : std_logic_vector(3 downto 0);
        video_on : in std_logic;
        pixel_x, pixel_y : in std_logic_vector(9 downto 0);
        graph_rgb : out std_logic_vector(2 downto 0);
        sec_tick : out std_logic;
        col_led: out std_logic_vector(3 downto 0)
    );
end player_test;

architecture arch of player_test is
    -- 60 Hz and 1 Hz reference ticks
    signal refr_tick, gravity_tick, second_tick : std_logic;
    -- signals for different entities being shown
    signal wall_on, player_on : std_logic;
    -- pixel coordinates
    signal pix_x, pix_y : unsigned(10 downto 0);
    signal world_pix_x, world_pix_y : unsigned(10 downto 0);
    -- player signals
    signal player_x_reg, player_x_next : unsigned(10 downto 0) := to_unsigned(50, 11);
    signal player_y_reg, player_y_next : unsigned(10 downto 0) := to_unsigned(50, 11);
    -- x and y left, right, and middle
    signal player_x_l, player_x_r, player_x_m, player_y_t, player_y_b, player_y_m : unsigned(10 downto 0);
    -- movement flags
    signal moving_left, moving_right, on_ground, on_ceiling: std_logic;
    -- player delta regs
    signal player_x_delta_reg, player_x_delta_next : signed(10 downto 0);
    signal player_y_delta_reg, player_y_delta_next : signed(10 downto 0);
    -- camera signals
    signal cam_x, cam_y : unsigned(10 downto 0);
    -- world constants
    constant viewport_size_x_half : unsigned(10 downto 0) := to_unsigned(320, 11);
    constant viewport_size_y_half : unsigned(10 downto 0) := to_unsigned(240, 11);
    constant world_size_x : unsigned(10 downto 0) := to_unsigned(1280, 11);
    constant world_size_y : unsigned(10 downto 0) := to_unsigned(960, 11);
    constant cam_max_x : unsigned(10 downto 0) := to_unsigned(640, 11);
    constant cam_max_y : unsigned(10 downto 0) := to_unsigned(480, 11);
    constant player_size : unsigned(10 downto 0) := to_unsigned(32, 11);
 
    signal tile_x, tile_y : unsigned(5 downto 0);
    signal tile_row : std_logic_vector(39 downto 0);
    -- world grid rom
    type tile_rom_type is array (0 to 29) of
    std_logic_vector (39 downto 0);
    -- rull tile ROM definition
    constant tile_rom : tile_rom_type := 
    (
        "1111111111111111111111111111111111111111", --0
        "1000000000000000000000000000000000000001", --1
        "1000000000000000000000000000000000000001", --2
        "1000000000000000000000000000000000000001", --3
        "1000000000000000000000000000000000000001", --4
        "1000000000000000000000000000000000000001", --5
        "1000000000000000000000001110100000000001", --6
        "1000000000000000000000111000100000011001", --7
        "1000000000000000000011100011100000000001", --8
        "1000000000000000011110001110000000000001", --9
        "1000000000000001110000111000000000000001", --10
        "1000000000001110000111000000000000000001", --11
        "1000000000111110111000000000000011110001", --12
        "1000010001111110000000000000000000000001", --13
        "1111111111111111111111000000111111111111", --14
        "1000000000000000000000000000000000000001", --15
        "1000000000000000000000111111000000000001", --16
        "1000000000000000000001000000000000000001", --17
        "1000000000000000001110000000000000000001", --18
        "1000000000000001111000000000000000000001", --19
        "1000000000011110000000000000000000000001", --20
        "1000000000000000000000000000000000000001", --21
        "1000000000000000000000000000000000000001", --22
        "1000000000000000000000000000000000000001", --23
        "1000000000000000000000000000000000000001", --24
        "1000000000000000000000000000000000000001", --25
        "1000000000000000000000000000000000000001", --26
        "1000000000000000000000000000000000000001", --27
        "1000000000000000000000000000000000000001", --28
        "1111111111111111111111111111111111111111"  --29
    );
begin
    sec_tick <= second_tick;
    -- registers
    process (clk, reset)
    begin
        if reset = '1' then
            player_x_reg <= to_unsigned(50, 11);
            player_y_reg <= to_unsigned(50, 11);
            player_x_delta_reg <= (others => '0');
            player_y_delta_reg <= (others => '0');
        elsif (clk'EVENT and clk = '1') then
            player_x_reg <= player_x_next;
            player_y_reg <= player_y_next;
            player_x_delta_reg <= player_x_delta_next;
            player_y_delta_reg <= player_y_delta_next;
        end if;
    end process;

    pix_x(9 downto 0) <= unsigned(pixel_x);
    pix_y(9 downto 0) <= unsigned(pixel_y);
 
    world_pix_x <= pix_x + cam_x;
    world_pix_y <= pix_y + cam_y;
 
    -- refr_tick: 1-clock tick asserted at start of v-sync
    -- i.e., when the screen is refreshed (60 Hz)
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) else
                 '0';
    second_tick_unit : entity work.clk_divider port map(refr_tick, second_tick, 60);
    gravity_tick_unit : entity work.clk_divider port map(refr_tick, gravity_tick, 6);
 
    -- index onto tile grid 
    tile_x <= world_pix_x(10 downto 5);
    tile_y <= world_pix_y(10 downto 5);

    -- get wall_on from ROM based on tile position
    tile_row <= tile_rom(to_integer(tile_y));
    wall_on <= tile_row(39 - to_integer(tile_x));

    player_x_l <= player_x_reg;
    player_y_t <= player_y_reg;
    player_x_m <= player_x_reg + player_size/2 - 1;
    player_y_m <= player_y_reg + player_size/2 - 1;
    player_x_r <= player_x_l + player_size - 1;
    player_y_b <= player_y_t + player_size - 1;

    player_on <= 
        '1' when (player_x_l <= world_pix_x) and (world_pix_x <= player_x_r) and
        (player_y_t <= world_pix_y) and (world_pix_y <= player_y_b) else
        '0';

    camera_process : process (player_x_reg, player_y_reg)
    begin
        if player_x_m < viewport_size_x_half then
            cam_x <= (others => '0');
        elsif player_x_m > (world_size_x - viewport_size_x_half) then
            cam_x <= cam_max_x;
        else
            cam_x <= player_x_m - viewport_size_x_half;
        end if;
        if player_y_m < viewport_size_y_half then
            cam_y <= (others => '0');
        elsif player_y_m > (world_size_y - viewport_size_y_half) then
            cam_y <= cam_max_y;
        else
            cam_y <= player_y_m - viewport_size_y_half;
        end if;
    end process camera_process;

    player_delta_process : process (refr_tick)
    begin
        if rising_edge(refr_tick) then
            -- x deltas
            -- left
            if btn(3) = '1' then
                if player_x_delta_reg > -4 then
                    player_x_delta_next <= player_x_delta_reg - 1;
                end if;
                moving_left <= '1';
                moving_right <= '0';
            -- right
            elsif btn(2) = '1' then
                if player_x_delta_reg < 4 then
                    player_x_delta_next <= player_x_delta_reg + 1;
                end if;
                moving_left <= '0';
                moving_right <= '1';
            else
                if player_x_delta_reg > 0 then
                    player_x_delta_next <= player_x_delta_reg - 1;
                elsif player_x_delta_reg < 0 then
                    player_x_delta_next <= player_x_delta_reg + 1;
                end if;
                moving_left <= '0';
                moving_right <= '0';
            end if;
            
            -- y deltas
            -- player on ground and press jump button
            if btn(0) = '1' and on_ground = '1' then
                player_y_delta_next <= to_signed(-5, 11);
            elsif on_ground = '1' then
                player_y_delta_next <= (others => '0');
            elsif on_ceiling = '1' then
                player_y_delta_next <= to_signed(1, 11);
            -- apply gravity
            elsif player_y_delta_reg < 20 and gravity_tick = '1' then
                player_y_delta_next <= player_y_delta_reg + 1;
            end if;
        end if;
    end process player_delta_process;
    
    player_update_process: process(refr_tick)
        -- variables to be used inside this process only for collision detection and resolution
        variable player_x_next_temp, player_y_next_temp : unsigned(10 downto 0);
        variable player_x_l_next, player_x_r_next : unsigned(10 downto 0);
        variable player_y_t_next, player_y_b_next : unsigned(10 downto 0);
        variable tile_l, tile_r, tile_t, tile_b : unsigned(5 downto 0);
        variable collision_topleft, collision_topright, collision_botleft, collision_botright : std_logic;
        variable tile_row_var : std_logic_vector(39 downto 0);
    begin
        if refr_tick = '1' then
            -- get potential update
            -- these temporary next positions may result in collisions and
            -- need to be resolved
            player_x_next_temp := player_x_reg + unsigned(player_x_delta_reg);
            player_y_next_temp := player_y_reg + unsigned(player_y_delta_reg);
            
            -- get next left, top, right, and bottom positions
            player_x_l_next := player_x_next_temp;
            player_y_t_next := player_y_next_temp;
            player_x_r_next := player_x_next_temp + player_size - 1;
            player_y_b_next := player_y_next_temp + player_size - 1;
            
            -- get tile for next x position and current y position
            tile_l := player_x_l_next(10 downto 5);
            tile_r := player_x_r_next(10 downto 5);
            tile_t := player_y_t(10 downto 5);
            tile_b := player_y_b(10 downto 5);

            -- check for collisions on the top of the player
            tile_row_var := tile_rom(to_integer(tile_t));
            collision_topleft := tile_row_var(39 - to_integer(tile_l));
            collision_topright := tile_row_var(39 - to_integer(tile_r));
            
            -- check for collisions on the bottom of the player
            tile_row_var := tile_rom(to_integer(tile_b));
            collision_botleft := tile_row_var(39 - to_integer(tile_l));
            collision_botright := tile_row_var(39 - to_integer(tile_r));
            
            -- resolve collisions in x direction
            -- collision moving left, adjust player to nearest tile to the right
            if (collision_topleft='1' or collision_botleft='1') and player_x_delta_reg<0 then
                player_x_next_temp := (tile_l+1) & "00000";
            -- collision moving left, adjust player to nearest tile to the right
            elsif  (collision_topright='1' or collision_botright='1') and player_x_delta_reg>0 then
                player_x_next_temp := tile_l & "00000";
            end if;
            
            -- update left and right next with resolved collisions
            player_x_l_next := player_x_next_temp;
            player_x_r_next := player_x_next_temp + player_size - 1;
            
            -- now that x collisions are resolved, check y collisions
            
            -- get tiles for next x and next y positions
            tile_l := player_x_l_next(10 downto 5);
            tile_r := player_x_r_next(10 downto 5);
            tile_t := player_y_t_next(10 downto 5);
            tile_b := player_y_b_next(10 downto 5);

            -- check for collisions on the top of the player
            tile_row_var := tile_rom(to_integer(tile_t));
            collision_topleft := tile_row_var(39 - to_integer(tile_l));
            collision_topright := tile_row_var(39 - to_integer(tile_r));
            
            -- check for collisions on the bottom of the player 
            tile_row_var := tile_rom(to_integer(tile_b));
            collision_botleft := tile_row_var(39 - to_integer(tile_l));
            collision_botright := tile_row_var(39 - to_integer(tile_r));
            
            -- resolve collisions in y direction
            -- collision moving up, adjust player to nearest tile below
            if (collision_topleft='1' or collision_topright='1') and player_y_delta_reg<0 then
                player_y_next_temp := (tile_t+1) & "00000";
            -- collision moving down, adjust player to nearest tile above
            elsif  (collision_botleft='1' or collision_botright='1') and player_y_delta_reg>0 then
                player_y_next_temp := tile_t & "00000";
            end if;
            
            -- now that all collisions are resolved, check if player is on the ground
            -- check one pixel below the bottom of the player (y + player_size - 1 + 1)
            player_y_b_next := player_y_next_temp + player_size;
            
            -- get tiles for next x and next y positions
            tile_l := player_x_l_next(10 downto 5);
            tile_r := player_x_r_next(10 downto 5);
            tile_b := player_y_b_next(10 downto 5);
            
            -- check for collisions with pixel under the player
            tile_row_var := tile_rom(to_integer(tile_b));
            collision_botleft := tile_row_var(39 - to_integer(tile_l));
            collision_botright := tile_row_var(39 - to_integer(tile_r));
            
            -- flag for player standing on the ground
            on_ground <= collision_botleft or collision_botright;
            
            -- repeat the ground check steps with the pixel above the player
            -- to check if the player is touching the cieling
            if player_y_next_temp > 0 then
                player_y_t_next := player_y_next_temp - 1;
                
                -- get tiles for next x and next y positions
                tile_l := player_x_l_next(10 downto 5);
                tile_r := player_x_r_next(10 downto 5);
                tile_t := player_y_t_next(10 downto 5);
                
                -- check for collisions with pixel under the player
                tile_row_var := tile_rom(to_integer(tile_t));
                collision_topleft := tile_row_var(39 - to_integer(tile_l));
                collision_topright := tile_row_var(39 - to_integer(tile_r));
                
                -- flag for player standing on the ground
                on_ceiling <= collision_topleft or collision_topright;
            else
                on_ceiling <= '1'; -- player is at the top of the world
            end if;
            
            player_x_next <= player_x_next_temp;
            player_y_next <= player_y_next_temp;
        else
            player_x_next <= player_x_reg;
            player_y_next <= player_y_reg;
        end if;
    end process player_update_process;

    color_mux : process (video_on, wall_on)
    begin
        if video_on = '0' then
            graph_rgb <= "000";
        else
            if player_on = '1' then
                graph_rgb <= "011"; --blue
            elsif wall_on = '1' then
                graph_rgb <= "111"; --white
            else
                graph_rgb <= "000"; --black
            end if;
        end if;
    end process color_mux;
    
    col_led <= on_ground & on_ceiling & '0' & '0';
end arch;