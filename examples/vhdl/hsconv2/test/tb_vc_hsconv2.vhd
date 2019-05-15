library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;
use vunit_lib.array_pkg.all;

use work.f.wl;

entity vc_hsconv2 is
  generic (
    m_axis          : axi_stream_master_t;
    s_axis          : axi_stream_slave_t;
    data_width      : natural:=16;
    window_width    : positive;
    band_depth      : positive;
    line_width      : positive;
    zpadding        : boolean;
    axis_data_width : natural:=32
  );
  port (
    clk, rst: in std_logic
  );
end entity;

library ieee;
context ieee.ieee_std_context;

architecture vc of vc_hsconv2 is

  function buffer_min_size(b,w,k: integer) return integer is
  begin
    return wl(b * (w - k) - 1);
  end function;

  -- Signals to/from the UUT from/to the verification components

  type axis_t is record
    rdy, valid, last: std_logic;
    strb: std_logic_vector((data_width/8)-1 downto 0);
    data: std_logic_vector(data_width-1 downto 0);
  end record;

  signal m, s: axis_t;

  type fifo_t is record
    c, f: std_logic;
    v: std_logic_vector(data_width downto 0);
  end record;

  signal wr, rd, e, f: std_logic;
  signal d: std_logic_vector(data_width downto 0);
  signal q: std_logic_vector(data_width downto 0);

  -- Signals to/from the UUT from/to the buffer

  type axis_buf_t is record
    rdy, valid, last: std_logic;
    data: std_logic_vector(axis_data_width-1 downto 0);
    strb: std_logic_vector(3 downto 0);
  end record;

  signal buf_m, buf_s: axis_buf_t;

  -- tb signals and variables

  signal rstn, c_zpadding: std_logic;

begin

  rstn <= not rst;

-- AXI4Stream Verification Components

  vunit_axis_m: entity vunit_lib.axi_stream_master
  generic map (
    master => m_axis)
  port map (
    aclk   => clk,
    tvalid => m.valid,
    tready => m.rdy,
    tdata  => m.data,
    tlast  => m.last);

  vunit_axis_s: entity vunit_lib.axi_stream_slave
  generic map (
    slave => s_axis)
  port map (
    aclk   => clk,
    tvalid => s.valid,
    tready => s.rdy,
    tdata  => s.data,
    tlast  => s.last);

-- The main I/O of the UUT are FIFOs
-- Adapt AXI4Stream Master/Slave from/to FIFOs

  m.strb <= (others=>'1');

  data_in: entity work.axis2fifo
    generic map (
      C_S_AXIS_DATA_WIDTH => data_width
    )
    port map (
      F            => f,
      WR           => wr,
      Q            => d,
      S_AXIS_CLK   => clk,
      S_AXIS_RSTN  => rstn,
      S_AXIS_RDY   => m.rdy,
      S_AXIS_DATA  => m.data,
      S_AXIS_VALID => m.valid,
      S_AXIS_STRB  => m.strb,
      S_AXIS_LAST  => m.last
    );

  data_out: entity work.fifo2axis
    generic map (
      C_M_AXIS_DATA_WIDTH => data_width
    )
    port map (
      E            => e,
      D            => q,
      RD           => rd,
      M_AXIS_CLK   => clk,
      M_AXIS_RSTN  => rstn,
      M_AXIS_RDY   => s.rdy,
      M_AXIS_DATA  => s.data,
      M_AXIS_VALID => s.valid,
      M_AXIS_STRB  => s.strb,
      M_AXIS_LAST  => s.last
    );

-- The UUT requires a buffer with AXI4Stream interfaces to hold intermediate values.
-- Buffer (AXI4 Stream FIFO loop)

  buf: entity work.axis_buffer
  generic map (
    data_width => axis_data_width,
    fifo_depth => buffer_min_size(band_depth, line_width, window_width)
  )
  port map (
    s_axis_clk   => clk,
    s_axis_rstn  => rstn,
    s_axis_rdy   => buf_m.rdy,
    s_axis_data  => buf_m.data,
    s_axis_valid => buf_m.valid,
    s_axis_strb  => buf_m.strb,
    s_axis_last  => buf_m.last,
    m_axis_clk   => clk,
    m_axis_rstn  => rstn,
    m_axis_valid => buf_s.valid,
    m_axis_data  => buf_s.data,
    m_axis_rdy   => buf_s.rdy,
    m_axis_strb  => buf_s.strb,
    m_axis_last  => buf_s.last
  );

  -- Unit Under Test

  c_zpadding <= '1' when zpadding else '0';

  uut: entity work.hsconv2
    generic map(
      C_WINDOW_WIDTH => window_width,
      C_LINE_WIDTH   => line_width,
      C_BAND_DEPTH   => band_depth,
      C_DATA_WIDTH   => data_width,
      C_AXIS_TDATA_WIDTH => axis_data_width
    )
    port map (
      CLK  => clk,
      RST  => rst,
      Z    => c_zpadding,
      CLKW => clk,
      CLKR => clk,
      WR   => wr,
      RD   => rd,
      E    => e,
      F    => f,
      D    => d,
      Q    => q,
      S_AXIS_ACLK    => clk,
      S_AXIS_ARESETN => rstn,
      S_AXIS_TREADY  => buf_s.rdy,
      S_AXIS_TDATA   => buf_s.data,
      S_AXIS_TVALID  => buf_s.valid,
      S_AXIS_TSTRB   => buf_s.strb,
      S_AXIS_TLAST   => buf_s.last,
      M_AXIS_ACLK    => clk,
      M_AXIS_ARESETN => rstn,
      M_AXIS_TVALID  => buf_m.valid,
      M_AXIS_TDATA   => buf_m.data,
      M_AXIS_TREADY  => buf_m.rdy,
      M_AXIS_TSTRB   => buf_m.strb,
      M_AXIS_TLAST   => buf_m.last
    );

end architecture;
