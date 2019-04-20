-- convert 60 Hz reference tick to 1 Hz second tick
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_divider is
   port(
        clk: in std_logic;
        refr_tick: in std_logic;
        second_tick: out std_logic
   );
end clk_divider;

architecture arch of clk_divider is
    signal count: integer := 0;
begin
    -- generate second tick
    process (refr_tick)
    begin
        if rising_edge(refr_tick) then
            count <= count + 1;
            if count = 59 then
                second_tick <= '1';
                count <= 0;
            else
                second_tick <= '0';
            end if;
        end if;
    end process;
end arch;
