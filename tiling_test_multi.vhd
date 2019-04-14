-- Listing 12.5
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tiling_test_multi is
   port(
        clk, reset: std_logic;
        btn: std_logic_vector(1 downto 0);
        video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
   );
end tiling_test_multi;

architecture arch of tiling_test_multi is
   signal refr_tick, wall_on: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   
   signal tile_x_8, tile_y_8: std_logic_vector(6 downto 0);
   signal tile_x_16, tile_y_16: std_logic_vector(5 downto 0);
   signal tile_x_32, tile_y_32: std_logic_vector(4 downto 0);
   signal tile_x_64, tile_y_64: std_logic_vector(3 downto 0);
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
	
	-- index onto tile grid    
    tile_x_8 <= pixel_x(9 downto 3);
	tile_y_8 <= pixel_y(9 downto 3);
	tile_x_16 <= pixel_x(9 downto 4);
	tile_y_16 <= pixel_y(9 downto 4);
    tile_x_32 <= pixel_x(9 downto 5);
	tile_y_32 <= pixel_y(9 downto 5);
    tile_x_64 <= pixel_x(9 downto 6);
	tile_y_64 <= pixel_y(9 downto 6);
	
	process(pixel_x, pixel_y)
	begin
        if ((pix_x < 320) and (pix_y < 240)) then
            if (tile_x_8(0) xnor tile_y_8(0)) = '1' then
                wall_on <= '1';
            else
                wall_on <= '0';
            end if;
        elsif ((pix_x >= 320) and (pix_y < 240)) then
            if (tile_x_16(0) xnor tile_y_16(0)) = '1' then
                wall_on <= '1';
            else
                wall_on <= '0';
            end if;
        elsif ((pix_x < 320) and (pix_y >= 240)) then
            if (tile_x_32(0) xnor tile_y_32(0)) = '1' then
                wall_on <= '1';
            else
                wall_on <= '0';
            end if;
        else
            if (tile_x_64(0) xnor tile_y_64(0)) = '1' then
                wall_on <= '1';
            else
                wall_on <= '0';
            end if;
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
