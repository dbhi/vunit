-- This core provides four interfaces:
-- - AXI4-Stream Slave
-- - AXI4-Stream Master
-- - FIFO Read
-- - FIFO Write
--
-- It is meant to abstract the AXI4-Stream protocol by adapting the Slave to a FIFO Read, and the Master to a FIFO Write.
-- However, the instantiation of actual FIFOs is optional, and it is independently configured through C_S_FIFO_ADR_BITS
-- and C_M_FIFO_ADR_BITS. If any of these equal to zero, no FIFO is inferred.
--
-- Note that each FIFO interface is composed of 5 signals: CLK, RST, RD/WR, E/F and D/Q. Because including a FIFO implies
-- a change in the exposed interface (from FIFO Write to FIFO Read, or vice versa) two of the signals have a different
-- meaning depending on the value of the corresponding generic parameter. I.e., when no FIFO is inferred, WR_E is the WR
-- signal coming out from axis2fifo, and F_RD is the F flag going in; but when a FIFO is inferred, WR_E is the E flag coming
-- out from the FIFO, and F_RD is the RD signal going in.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis2fifos is
	generic (
		C_S_AXIS_DATA_WIDTH	 : integer := 32;
		C_M_AXIS_DATA_WIDTH	 : integer := 32;

		C_S_FIFO_ADR_BITS : integer := 2;
		C_M_FIFO_ADR_BITS : integer := 2
	);
	port (
    CLKW: in  std_logic; -- notused       | fifoout.CLKW
		CLKR: in  std_logic; -- notused       | fifoin.CLKR
		RSTW: in  std_logic; -- notused       | fifoout.RST
		RSTR: in  std_logic; -- notused       | fifoin.RST
		E_WR: in  std_logic; -- fifos2axis.E  | fifoout.WR
		F_RD: in  std_logic; -- axis2fifo.F   | fifoin.RD
		WR_E: out std_logic; -- axis2fifo.WR  | fifoin.E
		RD_F: out std_logic; -- fifos2axis.RD | fifoout.F
	  D: in std_logic_vector(C_M_AXIS_DATA_WIDTH downto 0);
		Q: out std_logic_vector(C_S_AXIS_DATA_WIDTH downto 0);

		S_AXIS_CLK	 : in std_logic;
		S_AXIS_RSTN  : in std_logic;
		S_AXIS_RDY	 : out std_logic;
		S_AXIS_DATA	 : in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
		S_AXIS_VALID : in std_logic;
		S_AXIS_STRB  : in std_logic_vector((C_S_AXIS_DATA_WIDTH/8)-1 downto 0);
		S_AXIS_LAST  : in std_logic;

		M_AXIS_CLK	 : in std_logic;
		M_AXIS_RSTN  : in std_logic;
		M_AXIS_VALID : out std_logic;
		M_AXIS_DATA	 : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
		M_AXIS_RDY	 : in std_logic;
		M_AXIS_STRB  : out std_logic_vector((C_M_AXIS_DATA_WIDTH/8)-1 downto 0);
		M_AXIS_LAST  : out std_logic
	);
end axis2fifos;

architecture arch of axis2fifos is

	signal i_f, i_wr: std_logic;
	signal i_q: std_logic_vector(C_S_AXIS_DATA_WIDTH downto 0);

	signal o_e, o_rd: std_logic;
	signal o_d: std_logic_vector(C_M_AXIS_DATA_WIDTH downto 0);

begin

S_AXIS: entity work.axis2fifo
	generic map (
    C_S_AXIS_DATA_WIDTH	=> C_S_AXIS_DATA_WIDTH
	)
	port map (
	  F  => i_f,
	  WR => i_wr,
	  Q  => i_q,
		S_AXIS_CLK   => S_AXIS_CLK,
		S_AXIS_RSTN  => S_AXIS_RSTN,
		S_AXIS_VALID => S_AXIS_VALID,
		S_AXIS_LAST  => S_AXIS_LAST,
    S_AXIS_STRB  => S_AXIS_STRB,
		S_AXIS_DATA	 => S_AXIS_DATA,
    S_AXIS_RDY	 => S_AXIS_RDY
	);

M_AXIS: entity work.fifo2axis(preload)
	generic map (
    C_M_AXIS_DATA_WIDTH	=> C_M_AXIS_DATA_WIDTH
	)
	port map (
	  E  => o_e,
	  RD => o_rd,
	  D  => o_d,
    M_AXIS_CLK   => M_AXIS_CLK,
    M_AXIS_RSTN  => M_AXIS_RSTN,
    M_AXIS_RDY	 => M_AXIS_RDY,
    M_AXIS_VALID => M_AXIS_VALID,
    M_AXIS_DATA	 => M_AXIS_DATA,
    M_AXIS_LAST  => M_AXIS_LAST,
    M_AXIS_STRB  => M_AXIS_STRB
	);

IN_FIFO: if C_S_FIFO_ADR_BITS=0 generate begin
  i_f <= F_RD;
	WR_E <= i_wr;
	Q <= i_q;
else generate
  signal s_rst: std_logic;
begin
  s_rst <= (not S_AXIS_RSTN) or RSTR;
  FIFO: entity work.fifo
	  generic map (
	    data_width => C_S_AXIS_DATA_WIDTH+1,
      fifo_depth => C_S_FIFO_ADR_BITS
	  )
	  port map (
	    CLKW => S_AXIS_CLK,
		  CLKR => CLKR,
		  RST  => s_rst,
		  WR   => i_wr,
		  RD   => F_RD,
      D    => i_q,
      E    => WR_E,
		  F    => i_f,
      Q    => Q
	  );
end generate;

OUT_FIFO: if C_M_FIFO_ADR_BITS=0 generate begin
  o_e <= E_WR;
	RD_F <= o_rd;
	o_d <= D;
else generate
  signal m_rst: std_logic;
begin
  m_rst <= (not M_AXIS_RSTN) or RSTW;
  FIFO: entity work.fifo
	  generic map (
	    data_width => C_M_AXIS_DATA_WIDTH+1,
      fifo_depth => C_M_FIFO_ADR_BITS
	  )
	  port map (
	    CLKW => CLKW,
		  CLKR => M_AXIS_CLK,
		  RST  => m_rst,
		  WR   => E_WR,
		  RD   => o_rd,
      D    => D,
      E    => o_e,
		  F    => RD_F,
      Q    => o_d
	  );
end generate;

end architecture;
