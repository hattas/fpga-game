-- test a larger screen with scrolling camera
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity player_test is
   port(
        clk, reset: std_logic;
        btn: std_logic_vector(3 downto 0);
        video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0);
        sec_tick: out std_logic
   );
end player_test;

architecture arch of player_test is
   signal refr_tick, second_tick: std_logic;
   signal wall_on, player_on: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(10 downto 0);
   signal world_pix_x, world_pix_y: unsigned(10 downto 0);
   -- player signals
   signal player_x_reg, player_x_next: unsigned(10 downto 0);
   signal player_y_reg, player_y_next: unsigned(10 downto 0);
   -- x and y left, right, and middle
   signal player_x_l, player_x_r, player_x_m, player_y_t, player_y_b, player_y_m: unsigned(10 downto 0);
   -- player delta regs
   signal player_x_delta_reg, player_x_delta_next: unsigned(10 downto 0);
   signal player_y_delta_reg, player_y_delta_next: unsigned(10 downto 0);
   -- camera signals
   signal cam_x_reg: unsigned(10 downto 0) := to_unsigned(640, 11);
   signal cam_y_reg: unsigned(10 downto 0) := to_unsigned(480, 11);
   signal cam_x_next, cam_y_next: unsigned(10 downto 0);
   -- world constants
   constant viewport_size_x_half: unsigned(10 downto 0) := to_unsigned(320, 11);
   constant viewport_size_y_half: unsigned(10 downto 0) := to_unsigned(240, 11);
   constant world_size_x: unsigned(10 downto 0) := to_unsigned(1280, 11);
   constant world_size_y: unsigned(10 downto 0) := to_unsigned(960, 11);
   constant cam_max_x: unsigned(10 downto 0) := to_unsigned(640, 11);
   constant cam_max_y: unsigned(10 downto 0) := to_unsigned(480, 11);
   constant player_size: unsigned(10 downto 0) := to_unsigned(32, 11);
   
   signal tile_x, tile_y: unsigned(5 downto 0);
   signal tile_row: std_logic_vector(39 downto 0);
   -- world grid rom
   type tile_rom_type is array (0 to 29) of
       std_logic_vector (39 downto 0);
   -- rull tile ROM definition
   constant tile_rom: tile_rom_type :=
   (
        "1111111111111111111111111111111111111111", --0
        "1000000000000000000000000000000000000001", --1
        "1000000000000000000000000000000000000001", --2
        "1000000000000000000000000000111000000001", --3
        "1000000000000000000000000000101100000001", --4
        "1000000000000000000000000000101100000001", --5
        "1000001111100000000000000000101000000001", --6
        "1000111001100000000000000000101000000001", --7
        "1000100001000000000000000000101000000001", --8
        "1000100001000000000000000000111000000001", --9
        "1000111111000000000000000000000000000001", --10
        "1000000000000000000100000000000000000001", --11
        "1000000000000000001100000000000000000001", --12
        "1000000000000000001100000000000000000001", --13
        "1000000000000000000011000000000000000001", --14
        "1000000000000000000001000000000000000001", --15
        "1000000000000000001111000000000000000001", --16
        "1000000000000000000000000000111111100001", --17
        "1000000000000000000000000001111111100001", --18
        "1000000011000000000000000011111111000001", --19
        "1000000011100000000000001111111000000001", --20
        "1000000000111111111111111111100000000001", --21
        "1000000000111111111111111000000000000001", --22
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
   process (clk,reset)
   begin
      if reset='1' then
         cam_x_reg <= (others=>'0');
         cam_y_reg <= (others=>'0');
         player_x_reg <= (others=>'0');
         player_y_reg <= (others=>'0');
         player_x_delta_reg <= (others=>'0');
         player_y_delta_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         cam_x_reg <= cam_x_next;
         cam_y_reg <= cam_y_next;
         player_x_reg <= player_x_next;
         player_y_reg <= player_y_next;
         player_x_delta_reg <= player_x_delta_next;
         player_y_delta_reg <= player_y_delta_next;
      end if;
   end process;

   pix_x(9 downto 0) <= unsigned(pixel_x);
   pix_y(9 downto 0) <= unsigned(pixel_y);
   
   world_pix_x <= pix_x + cam_x_reg;
   world_pix_y <= pix_y + cam_y_reg;
   
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
    refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                 '0';
    second_tick_unit: entity work.clk_divider port map(refr_tick, second_tick);
    
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
    
    camera_process: process(player_x_reg, player_y_reg)
    begin
        if player_x_m < viewport_size_x_half then
            cam_x_next <= (others => '0');
        elsif player_x_m > (world_size_x - viewport_size_x_half) then
            cam_x_next <= cam_max_x;
        else
            cam_x_next <= player_x_m - viewport_size_x_half;
        end if;
        if player_y_m < viewport_size_y_half then
            cam_y_next <= (others => '0');
        elsif player_y_m > (world_size_y - viewport_size_y_half) then
            cam_y_next <= cam_max_y;
        else
            cam_y_next <= player_y_m - viewport_size_y_half;
        end if;
    end process camera_process;
    
    player_delta_process: process(refr_tick)
    begin
        if rising_edge(refr_tick) then
            --left
            if btn(3) = '1' then
                player_x_delta_next <= unsigned(to_signed(-1, 11));
            --right
            elsif btn(0) = '1' then
                player_x_delta_next <= to_unsigned(1, 11);
            else
                player_x_delta_next <= (others=>'0');
            end if;
            --down
            if btn(2) = '1' then
                player_y_delta_next <= to_unsigned(1, 11);
            --up
            elsif btn(1) = '1' then
                player_y_delta_next <= unsigned(to_signed(-1, 11));
            else
                player_y_delta_next <= (others=>'0');
            end if;
        end if;
    end process player_delta_process;
    
    -- update player position
    player_x_next <= player_x_reg + player_x_delta_reg when refr_tick='1' else player_x_reg;
    player_y_next <= player_y_reg + player_y_delta_reg when refr_tick='1' else player_y_reg;
	
   process(video_on, wall_on)
   begin
      if video_on='0' then
          graph_rgb <= "000";
      else
         if player_on = '1' then
            graph_rgb <= "011"; --blue
         elsif wall_on ='1' then
            graph_rgb <= "111"; --white
		 else
            graph_rgb <= "000"; --black
         end if;
      end if;
   end process;
end arch;
