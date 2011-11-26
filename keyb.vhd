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
	signal data_reg : std_logic_vector(8 downto 0);
	signal data_ready : std_logic;
	signal avalon_data_ready : std_logic;
	signal precteno : std_logic;
	signal key_data : std_logic_vector(7 downto 0);
	signal data_ready_clear : std_logic:='0';
	signal wdt_reset : std_logic;
	signal wdt_counter : unsigned(16 downto 0);
	signal wdt : std_logic;

begin

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

	process(kb_clk, avalon_reset_n, wdt_reset)
		variable bit_pos : integer range 0 to 11;	-- bitova pozice
		variable parita : std_logic;
	begin

		if (avalon_reset_n = '0' or wdt_reset = '1') then
			bit_pos := 0;
			data_reg <= (others => '0');
			data_ready <= '0';
			parita := '0';
			wdt <= '0';
			report "KB reset";

        elsif (kb_clk'event and kb_clk = '0') then

			wdt <= '0';

			if (bit_pos = 0 and kb_data = '0' and data_ready = '0') then --start bit
				bit_pos := 1;
				parita := '0';
				wdt <= '1';
				report "Start bit";
			elsif (bit_pos = 10) then

				bit_pos := 0;
				wdt <= '1';

				if (kb_data = '1' and parita = '1') then -- test stop bitu a parity
					data_ready <= '1';
					report "Data ready";
				else
					data_ready <= '0';
					report "Data error";
				end if;

			elsif (bit_pos >= 1) then
				data_reg <= kb_data & data_reg(8 downto 1);
				bit_pos := bit_pos + 1;
				parita := parita xor kb_data;
				wdt <= '1';
			else
				if(data_ready_clear = '1') then
					data_ready <= '0';
			   end if;
			end if;

		end if;

    end process;

	process(avalon_clk, avalon_reset_n, wdt_reset) -- resynchronizace data_ready -> avalon_data_ready
		variable dff,dff1,dff2 : std_logic;
	begin

		if(avalon_reset_n = '0') then
			dff := '0';
			dff1:= '0';
			dff2:='0';
			avalon_data_ready <= '0';
			precteno <= '0';
			key_data <= (others => '0');

		elsif(avalon_clk'event and avalon_clk = '1') then

			if(dff1 = '1' and dff2='0') then	-- detekce hrany

				key_data <= data_reg(7 downto 0);
				avalon_data_ready<='1';

			end if;

			if(avalon_read = '1') then

				avalon_data_ready <='0';
				precteno <= not precteno;

			end if;

			dff2 := dff1;
			dff1 := dff;
			dff := data_ready;
		end if;
	end process;


	process(kb_clk) -- resynchronizace data_ready_clear

		variable dff,dff1,dff2 : std_logic := '0';

	begin

		if(kb_clk='0' and kb_clk'event ) then

			data_ready_clear <= dff2 xor dff1;

			dff2 := dff1;
			dff1 := dff;
			dff := precteno;

		end if;

	end process;

	avalon_readdata <= key_data;

	avalon_irq <= avalon_data_ready;


end a_keyb;