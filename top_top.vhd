-- used to wrap book example code to adapt to the De1-SoC's VGA
-- maps 3 bit to 24 bit color and adds other VGA signals
library ieee;
use ieee.std_logic_1164.all;
entity top_top is
   port (
      clk, reset: in std_logic;
      btn: in std_logic_vector (1 downto 0);
      hsync, vsync: out  std_logic;
	  vga_r, vga_g, vga_b: out std_logic_vector(7 downto 0);
      vga_clk: out std_logic;
      vga_sync: out std_logic := '0';
      vga_blank: out std_logic := '1'
   );
end top_top;

architecture arch of top_top is
   signal rgb: std_logic_vector(2 downto 0);
   signal btn_s: std_logic_vector(1 downto 0);
begin
   pong_top_unit: entity work.pong_top_an
      port map(clk=>clk, reset=>reset,
               btn=>btn_s, hsync=>hsync,
               vsync=>vsync, rgb=>rgb);
   
   btn_s <= not btn;
   vga_r <= (others => '1') when rgb(2)='1' else (others => '0');
   vga_g <= (others => '1') when rgb(1)='1' else (others => '0');
   vga_b <= (others => '1') when rgb(0)='1' else (others => '0');
   vga_clk <= clk;
   
end arch;