-- convert 60 Hz reference tick to 1 Hz second tick
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_divider is
   port(
        in_tick: in std_logic;
        out_tick: out std_logic;
        time_count: in integer
   );
end clk_divider;

architecture arch of clk_divider is
    signal count: integer := 1;
begin
    -- generate second tick
    process (in_tick)
    begin
        if rising_edge(in_tick) then
            count <= count + 1;
            if count = time_count then
                out_tick <= '1';
                count <= 1;
            else
                out_tick <= '0';
            end if;
        end if;
    end process;
end arch;
