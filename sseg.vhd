----------------------------------------------------------------------------------
--
-- file: sseg.vhd
-- authors: John Hattas, Margaret Huelskamp
-- created: 4/8/19
-- description: hexadecimal digit to seven-segment LED display decoder
-- 		adapted from Pong P. Chu's book; page 56;  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity sseg is
	port(
		hex0, hex1, hex2, hex3, hex4, hex5 : in std_logic_vector(3 downto 0);
		sseg0, sseg1, sseg2, sseg3, sseg4, sseg5 : out std_logic_vector(6 downto 0)
	);
end sseg;

architecture arch of sseg is
begin
	u0: entity work.hex_to_sseg port map(hex0, sseg0);
	u1: entity work.hex_to_sseg port map(hex1, sseg1);
	u2: entity work.hex_to_sseg port map(hex2, sseg2);
	u3: entity work.hex_to_sseg port map(hex3, sseg3);
	u4: entity work.hex_to_sseg port map(hex4, sseg4);
	u5: entity work.hex_to_sseg port map(hex5, sseg5);
end arch;
