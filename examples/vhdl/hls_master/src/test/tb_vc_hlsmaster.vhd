library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity vc_hlsmaster is
  generic (
    imem, omem : memory_t;
    data_width : natural := 32
  );
  port (
    clk, rstn, ap_start: in std_logic;
    ap_done, ap_idle, ap_ready: out std_logic
  );
end entity;

architecture vc of vc_hlsmaster is

  constant id_width : natural := 1;
  constant in_axi_slave : axi_slave_t := new_axi_slave(memory => imem);
  constant out_axi_slave : axi_slave_t := new_axi_slave(memory => omem);

  signal awvalid, awready, wvalid, wready, wlast, arvalid, arready, rvalid, rready, rlast, bvalid, bready: std_logic;
  signal awaddr, araddr, wdata, rdata   : std_logic_vector(data_width-1 downto 0);
  signal awid, arid, rid, bid           : std_logic_vector(id_width-1 downto 0);
  signal wstrb                          : std_logic_vector(data_width/8-1 downto 0);
  signal awlen, arlen                   : std_logic_vector(7 downto 0);
  signal awsize, arsize                 : std_logic_vector(2 downto 0);
  signal awburst, arburst, rresp, bresp : std_logic_vector(1 downto 0);
  signal empty                          : std_logic_vector(0 downto 0):=(others=>'0');

begin

  vunit_write: entity vunit_lib.axi_write_slave
  generic map ( axi_slave => out_axi_slave)
  port map (
    aclk    => clk,
    awvalid => awvalid,
    awready => awready,
    awid    => awid,
    awaddr  => awaddr,
    awlen   => awlen,
    awsize  => awsize,
    awburst => awburst,
    wvalid  => wvalid,
    wready  => wready,
    wdata   => wdata,
    wstrb   => wstrb,
    wlast   => wlast,
    bvalid  => bvalid,
    bready  => bready,
    bid     => bid,
    bresp   => bresp
  );

  vunit_read: entity vunit_lib.axi_read_slave
  generic map ( axi_slave => in_axi_slave)
  port map (
    aclk    => clk,
    arvalid => arvalid,
    arready => arready,
    arid    => arid,
    araddr  => araddr,
    arlen   => arlen,
    arsize  => arsize,
    arburst => arburst,
    rvalid  => rvalid,
    rready  => rready,
    rid     => rid,
    rdata   => rdata,
    rresp   => rresp,
    rlast   => rlast
  );

  uut: entity work.hls_master
  generic map (
    C_M_AXI_A_ADDR_WIDTH   => data_width,
    C_M_AXI_A_ID_WIDTH     => id_width,
    C_M_AXI_A_AWUSER_WIDTH => 1,
    C_M_AXI_A_DATA_WIDTH   => data_width,
    C_M_AXI_A_WUSER_WIDTH  => 1,
    C_M_AXI_A_ARUSER_WIDTH => 1,
    C_M_AXI_A_RUSER_WIDTH  => 1,
    C_M_AXI_A_BUSER_WIDTH  => 1,
    C_M_AXI_A_TARGET_ADDR  => 0,
    C_M_AXI_A_USER_VALUE   => 0,
    C_M_AXI_A_PROT_VALUE   => 0,
    C_M_AXI_A_CACHE_VALUE  => 3
  )
  port map (
    ap_clk           => clk,
    ap_rst_n         => rstn,
    ap_start         => ap_start,
    ap_done          => ap_done,
    ap_idle          => ap_idle,
    ap_ready         => ap_ready,
    m_axi_a_AWVALID  => awvalid,
    m_axi_a_AWREADY  => awready,
    m_axi_a_AWADDR   => awaddr,
    m_axi_a_AWID     => awid,
    m_axi_a_AWLEN    => awlen,
    m_axi_a_AWSIZE   => awsize,
    m_axi_a_AWBURST  => awburst,
    m_axi_a_AWLOCK   => open,
    m_axi_a_AWCACHE  => open,
    m_axi_a_AWPROT   => open,
    m_axi_a_AWQOS    => open,
    m_axi_a_AWREGION => open,
    m_axi_a_AWUSER   => open,
    m_axi_a_WVALID   => wvalid,
    m_axi_a_WREADY   => wready,
    m_axi_a_WDATA    => wdata,
    m_axi_a_WSTRB    => wstrb,
    m_axi_a_WLAST    => wlast,
    m_axi_a_WID      => open,
    m_axi_a_WUSER    => open,
    m_axi_a_ARVALID  => arvalid,
    m_axi_a_ARREADY  => arready,
    m_axi_a_ARADDR   => araddr,
    m_axi_a_ARID     => arid,
    m_axi_a_ARLEN    => arlen,
    m_axi_a_ARSIZE   => arsize,
    m_axi_a_ARBURST  => arburst,
    m_axi_a_ARLOCK   => open,
    m_axi_a_ARCACHE  => open,
    m_axi_a_ARPROT   => open,
    m_axi_a_ARQOS    => open,
    m_axi_a_ARREGION => open,
    m_axi_a_ARUSER   => open,
    m_axi_a_RVALID   => rvalid,
    m_axi_a_RREADY   => rready,
    m_axi_a_RDATA    => rdata,
    m_axi_a_RLAST    => rlast,
    m_axi_a_RID      => rid,
    m_axi_a_RUSER    => empty,
    m_axi_a_RRESP    => rresp,
    m_axi_a_BVALID   => bvalid,
    m_axi_a_BREADY   => bready,
    m_axi_a_BRESP    => bresp,
    m_axi_a_BID      => bid,
    m_axi_a_BUSER    => empty
  );

end architecture;
