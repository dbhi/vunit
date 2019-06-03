-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com
--
-- The purpose of this package is to provide a byte vector access type (pointer)
-- that can itself be used in arrays and returned from functions unlike a
-- real access type. This is achieved by letting the actual value be a handle
-- into a singleton datastructure of string access types.
--

use work.byte_vector_pkg.all;
use work.string_ptr_pkg.all;

package byte_vector_ptr_pkg is

  alias storage_mode_t is storage_mode_t;
  alias byte_vector_ptr_t is string_ptr_t;
  alias null_byte_vector_ptr is null_string_ptr;

  alias new_byte_vector_ptr is new_string_ptr[natural, storage_mode_t, integer, val_t return ptr_t];
  alias new_byte_vector_ptr is new_string_ptr[natural, storage_mode_t, integer, natural return ptr_t];
  alias new_byte_vector_ptr is new_string_ptr[string, storage_mode_t, integer return ptr_t];

  alias is_external is is_external[ptr_t return boolean];
  alias deallocate is deallocate[ptr_t];
  alias length is length[ptr_t return integer];
  alias reallocate is reallocate[ptr_t, natural, natural];
  alias resize is resize[ptr_t, natural, natural, natural];

  procedure set (
    ptr   : byte_vector_ptr_t;
    index : natural := 0;
    value : natural := 0
  );

  impure function get (
    ptr   : byte_vector_ptr_t;
    index : natural := 0
  ) return natural;

end package;

use work.string_ptr_pkg.all;

package body byte_vector_ptr_pkg is
  procedure set (
    ptr   : byte_vector_ptr_t;
    index : natural := 0;
    value : natural := 0
  ) is begin
    work.string_ptr_pkg.set(ptr, index+1, value);
  end;

  impure function get (
    ptr   : byte_vector_ptr_t;
    index : natural := 0
  ) return natural is begin
    return work.string_ptr_pkg.get(ptr, index+1);
  end;
end package body;
