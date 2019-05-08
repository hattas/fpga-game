----------------------------------------------------------------------------------
--
-- file: tile_rom_32x32.vhd
-- authors: John Hattas, Margaret Huelskamp
-- created: 4/8/19
-- description: Test 32x32 tile ROM
------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tile_rom_32x32 is
   port(
        clk, reset: std_logic;
        btn: std_logic_vector(1 downto 0);
        video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
   );
end tile_rom_32x32;

architecture arch of tile_rom_32x32 is
   signal refr_tick, wall_on: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   
   signal tile_x, tile_y: std_logic_vector(4 downto 0);
   signal tile_row: std_logic_vector(19 downto 0);
   -- world grid rom
   type tile_rom_type is array (0 to 14) of
       std_logic_vector (19 downto 0);
   -- rull tile ROM definition
   constant tile_rom: tile_rom_type :=
   (
        "10001010010111001000", --0
        "10001010010100101000", --1
        "10001010010100101000", --2
        "10001010010100101000", --3
        "10001010010100101000", --4
        "10001010010100101000", --5
        "01010010010100101000", --6
        "01010011110100101000", --7
        "01010010010100101000", --8
        "01010010010100101000", --9
        "01010010010100101000", --10
        "01010010010100101000", --11
        "01010010010100101000", --12
        "00100010010100101000", --13
        "00100010010111001111"  --14
   );
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
	
	-- index onto tile grid    
    tile_x <= pixel_x(9 downto 5);
	tile_y <= pixel_y(9 downto 5);
    
    -- get row of tiles from tile rom
    tile_row <= tile_rom(to_integer(unsigned(tile_y)));
    -- select tile from tile row
	wall_on <= tile_row(19 - to_integer(unsigned(tile_x)));

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
