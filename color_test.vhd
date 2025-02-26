----------------------------------------------------------------------------------
--
-- file: color_test.vhd
-- authors: John Hattas, Margaret Huelskamp
-- created: 4/14/19
-- description: Display the 8 colors to the screen in bars.
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity color_test is
   port(
        clk, reset : std_logic;
        btn : std_logic_vector(3 downto 0);
        video_on : in std_logic;
        pixel_x, pixel_y : in std_logic_vector(9 downto 0);
        graph_rgb : out std_logic_vector(2 downto 0);
        sec_tick : out std_logic;
        col_led: out std_logic_vector(3 downto 0)
   );
end color_test;

architecture arch of color_test is
   signal refr_tick, second_tick: std_logic;
   signal wall_on: std_logic;
   
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   
   -- signals to count time
   constant TIMECONST: integer := 10;
   signal count: integer := 0;
   signal color_add: unsigned(2 downto 0) := "000";
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
   
    process (refr_tick)
    begin
        if refr_tick = '1' then
            count <= count + 1;
            if count = TIMECONST then
                second_tick <= '1';
                count <= 0;
            else
                second_tick <= '0';
            end if;
        end if;
    end process;
    
    process(second_tick)
    begin
        if second_tick = '1' then
            color_add <= color_add + 1;
        end if;
    end process;

   
   process(video_on)
   begin
      if video_on='0' then
          graph_rgb <= "000"; --blank
      else
			if pix_x < 80 then
				graph_rgb <= "000";
			elsif pix_x < 160 then
				graph_rgb <= "001";
			elsif pix_x < 240 then
				graph_rgb <= "010";
			elsif pix_x < 320 then
				graph_rgb <= "011";
			elsif pix_x < 400 then
				graph_rgb <= "100";
			elsif pix_x < 480 then
				graph_rgb <= "101";
			elsif pix_x < 560 then
				graph_rgb <= "110";
			else
				graph_rgb <= "111";
			end if;
      end if;
   end process;
end arch;
