library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity tb_c_hlsmaster is
  generic ( runner_cfg : string );
end entity;

architecture tb of tb_c_hlsmaster is

  constant params: integer_vector_ptr_t := new_integer_vector_ptr(6, 1);

  constant clk_step      : natural := get(params, 2);
  constant block_length  : integer := get(params, 4);
  constant data_width    : natural := get(params, 5);

  constant top_num : natural := 5;
  constant top: byte_vector_ptr_t := new_byte_vector_ptr(top_num, 2);

  constant memory : memory_t := new_memory(len => 2*block_length, id => 3);

  signal clk, rstn : std_logic := '0';
  signal done, tg : boolean := false;

  signal tops : std_logic_vector(0 to top_num-1) := (others=>'0');

  alias rst      is tops(0);
  alias ap_start is tops(1);
  alias ap_done  is tops(2);
  alias ap_idle  is tops(3);
  alias ap_ready is tops(4);

begin

  rstn <= not rst;

  clk_gen: entity vunit_lib.clk_handler generic map ( params ) port map ( rst, clk, tg );

  run: process(tg) begin if rising_edge(tg) then
    for x in 0 to top_num-1 loop
      --info("SAVE " & to_string(x+1) & " " & to_string(tops(x)));
      set(top, x, to_integer(unsigned'('0'&tops(x))));
    end loop;
    info("UPDATE READY");
    set(params, 3, 1);
  end if; end process;

  isdone: process(clk) begin if rising_edge(clk) and (??ap_done) then done <= true; end if; end process;

  main: process
    variable buf: buffer_t := allocate(memory, 1024);
  begin
    test_runner_setup(runner, runner_cfg);

    rst <= '1';
    info("Init test: " & to_string(data_width) & "-bit x" & to_string(block_length) & " | time: " & to_string(get_clk(params)));
    wait for 100 ns;
    rst <= '0';

    wait_load(params);

    ap_start <= '1';
    wait_for(clk, 2);
    ap_start <= '0';

    wait_sync(params, done, tg);
    info("Test done");
    test_runner_cleanup(runner);
    wait;
  end process;
  test_runner_watchdog(runner, 5000 ms);

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
