-- map 3 bit colors to 8 bit
library ieee;
use ieee.std_logic_1164.all;
entity color_map is
    port (
		sw : in std_logic_vector(9 downto 0);
		rgb: in std_logic_vector(2 downto 0);
		vga_r: out std_logic_vector(7 downto 0);
		vga_g: out std_logic_vector(7 downto 0);
		vga_b: out std_logic_vector(7 downto 0)
    );
end color_map;

architecture arch of color_map is
	signal sw_off, sw_on : std_logic_vector(7 downto 0);
begin
	
	with sw(2) select vga_r <= sw_off when '0', sw_on when '1';
	with sw(1) select vga_g <= sw_off when '0', sw_on when '1';
	with sw(0) select vga_b <= sw_off when '0', sw_on when '1';

	process(rgb)
	begin
		 case rgb is
			when "000" =>
				sw_off <= x"00"; sw_on <= x"00";
			when "001" =>
				sw_off <= x"00"; sw_on <= x"3F";
			when "010" =>
				sw_off <= x"00"; sw_on <= x"7F";
			when "011" =>
				sw_off <= x"00"; sw_on <= x"BF";
			when "100" =>
				sw_off <= x"00"; sw_on <= x"FF";
			when "101" =>
				sw_off <= x"55"; sw_on <= x"FF";
			when "110" =>
				sw_off <= x"AA"; sw_on <= x"FF";
			when "111" =>
				sw_off <= x"FF"; sw_on <= x"FF";
			when others =>
				sw_off <= x"00"; sw_on <= x"00";
		 end case;
	end process;
end arch;