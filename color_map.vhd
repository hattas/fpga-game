-- map 3 bit colors to 8 bit
library ieee;
use ieee.std_logic_1164.all;
entity color_map is
   port (
      rgb: in std_logic_vector(2 downto 0);
		vga_r: out std_logic_vector(7 downto 0);
		vga_g: out std_logic_vector(7 downto 0);
		vga_b: out std_logic_vector(7 downto 0)
   );
end color_map;

architecture arch of color_map is
	signal vga_rgb: std_logic_vector(23 downto 0);
begin

	process(rgb)
	begin
		 case rgb is
			  when "000" => vga_rgb <= x"222222"; --black
			  when "001" => vga_rgb <= x"003F3F";
			  when "010" => vga_rgb <= x"007F7F";
			  when "011" => vga_rgb <= x"00BFBF";
			  when "100" => vga_rgb <= x"00FFFF";
			  when "101" => vga_rgb <= x"55FFFF";
			  when "110" => vga_rgb <= x"AAFFFF";
			  when "111" => vga_rgb <= x"FFFFFF"; --white
			  when others => vga_rgb <= x"FF0000";
		 end case;
	end process;
	
	vga_r <= vga_rgb(23 downto 16);
	vga_g <= vga_rgb(15 downto 8);
	vga_b <= vga_rgb(7 downto 0);
end arch;