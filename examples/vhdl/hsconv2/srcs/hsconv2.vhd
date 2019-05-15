library ieee;
context ieee.ieee_std_context;

entity addertree is
	generic (
	  C_WINDOW_WIDTH : integer := 3;
		C_DATA_WIDTH   : integer := 16
	);
	port (
    CLK, RST, EN: in std_logic;
    D: in std_logic_vector((C_WINDOW_WIDTH**2)*C_DATA_WIDTH-1 downto 0);
		Q: out std_logic_vector(C_DATA_WIDTH-1 downto 0)
	);
end addertree;

architecture arch of addertree is

  constant C_COLUMN_WIDTH: integer:=C_WINDOW_WIDTH*C_DATA_WIDTH;

  type t_reg is array (0 to C_WINDOW_WIDTH-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
	signal reg: t_reg;

	type t_val is array (0 to (C_WINDOW_WIDTH**2)-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
	signal val: t_val;

  type t_add is array (0 to C_WINDOW_WIDTH**2/3-1) of signed(C_DATA_WIDTH-1 downto 0);
	signal add: t_add;

begin

	vgenx: for x in 0 to C_WINDOW_WIDTH-1 generate
		vgeny: for y in 0 to C_WINDOW_WIDTH-1 generate
		  val(x*C_WINDOW_WIDTH+y) <= D(x*C_COLUMN_WIDTH+(y+1)*C_DATA_WIDTH-1 downto x*C_COLUMN_WIDTH+y*C_DATA_WIDTH);
	  end generate;
	end generate;

	process(CLK) begin if rising_edge(CLK) then
    if RST then
      Q <= (others=>'0');
			for x in 0 to C_WINDOW_WIDTH-1 loop
				reg(x) <= (others=>'0');
			end loop;
		elsif EN then
			Q <= std_logic_vector((add(0) + add(1)) + add(2));
      for x in 0 to C_WINDOW_WIDTH-1 loop
        add(x) <= (signed(val(x*C_WINDOW_WIDTH+0)) + signed(val(x*C_WINDOW_WIDTH+1))) + signed(val(x*C_WINDOW_WIDTH+2));
      end loop;
		end if;
	end if; end process;

end architecture;

---

library ieee;
context ieee.ieee_std_context;

entity conv2filter is
	generic (
	  C_WINDOW_WIDTH : integer := 3;
		C_DATA_WIDTH   : integer := 16
	);
	port (
    CLK, RST, Z: in std_logic;
		MEN: in std_logic_vector(1 downto 0);
    D: in std_logic_vector((C_WINDOW_WIDTH**2)*C_DATA_WIDTH downto 0);
		Q: out std_logic_vector(C_DATA_WIDTH downto 0)
	);
end conv2filter;

architecture three of conv2filter is

	constant C_COLUMN_WIDTH: integer:=C_WINDOW_WIDTH*C_DATA_WIDTH;

  type t_ireg is array (0 to C_WINDOW_WIDTH-1) of std_logic_vector(C_COLUMN_WIDTH-1 downto 0);
	signal mreg: t_ireg;

	type t_ker is array (0 to (C_WINDOW_WIDTH**2)-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
	signal ker: t_ker;

	signal kreg: std_logic_vector(C_WINDOW_WIDTH*C_COLUMN_WIDTH-1 downto 0);
  signal mux0, mux2, pad: std_logic_vector(C_COLUMN_WIDTH-1 downto 0);

  signal en: std_logic;
	signal ens: std_logic_vector(3 downto 0);
	signal msel: std_logic_vector(C_WINDOW_WIDTH-2 downto 0);

  -- mreg: column major
	-- ker: row major

begin

  en <= D(D'left);
	Q(Q'left) <= en and ens(ens'left);

  process(CLK) begin if rising_edge(CLK) then
		if RST then
			for x in 0 to C_WINDOW_WIDTH-1 loop
        mreg(x) <= (others=>'0');
      end loop;
			kreg <= (others=>'0');
      ens <= (others=>'0');
			msel <= "01";
		elsif en then
      for x in 0 to C_WINDOW_WIDTH-1 loop
        mreg(x) <= D((x+1)*C_COLUMN_WIDTH-1 downto x*C_COLUMN_WIDTH);
      end loop;
			for x in 0 to C_WINDOW_WIDTH**2-1 loop
				kreg((x+1)*C_DATA_WIDTH-1 downto x*C_DATA_WIDTH) <= std_logic_vector(shift_right(signed(ker(x)),3)); -- shift_left, shift_right
			end loop;
			for x in ens'left downto 1 loop
        ens(x) <= ens(x-1);
			end loop;
			ens(0) <= en;
			if MEN(0) then
				msel(1) <= msel(0);
				msel(0) <= MEN(1);
			end if;
		end if;
	end if; end process;

  cker: for x in 0 to C_WINDOW_WIDTH-1 generate
		ker(0+x*C_WINDOW_WIDTH) <= mux0((x+1)*C_DATA_WIDTH-1 downto x*C_DATA_WIDTH);
		ker(1+x*C_WINDOW_WIDTH) <= mreg(1)((x+1)*C_DATA_WIDTH-1 downto x*C_DATA_WIDTH);
    ker(2+x*C_WINDOW_WIDTH) <= mux2((x+1)*C_DATA_WIDTH-1 downto x*C_DATA_WIDTH);
	end generate;

  pad <= (others=>'0') when Z else mreg(1);

  mux0 <= pad when msel(1) else mreg(0);
	mux2 <= pad when msel(0) else mreg(2);

	addertree: entity work.addertree
	  generic map (
      C_WINDOW_WIDTH => C_WINDOW_WIDTH,
			C_DATA_WIDTH => C_DATA_WIDTH
		)
		port map (
		  CLK => CLK,
			RST => RST,
			EN => en,
			D => kreg,
			Q => Q(Q'left-1 downto 0)
		);

end architecture;

---

library ieee;
context ieee.ieee_std_context;

use work.f.wl;

entity counter is
	generic (
	  C_MODULE : integer := 200
	);
	port (
    CLK, RST, EN: in std_logic;
		D: in unsigned(wl(C_MODULE)-1 downto 0);
    L: out std_logic
	);
end counter;

architecture arch of counter is

  signal cnt: unsigned(wl(C_MODULE)-1 downto 0);
	signal z: std_logic;

begin

	process(CLK) begin if rising_edge(CLK) then
		if RST then
      cnt <= D;
		elsif EN then
			cnt <= D when z else cnt - 1;
    end if;
	end if; end process;

  z <= cnt?=0;
	L <= z;

end architecture;

---

library ieee;
context ieee.ieee_std_context;

library work;
use work.f.wl;

entity ctrl is
	generic (
	  C_WINDOW_WIDTH : integer := 3;
	  C_BAND_DEPTH : integer := 200;
		C_LINE_WIDTH : integer := 145
	);
	port (
    CLK, RST: in std_logic;
		NENS: in std_logic_vector(8 downto 0);
		ENS: out std_logic_vector(8 downto 0);
		MEN: out std_logic_vector(1 downto 0)
	);
end ctrl;

architecture arch of ctrl is

	signal sby, init, en, zb, zl, zz, step, tc, load, isbuf, crst: std_logic;
	signal ens_o, ens_next: std_logic_vector(ENS'length-1 downto 0);
	signal cnt, cnt_ld: unsigned(wl(C_LINE_WIDTH)-1 downto 0);
	signal rmen: std_logic_vector(1 downto 0);

begin

  crst <= RST or (init and (NENS(0) or step));

	cntb: entity work.counter
		generic map (
			C_MODULE => C_BAND_DEPTH
		)
		port map (
			CLK => CLK,
			RST => crst,
			D => to_unsigned( C_BAND_DEPTH-1, wl(C_BAND_DEPTH-1)),
			EN => en,
			L => zb
		);

	process(CLK) begin if rising_edge(CLK) then
		if RST then
      cnt <= cnt_ld;
		elsif en and zb then
			cnt <= cnt_ld when zl else cnt - 1;
    end if;
	end if; end process;

  zl <= cnt?=0;
	zz <= zb and zl;
  cnt_ld <= to_unsigned(C_WINDOW_WIDTH-2, cnt'length)
	          when RST or (load and isbuf) else
	          to_unsigned(C_LINE_WIDTH-3, cnt'length)
	          when load else
						to_unsigned(C_LINE_WIDTH-1, cnt'length);

  process(CLK) begin if rising_edge(CLK) then
		if RST then
			init <= '1';
			ens_o <= (others=>'0');
		else
			if ens_o(0) then init <= '0'; end if;
			if step then ens_o <= ens_next; end if;
		end if;
	end if; end process;

  load <= unsigned(not ens_o)?/=0;
  en <= unsigned(ens_o and NENS)?=0;
  ens_next <= ens_o(ens_o'left-1 downto 0) & '1';

  step <= ((init and (not ens_o(0))) or tc) and unsigned(ens_next and NENS)?=0;
	tc <= zz when isbuf else zb and load;
  isbuf <= ens_o(3 downto 2)?="01" or ens_o(6 downto 5)?="01";

  ENS <= en and ens_o;

  process(CLK) begin if rising_edge(CLK) then
    if RST then
			MEN <= "00";
			rmen <= "00";
		else
			MEN <= rmen;
			rmen(1) <= (not load) and zz;
			rmen(0) <= zb;
		end if;
	end if; end process;

end architecture;

---

library ieee;
context ieee.ieee_std_context;

library work;
use work.f.wl;

entity hsconv2 is
	generic (
	  C_WINDOW_WIDTH : integer := 3;
		C_LINE_WIDTH   : integer := 256;
		C_BAND_DEPTH   : integer := 20;
		C_DATA_WIDTH   : integer := 16;
		C_AXIS_TDATA_WIDTH : integer := 32
	);
	port (
    CLK, RST: in std_logic;
    Z: in std_logic; --padding (both): Z=1 zero, Z=0 replicate

    CLKW, CLKR, WR, RD: in std_logic;
		E, F: out std_logic;
		D: in std_logic_vector(C_DATA_WIDTH downto 0);
		Q: out std_logic_vector(C_DATA_WIDTH downto 0);

		S_AXIS_ACLK	   : in std_logic;
		S_AXIS_ARESETN : in std_logic;
		S_AXIS_TREADY	 : out std_logic;
		S_AXIS_TDATA	 : in std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TVALID	 : in std_logic;
		S_AXIS_TSTRB   : in std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST   : in std_logic;

		M_AXIS_ACLK	   : in std_logic;
		M_AXIS_ARESETN : in std_logic;
		M_AXIS_TVALID	 : out std_logic;
		M_AXIS_TDATA	 : out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TREADY	 : in std_logic;
		M_AXIS_TSTRB   : out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST   : out std_logic
	);
end hsconv2;

architecture arch of hsconv2 is

  constant C_COLUMN_WIDTH: integer:=C_WINDOW_WIDTH*C_DATA_WIDTH;

  type t_fifo_interface is record
    WR, RD, E, F: std_logic;
	  D, Q: std_logic_vector(C_DATA_WIDTH-1 downto 0);
  end record;

  type t_fifos is array (0 to C_WINDOW_WIDTH-1, 0 to C_WINDOW_WIDTH-2) of t_fifo_interface;
  signal fifo: t_fifos;

  signal tofilter: std_logic_vector((C_WINDOW_WIDTH**2)*C_DATA_WIDTH-1 downto 0);
	signal e_tofilter: std_logic_vector(tofilter'length downto 0);
	signal fromfilter: std_logic_vector(C_DATA_WIDTH downto 0);
  signal oQ: std_logic_vector(C_DATA_WIDTH-1 downto 0);

  signal en, o_f, i_e, bo_f, bi_e, buf_d_last, buf_q_last, o_wr, i_rd: std_logic;
  signal buf_d, buf_q: std_logic_vector(C_AXIS_TDATA_WIDTH downto 0);
  signal en_rd, en_wr, buf_wr, buf_rd: std_logic;

  signal nens, ens, rens: std_logic_vector(8 downto 0);
	signal men: std_logic_vector(1 downto 0);

begin

  ctrl: entity work.ctrl
	  generic map (
		  C_WINDOW_WIDTH => C_WINDOW_WIDTH,
	    C_BAND_DEPTH => C_BAND_DEPTH,
		  C_LINE_WIDTH => C_LINE_WIDTH
	  )
	  port map (
      CLK => CLK,
			RST => RST,
			NENS => nens,
		  ENS => ens,
			MEN => men
	  );

	nens(0) <= i_e or fifo(2,1).F;
	nens(1) <= fifo(2,0).F;
	nens(2) <= bo_f;
	nens(3) <= bi_e or fifo(1,1).F;
	nens(4) <= fifo(1,0).F;
	nens(5) <= '0';
	nens(6) <= fifo(0,1).F;
	nens(7) <= fifo(0,0).F;
	nens(8) <= o_f;

  process(CLK) begin if rising_edge(CLK) then
    if RST then
		  rens <= (others=>'0');
		else
			rens <= ens;
		end if;
	end if; end process;

	i_rd <= ens(0);
  fifo(2,1).WR <= rens(0);

  fifo(2,1).RD <= ens(1);
  fifo(2,0).WR <= rens(1);

  fifo(2,0).RD <= ens(2);
  en_wr <= rens(2);

	en_rd <= ens(3);
	fifo(1,1).WR <= rens(3);

  fifo(1,1).RD <= ens(4);
	fifo(1,0).WR <= rens(4);

	fifo(1,0).RD <= ens(5);

  fifo(0,1).WR <= rens(6);

	fifo(0,1).RD <= ens(7);
	fifo(0,0).WR <= rens(7);

  fifo(0,0).RD <= ens(8);

	o_wr <= fromfilter(fromfilter'left);

---

  tofx: for x in 0 to C_WINDOW_WIDTH-1 generate
	  tofy: for y in 0 to C_WINDOW_WIDTH-2 generate
		  tofilter(y*C_COLUMN_WIDTH+(x+1)*C_DATA_WIDTH-1 downto y*C_COLUMN_WIDTH+x*C_DATA_WIDTH) <= fifo(x,y).Q;
	  end generate;
		tofilter((C_WINDOW_WIDTH-1)*C_COLUMN_WIDTH+(x+1)*C_DATA_WIDTH-1 downto (C_WINDOW_WIDTH-1)*C_COLUMN_WIDTH+x*C_DATA_WIDTH) <= fifo(x, 1).D;
  end generate;

  fgenx: for x in 0 to C_WINDOW_WIDTH-1 generate
	  fgeny: for y in 0 to C_WINDOW_WIDTH-3 generate
      fifo(x, y).D <= fifo(x, y+1).Q;
	  end generate;
  end generate;

	buf_d_last <= '0';
	buf_d(buf_d'length-1) <= buf_d_last;
	buf_d(buf_d'length-2 downto 0) <= std_logic_vector(resize(signed( fifo(1, 0).Q ), C_AXIS_TDATA_WIDTH/2)) &
	                                  std_logic_vector(resize(signed( fifo(2, 0).Q ), C_AXIS_TDATA_WIDTH/2));

	buf_q_last <= buf_q(buf_q'length-1);
	fifo(0, 1).D <= buf_q(C_AXIS_TDATA_WIDTH/2+C_DATA_WIDTH-1 downto C_AXIS_TDATA_WIDTH/2);
	fifo(1, 1).D <= buf_q(C_DATA_WIDTH-1 downto 0);

  Q <= '0'&oQ;

  ofifo: entity work.fifo
    generic map (
	    data_width => C_DATA_WIDTH,
	  	fifo_depth => 4
	  )
  	port map (
  	  CLKW => CLK,
	  	CLKR => CLKR,
		  RST => RST,
	  	WR => o_wr,
	  	RD => RD,
	  	D => fromfilter(fromfilter'left-1 downto 0),
	  	E => E,
	  	F => o_f,
	  	Q => oQ
	  );

  ififo: entity work.fifo
    generic map (
  	  data_width => C_DATA_WIDTH,
	  	fifo_depth => 4
	  )
  	port map (
  	  CLKW => CLKW,
	  	CLKR => CLK,
	  	RST => RST,
	  	WR => WR,
	  	RD => i_rd,
	  	D => D(D'length-2 downto 0),
  		E => i_e,
  		F => F,
	  	Q => fifo(C_WINDOW_WIDTH-1, C_WINDOW_WIDTH-2).D
	  );

  buf_wr <= en_wr and (not bo_f);
  buf_rd <= en_rd and (not bi_e);
  buf: entity work.axis2fifos
		generic map (
			C_S_AXIS_DATA_WIDTH	=> C_AXIS_TDATA_WIDTH,
			C_M_AXIS_DATA_WIDTH	=> C_AXIS_TDATA_WIDTH,
			C_S_FIFO_ADR_BITS => 5,
			C_M_FIFO_ADR_BITS => 5
		)
		port map (
	    CLKW => CLK,
			CLKR => CLK,
			RSTW => RST,
			RSTR => RST,
			E_WR => buf_wr,
			F_RD => buf_rd,
			WR_E => bi_e,
			RD_F => bo_f,
		  D    => buf_d,
			Q    => buf_q,
			S_AXIS_CLK	 => S_AXIS_ACLK,
			S_AXIS_RSTN  => S_AXIS_ARESETN,
			S_AXIS_RDY	 => S_AXIS_TREADY,
			S_AXIS_DATA	 => S_AXIS_TDATA,
			S_AXIS_VALID => S_AXIS_TVALID,
			S_AXIS_STRB  => S_AXIS_TSTRB,
			S_AXIS_LAST  => S_AXIS_TLAST,
			M_AXIS_CLK	 => M_AXIS_ACLK,
			M_AXIS_RSTN  => M_AXIS_ARESETN,
			M_AXIS_RDY	 => M_AXIS_TREADY,
			M_AXIS_DATA	 => M_AXIS_TDATA,
			M_AXIS_VALID => M_AXIS_TVALID,
			M_AXIS_STRB  => M_AXIS_TSTRB,
			M_AXIS_LAST  => M_AXIS_TLAST
		);

  fifosx: for x in 0 to C_WINDOW_WIDTH-1 generate
	  fifosy: for y in 0 to C_WINDOW_WIDTH-2 generate
	    fifos: entity work.fifo
	      generic map (
	  	    data_width => C_DATA_WIDTH,
	  		  fifo_depth => wl(C_BAND_DEPTH-1)
	  	  )
	  	  port map (
		      CLKW => CLK,
		  	  CLKR => CLK,
	  		  RST => RST,
	  		  WR => fifo(x, y).WR,
	  		  RD => fifo(x, y).RD,
	  		  D => fifo(x, y).D,
		  	  E => fifo(x, y).E,
	  		  F => fifo(x, y).F,
	  		  Q => fifo(x, y).Q
		    );
	  end generate;
  end generate;

  e_tofilter <= ens(7) & tofilter;

  filter: entity work.conv2filter
    generic map (
      C_WINDOW_WIDTH => C_WINDOW_WIDTH,
	  	C_DATA_WIDTH => C_DATA_WIDTH
	  )
	  port map (
      CLK => CLK,
	  	RST => RST,
			Z => Z,
			MEN => men,
	  	D => e_tofilter,
	  	Q => fromfilter
  	);

end architecture;
