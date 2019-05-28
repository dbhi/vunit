# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

"""
External Buffer
---------------

`Interfacing with foreign languages (C) through VHPIDIRECT <https://ghdl.readthedocs.io/en/latest/using/Foreign.html>`_

An array of type ``uint8_t`` is allocated in a C application and some values
are written to the first ``1/3`` positions. Then, the VHDL simulation is
executed, where the (external) array/buffer is used.

In the VHDL testbenches, two vector pointers are created, each of them using
a different access mechanism (``extfunc`` or ``extacc``). One of them is used to copy
the first ``1/3`` elements to positions ``[1/3, 2/3)``, while incrementing each value
by one. The second one is used to copy elements from ``[1/3, 2/3)`` to ``[2/3, 3/3)``,
while incrementing each value by two.

When the simulation is finished, the C application checks whether data was successfully
copied/modified. The content of the buffer is printed both before and after the
simulation.
"""

from vunit import VUnit
from sys import argv
from os import popen
from os.path import join, dirname
import inspect
from shutil import copyfile


# TODO https://github.com/VUnit/vunit/issues/478
def preconf(output_path):
    global opath
    opath = output_path
    return True


global opath
opath = ''
src_path = join(dirname(__file__), 'src')
ext_srcs = join(dirname(inspect.getfile(VUnit)), 'vhdl', 'data_types', 'src', 'external')
build_only = False
if '--build' in argv:
    argv.remove('--build')
    build_only = True

# Compile C applications to objects
c_iobj = join(src_path, 'imain.o')
c_bobj = join(src_path, 'bmain.o')

print(popen(' '.join([
    'gcc', '-fPIC',
    '-DTYPE=int32_t',
    '-I', ext_srcs,
    '-c', join(src_path, 'main.c'),
    '-o', c_iobj
])).read())

print(popen(' '.join([
    'gcc', '-fPIC',
    '-DTYPE=uint8_t',
    '-I', ext_srcs,
    '-c', join(src_path, 'main.c'),
    '-o', c_bobj
])).read())

# Enable the external feature for strings/byte_vectors and integer_vectors
ui = VUnit.from_argv(vhdl_standard='2008', external={'string': True, 'integer': True})

lib = ui.add_library('lib')
lib.add_source_files(join(src_path, '*.vhd'))

# Add the C object to the elaboration of GHDL
for tb in lib.get_test_benches(pattern='*tb_ext*', allow_empty=False):
    tb.set_sim_option('ghdl.elab_flags', ['-Wl,' + c_bobj, '-Wl,-Wl,--version-script=' + join(ext_srcs, 'grt.ver')], overwrite=True)
for tb in lib.get_test_benches(pattern='*tb_ext*_integer*', allow_empty=False):
    tb.set_sim_option('ghdl.elab_flags', ['-Wl,' + c_iobj, '-Wl,-Wl,--version-script=' + join(ext_srcs, 'grt.ver')], overwrite=True)

for tb in lib.get_test_benches(pattern='*', allow_empty=False):
    tb.set_pre_config(preconf)

if __name__ == '__main__':
    if build_only:
        ui.set_sim_option("ghdl.elab_e", True)
        ui._args.elaborate = True
    try:
        ui.main()
    except SystemExit as exc:
        if exc.code is not 0:
            exit(exc.code)
    if build_only and len(opath):
        copyfile(join(opath, 'ghdl', 'args.txt'), join(dirname(__file__), 'args.txt'))
