-- test the nes driver circuit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nes_test is
   port(
        clk, reset : std_logic;
        btn : std_logic_vector(7 downto 0);
        video_on : in std_logic;
        pixel_x, pixel_y : in std_logic_vector(9 downto 0);
        graph_rgb : out std_logic_vector(2 downto 0);
        sec_tick : out std_logic;
        led: out std_logic_vector(9 downto 0) := (others => '0')
   );
end nes_test;

architecture arch of nes_test is
   signal refr_tick, second_tick: std_logic;
   signal screen_on : std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
	
begin
	
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';
   
   process(video_on, pix_x, pix_y, btn)
   begin
      if video_on='0' then
          screen_on <= '0'; --blank
      else
			if pix_x < 80 then
				screen_on <= btn(1);
			elsif pix_x < 160 then
				screen_on <= btn(1);
			elsif pix_x < 240 then
				screen_on <= btn(2);
			elsif pix_x < 320 then
				screen_on <= btn(3);
			elsif pix_x < 400 then
				screen_on <= btn(4);
			elsif pix_x < 480 then
				screen_on <= btn(5);
			elsif pix_x < 560 then
				screen_on <= btn(6);
			else
				screen_on <= btn(7);
			end if;
       end if;
    end process;
   
    with screen_on select graph_rgb <=
		"000" when '0',
		"111" when '1';
	
	led(7 downto 0) <= btn;
end arch;
