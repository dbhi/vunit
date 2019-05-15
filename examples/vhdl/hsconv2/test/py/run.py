from vunit import VUnit, encode_json
from sys import argv
from os import popen
from os.path import join, dirname
import inspect
from shutil import copyfile

def preconf(output_path):
    global opath
    opath = output_path
    return True


global opath
opath = ''
root = join(dirname(__file__))
ext_srcs = join(dirname(inspect.getfile(VUnit)), 'vhdl', 'data_types', 'src', 'external')
build_only = False
if '--build' in argv:
    argv.remove('--build')
    build_only = True

vu = VUnit.from_argv(use_external=[True, True])

vu.add_json4vhdl()
vu.add_array_util()
vu.add_verification_components()

lib = vu.add_library('lib')
lib.add_source_files([
    join(root, '..', '..', 'srcs', '*.vhd'),
    join(root, '..', '*.vhd'),
    join(root, '..', 'c', '*.vhd'),
    join(root, '*.vhd')
])

c_nobj = join(root, 'stubs.o')
c_obj = join(root, 'main.o')

print(popen(' '.join([
    'gcc -fPIC -rdynamic',
    '-c', join(ext_srcs, 'stubs.c'),
    '-o', c_nobj
])).read())

print(popen(' '.join([
    'gcc -fPIC -rdynamic',
    '-I', ext_srcs,
    '-c', join(root, '..', 'c', 'main.c'),
    '-o', c_obj
])).read())

vu.set_compile_option('ghdl.flags', ['--ieee=synopsys', '-frelaxed'])
vu.set_sim_option('ghdl.elab_flags', ['--ieee=synopsys', '-frelaxed', '-Wl,'+c_nobj])

for tb in lib.get_test_benches(pattern='*tb_c_*', allow_empty=False):
    tb.set_sim_option('ghdl.elab_flags', ['--ieee=synopsys', '-frelaxed', '-Wl,'+c_obj])
    tb.set_pre_config(preconf)

vu.set_sim_option('ghdl.elab_flags', ['-Wl,-Wl,--version-script=' + join(ext_srcs, 'grt.ver')], overwrite=False)

tb_cfg = dict(
  file_in = "../data/I.csv",
  file_out = "../data/O.csv",
  window_width=3,
  band_depth=20,#200
  line_width=256, #145
  zpadding="false"
)

for tb in lib.get_test_benches(pattern='*tb_py_*', allow_empty=False):
    tb.set_generic("json_cfg", encode_json(tb_cfg))

#vu.set_generic("verbose", "true")

if build_only:
    vu.set_sim_option("ghdl.elab_e", True)
    vu._args.elaborate = True
try:
    vu.main()
except SystemExit as exc:
    if exc.code is not 0:
        exit(exc.code)
if build_only and len(opath):
    copyfile(join(opath, 'ghdl', 'args.txt'), join(dirname(__file__), 'args.txt'))
