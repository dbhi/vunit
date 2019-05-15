library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;
use vunit_lib.array_pkg.all;
library JSON;
context JSON.json_ctx;

use work.f.wl;

entity tb_py_axis_hsconv2 is
  generic (
    runner_cfg : string;
    tb_path    : string;
    json_cfg   : string;
    verbose    : boolean := true
  );
end entity;

library ieee;
context ieee.ieee_std_context;

architecture tb of tb_py_axis_hsconv2 is

-- tb_cfg contains stringified content
  constant Content : T_JSON := jsonLoad(json_cfg);

  constant tb_cfg_file_in      : string   := jsonGetString(Content, "file_in");
  constant tb_cfg_file_out     : string   := jsonGetString(Content, "file_out");
  constant tb_cfg_window_width : positive := positive'value( jsonGetString(Content, "window_width"));
  constant tb_cfg_band_depth   : positive := positive'value( jsonGetString(Content, "band_depth"));
  constant tb_cfg_line_width   : positive := positive'value( jsonGetString(Content, "line_width"));
  constant tb_cfg_zpadding     : boolean  := jsonGetBoolean(Content, "zpadding");

  -- Simulation constants

  constant clk_period: time := 12 ns;

  constant tb_cfg_data_width: natural:=16;
  constant C_AXIS_TDATA_WIDTH: natural:=32;

  -- AXI4Stream Verification Components

  constant m_axis : axi_stream_master_t := new_axi_stream_master(data_length => tb_cfg_data_width);
  constant s_axis : axi_stream_slave_t := new_axi_stream_slave(data_length => tb_cfg_data_width);

  -- tb signals and variables

  signal clk, rst, nrst: std_logic := '0';
  signal start, sent, saved: boolean:=false;

  shared variable data_I, data_O: array_t;

begin

  clk <= not clk after clk_period/2;
  nrst <= not rst;

  main: process begin
    test_runner_setup(runner, runner_cfg);
    info("Init test " & json_cfg);
    rst <= '1';
    wait for 15*clk_period;
    rst <= '0';
    wait until rising_edge(clk); start <= true;
    wait until rising_edge(clk); start <= false;
    wait until (sent and saved and rising_edge(clk));
    info("Test done");
    test_runner_cleanup(runner);
    wait;
  end process;
  test_runner_watchdog(runner, 20 ms);

--

  stimuli: process

    procedure send_row(
      variable csv: inout array_t;
      constant x:   integer;
      constant e:   boolean
    ) is
      variable last: std_logic := '0';
      variable dat: signed(tb_cfg_data_width-1 downto 0);
    begin
      for y in 0 to csv.width-1 loop
        if y = csv.width-1 then last := '1'; else last := '0'; end if;
        dat := to_signed(0, tb_cfg_data_width) when e else to_signed(csv.get(y,x), tb_cfg_data_width);
        push_axi_stream(net, m_axis, std_logic_vector(dat), tlast => last);
        if (verbose) then
          info("Sent (" & to_string(x) & "," & to_string(y) & ") : " & to_string(to_integer(signed(dat))));
        end if;
      end loop;
    end procedure;

    procedure send_csv(
      variable csv: inout array_t;
      constant id: string;
      constant band_depth: positive;
      constant line_width: positive;
      constant window_width: positive;
      constant zpadding: boolean;
      line_num : natural := 0;
      file_name : string := ""
    ) is
      variable i: std_logic_vector(tb_cfg_data_width-1 downto 0);
      variable last: std_logic := '0';
    begin
      info("Sending <"& id &"> of size " & to_string(csv.height) & "x" & to_string(csv.width) & " to UUT...",
        line_num => line_num, file_name => file_name);
      for x in 0 to line_width-1 loop
        send_row(csv, 0, zpadding);
        info("Sent first " & to_string(x));
      end loop;
      for x in 0 to csv.height-1 loop
        send_row(csv, x, false);
        info("Sent row " & to_string(x));
      end loop;
      for x in 0 to line_width-1 loop
        send_row(csv, csv.height-1, zpadding);
        info("Sent last " & to_string(x));
      end loop;
      for x in 0 to window_width*line_width*band_depth loop
        send_row(csv, csv.height-1, true);
        info("Sent fill " & to_string(x));
      end loop;
      info("<"& id &"> sent to UUT",
        line_num => line_num, file_name => file_name);
    end procedure;

  begin
    sent <= false;
    wait until start and rising_edge(clk);
    data_I.load_csv(tb_cfg_file_in);
    info("Read <I> of size " & to_string(data_I.height) & "x" & to_string(data_I.width) & " from <" & tb_cfg_file_in & ">");
    wait until rising_edge(clk);
    info("Send input data");
    send_csv(data_I, "I", tb_cfg_band_depth, tb_cfg_line_width, tb_cfg_window_width, tb_cfg_zpadding);
    wait until rising_edge(clk);
    sent <= true;
    wait;
  end process;

--

  save: process

    procedure receive_csv (
      variable csv: inout array_t;
      constant id: in string;
      line_num : natural := 0;
      file_name : string := ""
    ) is
      variable last: std_logic := '0';
      variable o: std_logic_vector(tb_cfg_data_width-1 downto 0);
    begin
      info("Receiving <"& id &"> of size " & to_string(csv.height) & "x" & to_string(csv.width) & " from UUT...",
        line_num => line_num, file_name => file_name);
      for x in 0 to csv.height-1 loop
        for y in 0 to csv.width-1 loop
          pop_axi_stream(net, s_axis, tdata => o, tlast => last);
          if (verbose) then
            info("Received (" & to_string(x) & "," & to_string(y) & ") : " & to_string(to_integer(signed(o))));
          end if;
          csv.set(y,x,to_integer(signed(o)));
        end loop;
        info("Received row " & to_string(x));
      end loop;
      info("<"& id &"> received from UUT",
        line_num => line_num, file_name => file_name);
    end procedure;

  begin
    saved <= false;
    wait until start and rising_edge(clk);
    wait for 100*clk_period;
    data_O.init_2d(data_I.width, data_I.height, tb_cfg_data_width, true);
    receive_csv(data_O, "O");
    wait until rising_edge(clk);
    data_O.save_csv(tb_cfg_file_out);
    wait until rising_edge(clk);
    saved <= true;
    wait;
  end process;

--

  uut_vc: entity work.vc_hsconv2
  generic map(
    m_axis          => m_axis,
    s_axis          => s_axis,
    data_width      => tb_cfg_data_width,
    window_width    => tb_cfg_window_width,
    band_depth      => tb_cfg_band_depth,
    line_width      => tb_cfg_line_width,
    zpadding        => tb_cfg_zpadding,
    axis_data_width => C_AXIS_TDATA_WIDTH
  )
  port map (
    clk  => clk,
    rst  => rst
  );

end architecture;
