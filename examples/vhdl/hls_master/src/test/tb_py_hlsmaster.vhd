library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity tb_hlsmaster is
  generic (
    runner_cfg : string;
    tb_path    : string
  );
end entity;

architecture tb of tb_hlsmaster is

  constant clk_period   : time    := 20 ns;
  constant data_width   : natural := 32;
  constant id_width     : natural := 1;
  constant block_length : natural := 5;

  constant memory : memory_t := new_memory;

  signal ap_start, ap_done, ap_idle, ap_ready : std_logic := '0';
  signal clk, rst, rstn                       : std_logic := '0';

begin

  clk <= not clk after (clk_period/2);
  rstn <= not rst;

  main: process
    variable buf: buffer_t := allocate(memory, 1024);
    variable tmp: std_logic_vector(data_width-1 downto 0);
    variable e, g: integer;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test") then
        info("Init test");
        rst <= '1';

        for x in 0 to block_length-1 loop
          tmp := std_logic_vector(to_signed(x, data_width));
          write_word(memory, 4*x, tmp);
          info("WRITE: " & to_string(to_integer(signed(tmp))));
        end loop;

        wait for 15*clk_period;
        wait until rising_edge(clk);
        rst <= '0';
        ap_start <= '1';
        wait for 5*clk_period;
        ap_start <= '0';
        wait until ap_done = '1';

        for x in 0 to block_length-1 loop
          e := x+100;
          g := to_integer(signed(read_word(memory, 4*(block_length+x), 4)));
          info("READ: " & to_string(g));
          if g /= e then
            error("Expected " & to_string(e) & " got " & to_string(g));
          end if;
        end loop;

        info("Test done");
      end if;
    end loop;
    test_runner_cleanup(runner);
    wait;
  end process;

--

  uut_vc: entity work.vc_hlsmaster
  generic map (
    imem       => memory,
    omem       => memory,
    data_width => data_width
  )
  port map (
    clk      => clk,
    rstn     => rstn,
    ap_start => ap_start,
    ap_done  => ap_done,
    ap_idle  => ap_idle,
    ap_ready => ap_ready
  );

end architecture;
