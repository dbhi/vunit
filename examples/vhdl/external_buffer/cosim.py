# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com


from vunit.cosim import *
import ctypes
from os.path import join, dirname, isfile


args = [line.rstrip('\n') for line in open(join(dirname(__file__), 'args.txt'))]

xargs = enc_args(args)

print("\nREGULAR EXECUTION")
ghdl = dlopen(args[0])
try:
    ghdl.main(len(xargs)-1, xargs)
# FIXME With VHDL 93, the execution is Aborted and Python exits here
except SystemExit as exc:
    if exc.code is not 0:
        exit(exc.code)
dlclose(ghdl)

print("\nPYTHON ALLOCATION")
ghdl = dlopen(args[0])

data = [111, 122, 133, 144, 155]

buf = [[] for c in range(2)]
buf[1] = byte_buf(data + [0 for x in range(2*len(data))])

buf[0] = int_buf([
    -2**31+10,
    -2**31,
    3,         # clk_step
    0,         # update
    len(data)  # block_length
])

for x, v in enumerate(buf):
    ghdl.set_string_ptr(x, v)

for i, v in enumerate(read_byte_buf(buf[1])):
    print("py " + str(i) + ": " + str(v))

ghdl.ghdl_main(len(xargs)-1, xargs)

for i, v in enumerate(read_byte_buf(buf[1])):
    print("py " + str(i) + ": " + str(v))

dlclose(ghdl)
