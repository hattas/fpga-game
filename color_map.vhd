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
	signal vga_rgb, vga_rgb_cyan, vga_rgb_magenta, vga_rgb_bw, vga_rgb_3: std_logic_vector(23 downto 0);
begin

	process(rgb)
	begin
		 case rgb is
			  when "000" => vga_rgb_cyan <= x"222222"; --black
			  when "001" => vga_rgb_cyan <= x"003F3F";
			  when "010" => vga_rgb_cyan <= x"007F7F";
			  when "011" => vga_rgb_cyan <= x"00BFBF";
			  when "100" => vga_rgb_cyan <= x"00FFFF";
			  when "101" => vga_rgb_cyan <= x"55FFFF";
			  when "110" => vga_rgb_cyan <= x"AAFFFF";
			  when "111" => vga_rgb_cyan <= x"FFFFFF"; --white
			  when others => vga_rgb_cyan <= x"FF0000";
		 end case;
		 
		 case rgb is
			  when "000" => vga_rgb_magenta <= x"222222"; --black
			  when "001" => vga_rgb_magenta <= x"3F003F";
			  when "010" => vga_rgb_magenta <= x"7F007F";
			  when "011" => vga_rgb_magenta <= x"BF00BF";
			  when "100" => vga_rgb_magenta <= x"FF00FF";
			  when "101" => vga_rgb_magenta <= x"FF55FF";
			  when "110" => vga_rgb_magenta <= x"FFAAFF";
			  when "111" => vga_rgb_magenta <= x"FFFFFF"; --white
			  when others => vga_rgb_magenta <= x"FF0000";
		 end case;
		 
		 case rgb is
			  when "000" => vga_rgb_bw <= x"000000"; --black
			  when "001" => vga_rgb_bw <= x"242424";
			  when "010" => vga_rgb_bw <= x"484848";
			  when "011" => vga_rgb_bw <= x"6D6D6D";
			  when "100" => vga_rgb_bw <= x"919191";
			  when "101" => vga_rgb_bw <= x"B6B6B6";
			  when "110" => vga_rgb_bw <= x"DADADA";
			  when "111" => vga_rgb_bw <= x"FFFFFF"; --white
			  when others => vga_rgb_bw <= x"FF0000";
		 end case;
		 
		 case rgb is
			  when "000" => vga_rgb_3 <= x"000000"; --black
			  when "001" => vga_rgb_3 <= x"0000FF";
			  when "010" => vga_rgb_3 <= x"00FF00";
			  when "011" => vga_rgb_3 <= x"00FFFF";
			  when "100" => vga_rgb_3 <= x"FF0000";
			  when "101" => vga_rgb_3 <= x"FF00FF";
			  when "110" => vga_rgb_3 <= x"FFFF00";
			  when "111" => vga_rgb_3 <= x"FFFFFF"; --white
			  when others => vga_rgb_3 <= x"FF0000";
		 end case;
	end process;
	
	
	with sw(1 downto 0) select vga_rgb <=
		vga_rgb_cyan 	when "00",
		vga_rgb_magenta when "01",
		vga_rgb_bw   	when "10",
		vga_rgb_3 		when "11";
	
	
	vga_r <= vga_rgb(23 downto 16);
	vga_g <= vga_rgb(15 downto 8);
	vga_b <= vga_rgb(7 downto 0);
end arch;