-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

use work.string_pkg.all;

package byte_vector_pkg is
  alias byte_vector_access_t is string_access_t;
  alias byte_vector_access_vector_t is string_access_vector_t;
  alias byte_vector_access_vector_access_t is string_access_vector_access_t;

  alias extbytevec_access_t is extstring_access_t;
  alias extbytevec_access_vector_t is extstring_access_vector_t;
  alias extbytevec_access_vector_access_t is extstring_access_vector_access_t;
end package;
