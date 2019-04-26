
library ieee;
use ieee.std_logic_1164.all;
entity game_top is
    port (
      clk, reset: in std_logic;
      btn: in std_logic_vector (3 downto 0);
      leds: out std_logic_vector(3 downto 0);
      led: out std_logic;
      col_led: out std_logic_vector(3 downto 0);
      hsync, vsync: out  std_logic;
	  vga_r, vga_g, vga_b: out std_logic_vector(7 downto 0);
      vga_clk: out std_logic;
      vga_sync: out std_logic := '0';
      vga_blank: out std_logic := '1'
   );
end game_top;

architecture arch of game_top is
   signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
   signal video_on, pixel_tick: std_logic;
   signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
   signal btn_s: std_logic_vector(3 downto 0);
begin
   -- instantiate VGA sync
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset,
               video_on=>video_on, p_tick=>pixel_tick,
               hsync=>hsync, vsync=>vsync,
               pixel_x=>pixel_x, pixel_y=>pixel_y);
               
   -- instantiate graphic generator
   pixel_generator_unit: entity work.player_test
      port map (clk=>clk, reset=>reset,
                btn=>btn_s, video_on=>video_on,
                pixel_x=>pixel_x, pixel_y=>pixel_y,
                graph_rgb=>rgb_next, sec_tick=>led, col_led=>col_led);
                
   -- instantiate color mapper
	color_map_unit: entity work.color_map port map(rgb_reg, vga_r, vga_g, vga_b);
    
   -- rgb buffer
   process (clk)
   begin
      if (clk'event and clk='1') then 
         if (pixel_tick='1') then
            rgb_reg <= rgb_next; --setting rgb_reg to the next rgb value
         end if;
      end if;
   end process;
   
   vga_clk <= pixel_tick;
   btn_s <= not btn;
   leds <= btn_s;
end arch;
