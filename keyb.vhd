-- keyb.vhd
-- Jakub Valenta
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyb is port(
	kb_clk : in std_logic;		-- hodiny z klavesnice
	kb_data : in std_logic;		-- seriova data z klavesnice
	avalon_read : in std_logic;	-- ze strany procesoru
	avalon_readdata : out std_logic_vector(7 downto 0);
	avalon_irq : out std_logic;	-- interrupt, data pripravena
	avalon_clk : in std_logic;
	avalon_reset_n : in std_logic;
	global_reset_n : in std_logic
);
end keyb;

architecture a_keyb of keyb is
	signal bit_position : unsigned(3 downto 0);
	signal data_reg : std_logic_vector(8 downto 0);
	signal data_ready : std_logic;
	signal avalon_data_ready : std_logic;
	signal avalon_buffer : std_logic_vector(7 downto 0);
	signal avalon_error : std_logic;
	signal wdt_reset : std_logic;
	signal wdt_counter : unsigned(16 downto 0);
	signal wdt : std_logic;
	signal reset_n : std_logic;

begin

process(avalon_clk, global_reset_n)
	variable dff1, dff2 : std_logic;
begin

	if (global_reset_n = '0') then
		dff1 := '0';
		dff2 := '0';
		reset_n <= '0';
	elsif (avalon_clk'event and avalon_clk = '1') then

		dff2 := dff1;
		dff1 := '1';

		reset_n <= dff2 and avalon_reset_n;

	end if;


end process;

process(avalon_clk, wdt)
begin

	if (wdt = '0') then
		wdt_counter <= (others => '0');
		wdt_reset <= '0';

	elsif (avalon_clk'event and avalon_clk = '1') then

		if (wdt_counter > 125000) then	-- max. doba paketu nesmi byt vic nez 2ms => avalon_clk T=20ns => 2ms/20n = 100000 + rezerva
			wdt_reset <= '1';
		else
			wdt_counter <= wdt_counter + 1;
		end if;

	end if;

end process;

process(kb_clk, reset_n, wdt_reset)
	variable parity : std_logic;
begin

	if (reset_n = '0' or wdt_reset = '1') then

		parity := '0';
		bit_position <= (others => '0');
		data_reg <= (others => '0');
		data_ready <= '0';
		wdt <= '0';

	elsif (kb_clk'event and kb_clk = '0') then

		if (bit_position = 0 and kb_data = '0') then	-- start bit
			parity := '0';
			bit_position <= (0 => '1', others => '0');
			data_ready <= '0';
			wdt <= '1';

		elsif (bit_position = 10) then

			wdt <= '0';
			bit_position <= (others => '0');

			if (kb_data = '1' and parity = '1') then
				data_ready <= '1';
				report "Data ready" severity note;
			else
				data_ready <= '0';
				report "Data error" severity note;
			end if;

		elsif (bit_position >= 1) then
			data_reg <= kb_data & data_reg(8 downto 1);
			parity := parity xor kb_data;
			bit_position <= bit_position + 1;

		end if;

	end if;

end process;

process(avalon_clk, reset_n)
	variable dff1, dff2, dff3 : std_logic;
begin

	if (reset_n = '0') then
		dff1 := '0';
		dff2 := '0';
		dff3 := '0';
		avalon_data_ready <= '0';
		avalon_buffer <= (others => '0');
		avalon_error <= '0';

	elsif (avalon_clk'event and avalon_clk = '1') then

		if (dff2 = '1' and dff3 = '0') then
			if (avalon_data_ready = '1') then
				avalon_error <= '1';
			end if;
			avalon_data_ready <= '1';
			avalon_buffer <= data_reg(7 downto 0);
		end if;

		if(avalon_read = '1') then
			avalon_data_ready <='0';
		end if;

		dff3 := dff2;
		dff2 := dff1;
		dff1 := data_ready;

	end if;

end process;

avalon_irq <= avalon_data_ready;
avalon_readdata <= avalon_buffer;

end a_keyb;