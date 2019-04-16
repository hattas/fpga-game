-- Listing 12.6
library ieee;
use ieee.std_logic_1164.all;
entity vga_top is --Port map for the vga top
   port (
      clk,reset: in std_logic;
      btn: in std_logic_vector (1 downto 0);
      hsync, vsync: out  std_logic;
      rgb: out std_logic_vector(2 downto 0)
   );
end vga_top;

architecture arch of vga_top is
   signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
   signal video_on, pixel_tick: std_logic;
   signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
begin
   -- instantiate VGA sync
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset,
               video_on=>video_on, p_tick=>pixel_tick,
               hsync=>hsync, vsync=>vsync,
               pixel_x=>pixel_x, pixel_y=>pixel_y);
   -- instantiate graphic generator
   pixel_generator_unit: entity work.color_test
      port map (clk=>clk, reset=>reset,
                btn=>btn, video_on=>video_on,
                pixel_x=>pixel_x, pixel_y=>pixel_y,
                graph_rgb=>rgb_next);
   -- rgb buffer
   process (clk)
   begin
      if (clk'event and clk='1') then 
         if (pixel_tick='1') then
            rgb_reg <= rgb_next; --setting rgb_reg to the next rgb value
         end if;
      end if;
   end process;
   rgb <= rgb_reg;
end arch;
