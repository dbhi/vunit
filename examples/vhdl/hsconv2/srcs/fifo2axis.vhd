library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo2axis is
	generic (
		C_M_AXIS_DATA_WIDTH : integer := 32
	);
	port (
	  E  : in  std_logic;
	  RD : out std_logic;
	  D  : in  std_logic_vector(C_M_AXIS_DATA_WIDTH downto 0);
    M_AXIS_CLK	 : in std_logic;
    M_AXIS_RSTN  : in std_logic;
    M_AXIS_RDY   : in std_logic;
    M_AXIS_VALID : out std_logic;
    M_AXIS_DATA  : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    M_AXIS_LAST  : out std_logic;
    M_AXIS_STRB  : out std_logic_vector((C_M_AXIS_DATA_WIDTH/8)-1 downto 0)
	);
end fifo2axis;

architecture arch of fifo2axis is
  signal do: std_logic;
begin
  process(M_AXIS_CLK) begin if rising_edge(M_AXIS_CLK) then
    if (M_AXIS_RSTN = '0') then
	    M_AXIS_VALID <= '0';
	  else
      M_AXIS_VALID <= do;
	end if;
  end if; end process;
  do <= (not E) and M_AXIS_RDY;
  RD <= do;
  M_AXIS_DATA	<= D(C_M_AXIS_DATA_WIDTH-1 downto 0);
  M_AXIS_LAST  <= D(D'left);
  M_AXIS_STRB  <= (others=>'1');
end architecture;

architecture preload of fifo2axis is
  signal do, valid: std_logic;
begin
  process(M_AXIS_CLK) begin if rising_edge(M_AXIS_CLK) then
    if ((not M_AXIS_RSTN) or ((valid and E) and M_AXIS_RDY))='1' then
	    valid <= '0';
	  elsif do then
			valid <= '1';
		else
			valid <= valid;
		end if;
  end if; end process;
	M_AXIS_VALID <= valid;
  do <= (not E) and (valid nand (not M_AXIS_RDY));
  RD <= do;
  M_AXIS_DATA	<= D(C_M_AXIS_DATA_WIDTH-1 downto 0);
  M_AXIS_LAST <= D(D'left);
  M_AXIS_STRB <= (others=>'1');
end architecture;
