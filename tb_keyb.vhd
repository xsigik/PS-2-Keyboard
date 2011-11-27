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
	signal kb_clk_stop, avalon_clk_stop, kb_clk_pause, kb_clk_high : boolean;

	procedure print_key(constant key : in std_logic_vector(7 downto 0); signal kb_data : out std_logic; signal kb_clk : out std_logic; constant clk_delay : in integer) is
	begin

		kb_clk <= '1';
		wait for 500 us;

		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		-- start bit
		kb_data <= '0';
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		kb_data <= key(0);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;
		wait for clk_delay * 1 us;
		kb_data <= key(1);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		kb_data <= key(2);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		kb_data <= key(3);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		kb_data <= key(4);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		kb_data <= key(5);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		kb_data <= key(6);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		kb_data <= key(7);
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		-- parita
		kb_data <= not (key(0) xor key(1) xor key(2) xor key(3) xor key(4) xor key(5) xor key(6) xor key(7));
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';
		wait for 65 us;

		-- stop bit
		kb_data <= '1';
		kb_clk <= '0';
		wait for 65 us;
		kb_clk <= '1';


		wait for 500 us;

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

		kb_data <= '1';
		kb_clk <= '1';

		avalon_reset_n <= '1';
		avalon_read <= '0';
		global_reset_n <= '0' after 5 ns;
		wait for 83 us;
		global_reset_n <= '1' after 5 ns;
		wait for 76 us;


		print_key(x"41",kb_data,kb_clk,0); -- A

		wait until avalon_clk = '1' and avalon_clk'event;
		wait for 80 ns;
		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;


		print_key(x"48",kb_data,kb_clk,2500); -- H
		wait for 130 us;
		wait until avalon_clk = '1' and avalon_clk'event;

		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;


		print_key(x"4F",kb_data,kb_clk,0); -- O

		wait until avalon_clk = '1' and avalon_clk'event;

		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;




		print_key(x"4A",kb_data,kb_clk,0); -- J

		wait until avalon_clk = '1' and avalon_clk'event;

		avalon_read <= '1' after 2 ns;
		wait for 20 ns;

		avalon_read <= '0' after 2 ns;
		wait for 1000 us;





        avalon_clk_stop <= true;
        wait;

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