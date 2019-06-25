set num_facs  [ gtkwave::getNumFacs ]
set old_path ""

# create dict key/val
set dictGroup [dict create]

# search entire waveform list to find matches to add to groups
for {set i 0} {$i < $num_facs} {incr i} {
  set path [ gtkwave::getFacName $i ]

  # split path and determine how many elements there are
  set elements     [ split $path "." ]
  set num_elements [ llength $elements ]

  # remove first element because redundant and last because this is the signal name, then join for matching
  set group_elements [ lreplace [ lreplace $elements 0 0 ] end end ]
  set group_name     [ join $group_elements "." ]

  # init add_wave flag so we only add match
  set add_wave 0

  # if we are adding by name, else add by hierarchy
  if {[string is true $do_add_by_name]} {

    # search add_waves to see if we have group name match that is case insensitive
    set is_string_match [lsearch -exact [ string tolower $add_waves ] $group_name]

    if {$is_string_match >= 0} {
      incr add_wave
    }

  } else {

    # if we have correct hierarchy depth, add element
    if {$num_elements <= $max_depth} {
      incr add_wave
    }

  }

  # if we found match, append path to group key
  if {$add_wave > 0} {

    set elements [ split $path \[ ]

    if { [ llength $elements ] > 1 } {
        set var [ lreplace $elements end end ]
        set path [ join $var \[ ]
    }

    if {$old_path ne $path} {
        # create dict with key:<group_name> and value:<path>
        set key   $group_name
        set value $path
        set old_path $path

        # append element to group key
        dict lappend dictGroup $key $value
    }
  }

}

set first 0

foreach {k v} $dictGroup {
  set num_added [ gtkwave::addSignalsFromList $v ]

  # GTK doesn't highlight the first set of signals added so nothing gets grouped
  if {$first == 0} {
    gtkwave::/Edit/Highlight_All
  }
  gtkwave::/Edit/Create_Group "$k"
  gtkwave::/Edit/Toggle_Group_Open|Close
  gtkwave::/Edit/UnHighlight_All

  incr first
}