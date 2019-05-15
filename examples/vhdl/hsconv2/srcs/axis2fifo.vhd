library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis2fifo is
	generic (
		C_S_AXIS_DATA_WIDTH : integer := 32 -- AXI4Stream sink: Data Width
	);
	port (
	  F  : in  std_logic;
		WR : out std_logic;
		Q  : out std_logic_vector(C_S_AXIS_DATA_WIDTH downto 0);
    S_AXIS_CLK	 : in  std_logic;  -- AXI4Stream sink: Clock
    S_AXIS_RSTN  : in  std_logic;  -- AXI4Stream sink: Reset
    S_AXIS_VALID : in  std_logic;  -- Data in is valid
    S_AXIS_LAST  : in  std_logic;
    S_AXIS_STRB  : in  std_logic_vector((C_S_AXIS_DATA_WIDTH/8)-1 downto 0);
    S_AXIS_DATA  : in  std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0); -- Data in
    S_AXIS_RDY   : out std_logic -- Ready to accept data in
	);
end axis2fifo;

architecture arch of axis2fifo is
begin
  S_AXIS_RDY	<= not F;
  WR <= S_AXIS_VALID and (not F);
	Q <= S_AXIS_LAST & S_AXIS_DATA;
end architecture;
