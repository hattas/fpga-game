----------------------------------------------------------------------------------
--
-- file: camera_test.vhd
-- authors: John Hattas, Margaret Huelskamp
-- created: 4/18/19
-- description: Uses camera controlled by buttons to move visible area of world.
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity camera_test is
   port(
        clk, reset: std_logic;
        btn: std_logic_vector(3 downto 0);
        video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
   );
end camera_test;

architecture arch of camera_test is
   signal refr_tick, wall_on: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(10 downto 0);
   signal world_pix_x, world_pix_y: unsigned(10 downto 0);
   signal player_x: unsigned(10 downto 0);
   signal player_y: unsigned(10 downto 0);
   signal cam_x: unsigned(10 downto 0) := to_unsigned(640, 11);
   signal cam_y: unsigned(10 downto 0) := to_unsigned(480, 11);
   constant viewport_size_x_half: unsigned(10 downto 0) := to_unsigned(320, 11);
   constant viewport_size_y_half: unsigned(10 downto 0) := to_unsigned(240, 11);
   constant world_size_x: unsigned(10 downto 0) := to_unsigned(1280, 11);
   constant world_size_y: unsigned(10 downto 0) := to_unsigned(960, 11);
   constant offset_max_x: unsigned(10 downto 0) := to_unsigned(640, 11);
   constant offset_max_y: unsigned(10 downto 0) := to_unsigned(480, 11);
   
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
   pix_x(9 downto 0) <= unsigned(pixel_x);
   pix_y(9 downto 0) <= unsigned(pixel_y);
   
   world_pix_x <= pix_x + cam_x;
   world_pix_y <= pix_y + cam_y;
   
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
	
	-- index onto tile grid    
    tile_x <= world_pix_x(10 downto 5);
	tile_y <= world_pix_y(10 downto 5);
    
    -- get row of tiles from tile rom
    tile_row <= tile_rom(to_integer(tile_y));
    -- select tile from tile row
	-- subtract from 39 to flip the rom to make it consistent with how it is arranged in the code
	wall_on <= tile_row(39 - to_integer(tile_x));
	
    
    process(refr_tick)
    begin
        if refr_tick = '1' then
            --left
            if btn(3) = '1' and cam_x > 0 then
                cam_x <= cam_x - 1;
            --right
            elsif btn(0) = '1' and cam_x < 640 then
                cam_x <= cam_x + 1;
            end if;
            --down
            if btn(2) = '1' and cam_y < 480 then
                cam_y <= cam_y + 1;
            --up
            elsif btn(1) = '1' and cam_y > 0 then
                cam_y <= cam_y - 1;
            end if;
        end if;
    end process;
    
	
   process(video_on, wall_on)
   begin
      if video_on='0' then
          graph_rgb <= "000"; --blank
      else
         if wall_on='1' then
            graph_rgb <= "111"; --white
		 else
            graph_rgb <= "000"; -- black
         end if;
      end if;
   end process;
end arch;
