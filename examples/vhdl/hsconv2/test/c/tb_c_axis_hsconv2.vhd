library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;
--use vunit_lib.core_pkg.stop;

library work;
use work.f.wl;

entity tb_c_axis_hsconv2 is
  generic (
    runner_cfg : string;
    verbose    : boolean := false
  );
end entity;

library ieee;
context ieee.ieee_std_context;

architecture tb of tb_c_axis_hsconv2 is

  constant params: integer_vector_ptr_t := new_integer_vector_ptr(10, -1);

  constant clk_step       : natural  := get(params, 2);
  constant data_width     : positive := get(params, 4);
  constant window_width   : positive := get(params, 5);
  constant zpadding       : boolean  := get(params, 6)=1;
  constant band_depth     : positive := get(params, 7);
  constant spatial_width  : positive := get(params, 8);
  constant spatial_height : positive := get(params, 9);

  constant ibuffer: integer_vector_ptr_t := new_integer_vector_ptr(spatial_width*spatial_height*band_depth, -2); --2
  constant obuffer: integer_vector_ptr_t := new_integer_vector_ptr(spatial_width*spatial_height*band_depth, -3); --3

  impure function get (
    buf: integer_vector_ptr_t;
    y, x: integer
  ) return integer is begin
    return get(buf, y*band_depth+x);
  end;

  procedure set (
    buf: integer_vector_ptr_t;
    y, x, z: integer
  ) is begin
    set(buf, y*band_depth+x, z);
  end;

  constant C_AXIS_TDATA_WIDTH: natural := 32;

  constant m_axis : axi_stream_master_t := new_axi_stream_master (data_length => data_width);
  constant s_axis : axi_stream_slave_t  := new_axi_stream_slave  (data_length => data_width);

  signal clk, rst, nrst: std_logic := '0';
  signal start, sent, saved, tg, done: boolean:=false;

begin

  nrst <= not rst;

  clk_gen: entity vunit_lib.clk_handler generic map ( params ) port map ( rst, clk, tg );

  run: process(tg) begin if rising_edge(tg) then
    info("SAVE");
    set(params, 3, 1);
  end if; end process;

  main: process begin
    test_runner_setup(runner, runner_cfg);
    info("Init test");
    info("clk_step: " & to_string(clk_step));
    info("data_width: " & to_string(data_width));
    info("window_width: " & to_string(window_width));
    info("zpadding: " & to_string(zpadding));
    info("band_depth: " & to_string(band_depth));
    info("spatial_width: " & to_string(spatial_width));
    info("spatial_height: " & to_string(spatial_height));
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait_load(params);
    wait until rising_edge(clk); start <= true;
    wait until rising_edge(clk); start <= false;
    --wait until (sent and saved and rising_edge(clk));
    wait_sync(params, done, tg);
    info("Test done");
    test_runner_cleanup(runner);
    wait;
  end process;
  --test_runner_watchdog(runner, 30 ms);

  done <= sent and saved;

  stimuli: process

    procedure send_row(
      constant buf: integer_vector_ptr_t;
      constant b: integer; -- number of bands
      constant y: integer; -- row number
      constant e: boolean  -- zeros
    ) is
      variable last: std_logic := '0';
      variable dat: signed(data_width-1 downto 0);
    begin
      for x in 0 to b-1 loop
        if x = b-1 then last := '1'; else last := '0'; end if;
        dat := to_signed(0, data_width) when e else to_signed(get(buf, y, x), data_width);
        push_axi_stream(net, m_axis, std_logic_vector(dat), tlast => last);
        if (verbose) then
          info("Sent (" & to_string(y) & "," & to_string(x) & ") : " & to_string(to_integer(signed(dat))));
        end if;
      end loop;
    end procedure;

    procedure send_buf(
      constant buf: integer_vector_ptr_t;
      constant id: string;
      constant depth: positive;
      constant s_width: positive;
      constant s_height: positive;
      constant window: positive;
      constant zpad: boolean
    ) is
      variable i: std_logic_vector(data_width-1 downto 0);
      variable last: std_logic := '0';
    begin
      for y in 0 to s_width-1 loop
        send_row(buf, depth, 0, zpad);
        info("Sent first " & to_string(y));
      end loop;
      for y in 0 to s_width*s_height-1 loop
        send_row(buf, depth, y, false);
        info("Sent row " & to_string(y));
      end loop;
      for y in 0 to s_width-1 loop
        send_row(buf, depth, s_width*s_height-1, zpad);
        info("Sent last " & to_string(y));
      end loop;
      for y in 0 to window*s_width*depth loop
        send_row(buf, depth, s_width*s_height-1, true);
        info("Sent fill " & to_string(y));
      end loop;
    end procedure;

  begin
    sent <= false;
    wait until start and rising_edge(clk);
    info("Send input data: " & to_string(spatial_width*spatial_height) & "x" & to_string(band_depth));
    send_buf(ibuffer, "I", band_depth, spatial_width, spatial_height, window_width, zpadding);
    wait until rising_edge(clk);
    info("Input data sent to UUT");
    sent <= true;
    wait;
  end process;

  save: process

    procedure receive_buf (
      constant buf: integer_vector_ptr_t;
      constant id: in string
    ) is
      variable last: std_logic := '0';
      variable o: std_logic_vector(data_width-1 downto 0);
    begin
      for y in 0 to spatial_width*spatial_height-1 loop
        for x in 0 to band_depth-1 loop
          pop_axi_stream(net, s_axis, tdata => o, tlast => last);
          if (verbose) then
            info("Received (" & to_string(y) & "," & to_string(x) & ") : " & to_string(to_integer(signed(o))));
          end if;
          set(buf, y, x, to_integer(signed(o)));
        end loop;
        info("Received row " & to_string(y));
      end loop;
    end procedure;

  begin
    saved <= false;
    wait until start and rising_edge(clk);
    wait_for(clk, 100);
    receive_buf(obuffer, "O");
    info("Output data received from UUT");
    wait until rising_edge(clk);
    saved <= true;
    wait;
  end process;

--

  uut_vc: entity work.vc_hsconv2
  generic map(
    m_axis          => m_axis,
    s_axis          => s_axis,
    data_width      => data_width,
    window_width    => window_width,
    band_depth      => band_depth,
    line_width      => spatial_width,
    zpadding        => zpadding,
    axis_data_width => C_AXIS_TDATA_WIDTH
  )
  port map (
    clk  => clk,
    rst  => rst
  );

end architecture;
