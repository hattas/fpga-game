----------------------------------------------------------------------------------
--
-- file: game_top.vhd
-- authors: John Hattas, Margaret Huelskamp
-- created: 4/14/19
-- description: Main top file for the game.  Instantiages player unit, color map, vga sync unit, and controller units.
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
entity game_top is
    port (
		clk: in std_logic;
		sw : in std_logic_vector(9 downto 0);
		btn : in std_logic_vector(3 downto 0);
		nes_data : in std_logic;
		nes_clock, nes_latch : out std_logic;
		led: out std_logic_vector(9 downto 0) := (others => '0');
		hsync, vsync: out  std_logic;
		vga_r, vga_g, vga_b: out std_logic_vector(7 downto 0);
		vga_clk: out std_logic;
		vga_sync: out std_logic := '0';
		vga_blank: out std_logic := '1';
		ssd0, ssd1, ssd2, ssd3, ssd4, ssd5 : out std_logic_vector(6 downto 0)
	);
end game_top;

architecture arch of game_top is
	signal reset : std_logic;
    signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
    signal video_on, pixel_tick: std_logic;
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
	signal btn_s, btn_board, nes_button : std_logic_vector(7 downto 0);
	signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(3 downto 0);
	signal nes_latch_int : std_logic;
	signal nes_clock_int : std_logic;
begin
	reset <= sw(9);

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
                graph_rgb=>rgb_next, led=>led,
				hex0=>hex0, hex1=>hex1, hex2=>hex2,
				hex3=>hex3, hex4=>hex4, hex5=>hex5);
					 
	-- instantiate NES FSM
   nes_fsm_unit: entity work.nes_fsm
      port map (clk=>clk, latch=>nes_latch_int,
                pulse=>nes_clock_int, data=>nes_data,
                button=>nes_button);
					 
	-- instantiate NES clock unit
   nes_clock_unit: entity work.nes_clocks
      port map (clk=>clk, nes_clk=>nes_clock_int, nes_latch=>nes_latch_int);
   
	nes_latch <= nes_latch_int;
	nes_clock <= nes_clock_int;

   -- instantiate color mapper
	color_map_unit: entity work.color_map port map(sw, rgb_reg, vga_r, vga_g, vga_b);
	
	-- 7 segment unit
	sseg_unit : entity work.sseg port map(hex0, hex1, hex2, hex3, hex4, hex5, ssd0, ssd1, ssd2, ssd3, ssd4, ssd5);
    
   -- rgb buffer
   process (clk)
   begin
      if (clk'event and clk='1') then 
         if (pixel_tick='1') then
            rgb_reg <= rgb_next; --setting rgb_reg to the next rgb value
         end if;
      end if;
   end process;
   
   
   btn_board <= not btn(2) & not btn(3) & "0000" & not btn(0) & '0';
   with sw(4) select btn_s <=
		nes_button when '0',
		btn_board when '1';
		
   
   vga_clk <= pixel_tick;
end arch;
