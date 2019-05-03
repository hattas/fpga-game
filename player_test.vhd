-- test a larger screen with scrolling camera
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity player_test is
    port (
        clk, reset : std_logic;
        btn : std_logic_vector(7 downto 0);
        video_on : in std_logic;
        pixel_x, pixel_y : in std_logic_vector(9 downto 0);
        graph_rgb : out std_logic_vector(2 downto 0);
        led : out std_logic_vector(9 downto 0);
		hex0, hex1, hex2, hex3, hex4, hex5 : out std_logic_vector(3 downto 0) := (others => '0')
    );
end player_test;

architecture arch of player_test is
    -- 60 Hz and 1 Hz reference ticks
    signal refr_tick, refr_tick_next, refr_pulse, second_tick, horiz_tick, grav_tick : std_logic;
	signal second_counter : unsigned(7 downto 0) := (others => '0');
	signal grav_counter, grav_counter_next : integer := 0;
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
    signal moving_left, moving_right, on_ground, on_ceiling, on_left, on_right: std_logic;
    -- player delta regs
    signal player_x_delta_reg, player_x_delta_next : signed(10 downto 0);
    signal player_y_delta_reg, player_y_delta_next : signed(10 downto 0);
	 -- movement button signals
	 signal btn_jump, btn_left, btn_right : std_logic;
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
    -- rom types
    type tile_rom_type is array (0 to 29) of std_logic_vector (39 downto 0);
	 type block_rom_type is array (0 to 31) of std_logic_vector (31 downto 0);

	 -- world tile ROM
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
	 
	 -- wall roms
    constant wall_rom_r : block_rom_type := 
    (
         "00111111111111111111111111111100", --0
			"00111111111111111111111111111100", --1
			"11111111111111111111111111111111", --2
			"11111111111111111111111111111111", --3
			"11111111111111111111111111111111", --4
			"11111111111111111111111111111111", --5
			"11111111000000000000000011111111", --6
			"11111111000000000000000011111111", --7
			"11111100000000000000000000111111", --8
			"11111100000000000000000000111111", --9
			"11111100000000000000000000111111", --10
			"11111100000000000000000000111111", --11
			"11111100000000000000000000111111", --12
			"11111100000000000000000000111111", --13
			"11111100000000000000000000111111", --14
			"11111100000000000000000000111111", --15
			"11111100000000000000000000111111", --16
			"11111100000000000000000000111111", --17
			"11111100000000000000000000111111", --18
			"11111100000000000000000000111111", --19
			"11111100000000000000000000111111", --20
			"11111100000000000000000000111111", --21
			"11111100000000000000000000111111", --22
			"11111100000000000000000000111111", --23
			"11111111000000000000000011111111", --24
			"11111111000000000000000011111111", --25
			"11111111111111111111111111111111", --26
			"11111111111111111111111111111111", --27
			"11111111111111111111111111111111", --28
			"11111111111111111111111111111111", --29
			"00111111111111111111111111111100", --30
			"00111111111111111111111111111100"  --31
    );
	 
    constant wall_rom_g : block_rom_type := 
    (
         "00111111111111111111111111111100", --0
			"00111111111111111111111111111100", --1
			"11110000000000000000000000001111", --2
			"11110000000000000000000000001111", --3
			"11000011000000000000000000000011", --4
			"11000011000000000000000000000011", --5
			"11000011111111111111111100000011", --6
			"11000011111111111111111100000011", --7
			"11000011110000000000001111000011", --8
			"11000011110000000000001111000011", --9
			"11000011000000000000000011000011", --10
			"11000011000000000000000011000011", --11
			"11000011000000000000000011000011", --12
			"11000011000000000000000011000011", --13
			"11000011000000000000000011000011", --14
			"11000011000000000000000011000011", --15
			"11000011000000000000000011000011", --16
			"11000011000000000000000011000011", --17
			"11000011000000000000000011000011", --18
			"11000011000000000000000011000011", --19
			"11000011000000000000000011000011", --20
			"11000011000000000000000011000011", --21
			"11000011110000000000001111000011", --22
			"11000011110000000000001111000011", --23
			"11000000111111111111111100000011", --24
			"11000000111111111111111100000011", --25
			"11000000000000000000000000000011", --26
			"11000000000000000000000000000011", --27
			"11110000000000000000000000001111", --28
			"11110000000000000000000000001111", --29
			"00111111111111111111111111111100", --30
			"00111111111111111111111111111100"  --31
    );
	 
    constant wall_rom_b : block_rom_type := 
    (
         "00000000000000000000000000000000", --0
			"00000000000000000000000000000000", --1
			"00001111111111111111111111110000", --2
			"00001111111111111111111111110000", --3
			"00111111000000000000000000111100", --4
			"00111111000000000000000000111100", --5
			"00110011000000000000000000001100", --6
			"00110011000000000000000000001100", --7
			"00110000001111111111110000001100", --8
			"00110000001111111111110000001100", --9
			"00110000111100000000111100001100", --10
			"00110000111100000000111100001100", --11
			"00110000110000000000001100001100", --12
			"00110000110000000000001100001100", --13
			"00110000110000000000001100001100", --14
			"00110000110000000000001100001100", --15
			"00110000110000000000001100001100", --16
			"00110000110000000000001100001100", --17
			"00110000110000000000001100001100", --18
			"00110000110000000000001100001100", --19
			"00110000111100000000111100001100", --20
			"00110000111100000000111100001100", --21
			"00110000001111111111110000001100", --22
			"00110000001111111111110000001100", --23
			"00110000000000000000000000001100", --24
			"00110000000000000000000000001100", --25
			"00111100000000000000000000111100", --26
			"00111100000000000000000000111100", --27
			"00001111111111111111111111110000", --28
			"00001111111111111111111111110000", --29
			"00000000000000000000000000000000", --30
			"00000000000000000000000000000000"  --31
    );
	 
	 -- player roms
    constant player_rom_r : block_rom_type := 
    (
			"00000000000000000000000000000000", --0
			"00000000000000000000000000000000", --1
			"00000000000000000000000000000000", --2
			"00000000000000000000000000000000", --3
			"00000000000000000000000000000000", --4
			"00001111110000000111111000000000", --5
			"00011111111000001111111100000000", --6
			"00111111111100011111111110000000", --7
			"00111111111100011111111110000000", --8
			"00000001111100000000111110000000", --9
			"00000001111100000000111110000000", --10
			"00000001111100000000111110000000", --11
			"00000001111100000000111110000000", --12
			"00000001111100000000111110000000", --13
			"00111111111100011111111110000000", --14
			"00011111111000001111111100000000", --15
			"00001111110000000111111000000000", --16
			"00000000000000000000000000000000", --17
			"00000000000000000000000000000000", --18
			"00000000000000000000000000000000", --19
			"00000000000000000000000000000000", --20
			"00000000000000000000000000000000", --21
			"00000000000000000000000000000000", --22
			"00000000000000000000000000000000", --23
			"00000000000000000000000000000000", --24
			"00000000000000000000000000000000", --25
			"00000000000000000000000000000000", --26
			"00000000000000000000000000000000", --27
			"00000000000000000000000000000000", --28
			"00000000000000000000000000000000", --29
			"00000000000000000000000000000000", --30
			"00000000000000000000000000000000"  --31
    );
	 
    constant player_rom_g : block_rom_type := 
    (
			"00000000000000000000000000000000", --0
			"00000000000011111111000000000000", --1
			"00000000011111111111111000000000", --2
			"00000001111111111111111110000000", --3
			"00000011111111111111111111000000", --4
			"00001111111111111111111111100000", --5
			"00011111111111111111111111110000", --6
			"00111111111111111111111111111000", --7
			"00111111111111111111111111111100", --8
			"01111111111111111111111111111100", --9
			"01111111111111111111111111111100", --10
			"11111111111111111111111111111110", --11
			"11111111111111111111111111111110", --12
			"11111111111111111111111111111110", --13
			"11111111111111111111111111111110", --14
			"11111111111111111111111111111110", --15
			"11111111111111111111111111111110", --16
			"11111111111111111111111111111110", --17
			"11111111111111111111111111111110", --18
			"11111111111111111111111111111110", --19
			"11111111111111111111111111111110", --20
			"11111111111111111111111111111110", --21
			"11111111111111111111111111111110", --22
			"11111111111111111111111111111110", --23
			"11111111111111111111111111111110", --24
			"11111111111111111111111111111110", --25
			"11111111111111111111111111111110", --26
			"11111111111111100111111111111110", --27
			"11110011111111000011111111001110", --28
			"11100001111110000001111110000110", --29
			"11000000111100000000111100000010", --30
			"10000000011000000000011000000000"  --31
    );
	 
    constant player_rom_b : block_rom_type := 
    (
		"00000000000011111111000000000000", --0
		"00000000011100000000111000000000", --1
		"00000001111111111111000110000000", --2
		"00000011111111111111111001000000", --3
		"00000111111111111111111110100000", --4
		"00000000001111111000000111010000", --5
		"00011111110111111111111011101000", --6
		"00111111111011111111111101110100", --7
		"00111111111011111111111101111000", --8
		"01000001111011100000111101111010", --9
		"01000001111011100000111101111010", --10
		"11000001111011100000111101111101", --11
		"11000001111011100000111101111101", --12
		"11000001111011100000111101111101", --13
		"11111111111011111111111101111101", --14
		"11101111110111110111111011111101", --15
		"11110000001111111000000111111101", --16
		"11111111111111111111111111111101", --17
		"11111111111111111111111111111101", --18
		"11111111111111111111111111111101", --19
		"11111111111111111111111111111101", --20
		"11111111111111111111111111111101", --21
		"11111111111111111111111111111101", --22
		"11111111111111111111111111111101", --23
		"11111111111111111111111111111101", --24
		"11111111111111111111111111111101", --25
		"11111111111111111111111111111101", --26
		"11111111111111111111111111111101", --27
		"11111111111111100111111111111101", --28
		"11110011111111000011111111001101", --29
		"11100001111110000001111110000101", --30
		"11000000111100000000111100000011"  --31
    );
	 
	 
begin
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
			refr_tick <= refr_tick_next;
        end if;
    end process;
	
	-- assign buttons
	btn_jump <= btn(1); --b
	btn_left <= btn(6); --left
	btn_right <= btn(7); --right
	
	
    pix_x(9 downto 0) <= unsigned(pixel_x);
    pix_y(9 downto 0) <= unsigned(pixel_y);
 
    world_pix_x <= pix_x + cam_x;
    world_pix_y <= pix_y + cam_y;
 
    -- refr_tick: 1-clock tick asserted at start of v-sync
    -- i.e., when the screen is refreshed (60 Hz)
    --refr_tick_next <= '1' when (pix_y = 481) and (pix_x = 0) else '0';
	refr_tick_next <= '1' when (pix_y = 481) else '0';
	refr_pulse <= '1' when refr_tick = '0' and refr_tick_next = '1' else '0';
    second_tick_unit : entity work.clk_divider port map(refr_tick, second_tick, 60);
	horizo_tick_unit : entity work.clk_divider port map(refr_tick, horiz_tick, 3);
	gravit_tick_unit : entity work.gravity_divider port map(on_ground, refr_tick, grav_tick, 3);
	second_counter <= second_counter + 1 when rising_edge(second_tick);
	hex4 <= std_logic_vector(second_counter(3 downto 0));
	hex5 <= std_logic_vector(second_counter(7 downto 4));
	
    -- index onto tile grid 
    tile_x <= world_pix_x(10 downto 5);
    tile_y <= world_pix_y(10 downto 5);
	-- show tile coordinates on 7 segment display
	hex0 <= std_logic_vector(player_y_reg(8 downto 5));
	hex1 <= "00" & std_logic_vector(player_y_reg(10 downto 9));
	hex2 <= std_logic_vector(player_x_reg(8 downto 5));
	hex3 <= "00" & std_logic_vector(player_x_reg(10 downto 9));

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

    player_process : process (refr_pulse)
		-- variables to be used inside this process only for collision detection and resolution
        variable player_x_next_temp, player_y_next_temp : unsigned(10 downto 0);
        variable player_x_l_next, player_x_r_next : unsigned(10 downto 0);
        variable player_y_t_next, player_y_b_next : unsigned(10 downto 0);
        variable tile_l, tile_r, tile_t, tile_b : unsigned(5 downto 0);
        variable collision_topleft, collision_topright, collision_botleft, collision_botright : std_logic;
        variable tile_row_var : std_logic_vector(39 downto 0);
		variable temp_col : std_logic;
    begin
        if refr_pulse = '1' then
		
            -- x deltas
            -- left
            if btn_left = '1' then
				if on_left = '0' then
					if player_x_delta_reg > -8  and horiz_tick = '1' then
						if on_ground = '1' then
							player_x_delta_next <= player_x_delta_reg - 2;
						else
							player_x_delta_next <= player_x_delta_reg - 1;
						end if;
					end if;
				else
					player_x_delta_next <= to_signed(-1, 11);
				end if;
                moving_left <= '1';
                moving_right <= '0';
            -- right
            elsif btn_right = '1' then
				if on_right = '0' then
					if player_x_delta_reg < 8  and horiz_tick = '1' then
						if on_ground = '1' then
							player_x_delta_next <= player_x_delta_reg + 2;
						else
							player_x_delta_next <= player_x_delta_reg + 1;
						end if;
					end if;
				else
					player_x_delta_next <= to_signed(1, 11);
				end if;
                moving_left <= '0';
                moving_right <= '1';
            else
			    if (on_left = '1' and moving_left = '1') or (on_right = '1' and moving_right = '1') then
					player_x_delta_next <= (others => '0');
                elsif player_x_delta_reg > 0  and horiz_tick = '1' then
                    player_x_delta_next <= player_x_delta_reg - 2;
                elsif player_x_delta_reg < 0  and horiz_tick = '1' then
                    player_x_delta_next <= player_x_delta_reg + 2;
                end if;
				if player_x_delta_reg >= -1 and player_x_delta_reg <= 1 and horiz_tick = '1' then
					player_x_delta_next <= (others => '0');
				end if;
            end if;
            
            -- y deltas
            -- player on ground and press jump button
            if btn_jump = '1' and on_ground = '1' then
                player_y_delta_next <= to_signed(-10, 11);
            elsif on_ground = '1' then
                player_y_delta_next <= (others => '0');
            elsif on_ceiling = '1' then
                player_y_delta_next <= to_signed(1, 11);
            -- apply gravity
            elsif player_y_delta_reg < 20 and grav_tick = '1' then
                player_y_delta_next <= player_y_delta_reg + 1;
			else
				player_y_delta_next <= player_y_delta_reg;
            end if;
			
			
			-- get potential update
            -- these temporary next positions may result in collisions and
            -- need to be resolved
            player_x_next_temp := player_x_reg + unsigned(player_x_delta_reg);
            player_y_next_temp := player_y_reg + unsigned(player_y_delta_reg);
            
			---------- HORIZONTAL COLLISIONS ----------
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
            ---------- END HORIZONTAL COLLISIONS ----------
			
			---------- VERTICAL COLLISIONS ----------
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
            ---------- END VERTICAL COLLISIONS ----------
			
			
			---------- VERTICAL BORDER COLLISIONS ----------
            -- now that all collisions are resolved, check if player is on the ground
            -- check one pixel below the bottom of the player (y + player_size - 1 + 1)
			-- check one pixel above the top of the player (y - 1)
			-- need this check so the value doesn't go below 0
			if player_y_next_temp > 0 then
				player_y_t_next := player_y_next_temp - 1;
				temp_col := '0';
			else
				player_y_t_next := player_y_next_temp;
				temp_col := '1';
			end if;
            player_y_b_next := player_y_next_temp + player_size;
            
            -- get tiles for next x and next y positions
            tile_l := player_x_l_next(10 downto 5);
            tile_r := player_x_r_next(10 downto 5);
			tile_t := player_y_t_next(10 downto 5);
            tile_b := player_y_b_next(10 downto 5);
            
			-- check for collisions with ceiling
			tile_row_var := tile_rom(to_integer(tile_t));
            collision_topleft := tile_row_var(39 - to_integer(tile_l));
            collision_topright := tile_row_var(39 - to_integer(tile_r));
			
			-- check for collisions with floor
            tile_row_var := tile_rom(to_integer(tile_b));
            collision_botleft := tile_row_var(39 - to_integer(tile_l));
            collision_botright := tile_row_var(39 - to_integer(tile_r));
            
            -- flag for player standing on the ground
            on_ground <= collision_botleft or collision_botright;
			
			-- flag for player hitting ceiling
			if temp_col = '1' then
				on_ceiling <= '1';
			else
				on_ceiling <= collision_topleft or collision_topright;
			end if;
			---------- END VERTICAL BORDER COLLISIONS ----------
            
			
			---------- HORIZONTAL BORDER COLLISIONS ----------
            -- now that all collisions are resolved, check if player is on the ground
            -- check one pixel below the bottom of the player (y + player_size - 1 + 1)
			-- check one pixel above the top of the player (y - 1)
			-- need this check so the value doesn't go below 0
			if player_x_next_temp > 0 then
				player_x_l_next := player_x_next_temp - 1;
				temp_col := '0';
			else
				player_x_l_next := player_x_next_temp;
				temp_col := '1';
			end if;
            player_x_r_next := player_x_next_temp + player_size;
			
			-- restore vertical boundaries
			player_y_t_next := player_y_next_temp;
            player_y_b_next := player_y_next_temp + player_size - 1;
            
            -- get tiles for next x and next y positions
            tile_l := player_x_l_next(10 downto 5);
            tile_r := player_x_r_next(10 downto 5);
			tile_t := player_y_t_next(10 downto 5);
            tile_b := player_y_b_next(10 downto 5);
            
			-- check for collisions with ceiling
			tile_row_var := tile_rom(to_integer(tile_t));
            collision_topleft := tile_row_var(39 - to_integer(tile_l));
            collision_topright := tile_row_var(39 - to_integer(tile_r));
			
			-- check for collisions with floor
            tile_row_var := tile_rom(to_integer(tile_b));
            collision_botleft := tile_row_var(39 - to_integer(tile_l));
            collision_botright := tile_row_var(39 - to_integer(tile_r));
            
            -- flag for player standing on the ground
            on_right <= collision_topright or collision_botright;
			
			-- flag for player hitting ceiling
			if temp_col = '1' then
				on_left <= '1';
			else
				on_left <= collision_topleft or collision_botleft;
			end if;
			---------- END HORIZONTAL BORDER COLLISIONS ----------
            
            
            player_x_next <= player_x_next_temp;
            player_y_next <= player_y_next_temp;
		else
			player_x_next <= player_x_reg;
            player_y_next <= player_y_reg;
            player_x_delta_next <= player_x_delta_reg;
            player_y_delta_next <= player_y_delta_reg;
        end if;
    end process player_process;
    
    

    color_mux : process (video_on, wall_on)
		variable color_row : std_logic_vector(31 downto 0);
		variable offset_x, offset_y : unsigned(10 downto 0);
    begin
        if video_on = '0' then
            graph_rgb <= "000";
        else
            if player_on = '1' then
					-- index into player color roms to get rgb bits
					offset_x := world_pix_x - player_x_reg;
					offset_y := world_pix_y - player_y_reg;
					if moving_left = '1' then
						 color_row := player_rom_r(to_integer(offset_y(4 downto 0)));
						 graph_rgb(2) <= color_row(to_integer(31 - offset_x(4 downto 0)));
						 color_row := player_rom_g(to_integer(offset_y(4 downto 0)));
						 graph_rgb(1) <= color_row(to_integer(31 - offset_x(4 downto 0)));
						 color_row := player_rom_b(to_integer(offset_y(4 downto 0)));
						 graph_rgb(0) <= color_row(to_integer(31 - offset_x(4 downto 0)));
					else
						 color_row := player_rom_r(to_integer(offset_y(4 downto 0)));
						 graph_rgb(2) <= color_row(to_integer(offset_x(4 downto 0)));
						 color_row := player_rom_g(to_integer(offset_y(4 downto 0)));
						 graph_rgb(1) <= color_row(to_integer(offset_x(4 downto 0)));
						 color_row := player_rom_b(to_integer(offset_y(4 downto 0)));
						 graph_rgb(0) <= color_row(to_integer(offset_x(4 downto 0)));
					end if;
            elsif wall_on = '1' then
					-- index into wall color roms to get rgb bits
					 color_row := wall_rom_r(to_integer(world_pix_y(4 downto 0)));
					 graph_rgb(2) <= color_row(to_integer(31 - world_pix_x(4 downto 0)));
					 color_row := wall_rom_g(to_integer(world_pix_y(4 downto 0)));
					 graph_rgb(1) <= color_row(to_integer(31 - world_pix_x(4 downto 0)));
					 color_row := wall_rom_b(to_integer(world_pix_y(4 downto 0)));
					 graph_rgb(0) <= color_row(to_integer(31 - world_pix_x(4 downto 0)));
				else
					-- background
                graph_rgb <= "000"; --black
            end if;
        end if;
    end process color_mux;
    
	 led(9) <= second_tick;
	 led(8) <= on_ground;
	 led(7) <= on_ceiling;
	 led(6) <= on_left;
	 led(5) <= on_right;
	 led(2) <= btn_left;
	 led(1) <= btn_right;
	 led(0) <= btn_jump;
end arch;