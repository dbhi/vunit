package f is
  function wl( depth: natural ) return natural;
end package;

package body f is
  function wl( depth: natural ) return natural is
    variable t,v: natural range 0 to depth := 0;
  begin t:=depth; while t>0 loop v:=v+1; t:=t/2; end loop;
  return v; end function;
end f;
