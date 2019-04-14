-- Listing 12.5
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tiling_test_16x16 is
   port(
        clk, reset: std_logic;
        btn: std_logic_vector(1 downto 0);
        video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
   );
end tiling_test_16x16;

architecture arch of tiling_test_16x16 is
   signal refr_tick, wall_on: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   
   signal tile_x, tile_y: std_logic_vector(5 downto 0);
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
	
	-- index onto tile grid
	tile_x <= pixel_x(9 downto 4);
	tile_y <= pixel_y(9 downto 4);
	
	process(tile_x, tile_y)
	begin
		if (tile_x(0) xnor tile_y(0)) = '1' then
			wall_on <= '1';
		else
			wall_on <= '0';
		end if;
	end process;
	
	
   process(video_on,wall_on)
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
