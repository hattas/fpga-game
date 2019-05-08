----------------------------------------------------------------------------------
--
-- file: gravity_divider.vhd
-- authors: John Hattas, Margaret Huelskamp
-- created: 5/3/19
-- description: Generates gravity tick time_count clock ticks after player leaves ground.
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gravity_divider is
   port(
		on_ground: in std_logic;
        in_tick: in std_logic;
        out_tick: out std_logic;
        time_count: in integer
   );
end gravity_divider;

architecture arch of gravity_divider is
    signal count: integer := 1;
begin
    -- generate second tick
    process (in_tick)
    begin
        if rising_edge(in_tick) then
            count <= count + 1;
			if on_ground = '1' then
				out_tick <= '0';
				count <= 1;
            elsif count = time_count then
                out_tick <= '1';
                count <= 1;
            else
                out_tick <= '0';
            end if;
        end if;
    end process;
end arch;
