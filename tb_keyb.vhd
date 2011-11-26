-- tb_keyb.vhd
-- Jakub Valenta

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_keyb is
end tb_keyb;

architecture a_tb_keyb of tb_keyb is

    component keyb is port(
	  kb_clk : in std_logic;		-- hodiny z klavesnice
	  kb_data : in std_logic;		-- seriova data z klavesnice
	  avalon_read : in std_logic;		-- ze strany procesoru
	  avalon_readdata : out std_logic_vector(7 downto 0);
	  avalon_irq : out std_logic;	-- interrupt, data pripravena
	  avalon_clk : in std_logic;
	  avalon_reset_n : in std_logic;
	  global_reset_n : in std_logic
        );
    end component;


    signal kb_clk, kb_data, avalon_read, avalon_irq, avalon_clk, avalon_reset_n, global_reset_n : std_logic;
    signal avalon_readdata : std_logic_vector(7 downto 0);
	signal kb_clk_stop, avalon_clk_stop, kb_clk_pause : boolean;

	procedure print_key(constant key : in std_logic_vector(7 downto 0); signal kb_data : out std_logic) is
	begin

		-- start bit
		kb_data <= '0';
		wait until kb_clk = '1';

		kb_data <= key(0);
		wait until kb_clk = '1';
		kb_data <= key(1);
		wait until kb_clk = '1';
		kb_data <= key(2);
		wait until kb_clk = '1';
		kb_data <= key(3);
		wait until kb_clk = '1';
		kb_data <= key(4);
		wait until kb_clk = '1';
		wait for 100 us;
		kb_data <= key(5);
		wait until kb_clk = '1';
		kb_data <= key(6);
		wait until kb_clk = '1';
		kb_data <= key(7);
		wait until kb_clk = '1';

		-- parita
		kb_data <= not (key(0) xor key(1) xor key(2) xor key(3) xor key(4) xor key(5) xor key(6) xor key(7));
		wait until kb_clk = '1';

		-- stop bit
		kb_data <= '1';
		wait until kb_clk = '1';

		wait for 100 us;

	end print_key;

begin
    dut: keyb port map (
        kb_clk => kb_clk,
        kb_data => kb_data,
        avalon_read => avalon_read,
        avalon_irq => avalon_irq,
        avalon_clk => avalon_clk,
        avalon_reset_n => avalon_reset_n,
        avalon_readdata => avalon_readdata,
		global_reset_n => global_reset_n
    );

    wave: process
    begin

		kb_clk_pause <= false;

        avalon_reset_n <= '0';
        wait for 100 ns;
        avalon_reset_n <= '1';
        wait for 20 ns;
        avalon_read <= '0';
        wait for 20 ns;


		print_key(x"41",kb_data); -- A

		wait until avalon_clk = '1' and avalon_clk'event;
		wait for 80 ns;
		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;

		kb_clk_pause <= true;
		wait for 100 us;
		kb_clk_pause <= false;
		wait for 100 us;

		print_key(x"48",kb_data); -- H
		wait for 130 us;
		wait until avalon_clk = '1' and avalon_clk'event;

		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;


		print_key(x"4F",kb_data); -- O

		wait until avalon_clk = '1' and avalon_clk'event;

		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;




		print_key(x"4A",kb_data); -- J

		wait until avalon_clk = '1' and avalon_clk'event;

		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;





        avalon_clk_stop <= true;
		kb_clk_stop <= true;
        wait;

    end process;

    keyboard_clock: process
    begin
		if kb_clk_pause then
			wait for 1000 us;
		elsif kb_clk_stop then
			wait;
        end if;

		kb_clk <= '1';
		wait for 65 us;
		kb_clk <= '0';
		wait for 65 us;

    end process;

    avalon_clock: process
    begin
		if avalon_clk_stop then
			wait;
        end if;

        avalon_clk <= '1';
        wait for 10 ns;
        avalon_clk <= '0';
        wait for 10 ns;

    end process;

end a_tb_keyb;