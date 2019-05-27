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

vu = VUnit.from_argv(use_external=[True, True])

vu.add_array_util()
vu.add_verification_components()

lib = vu.add_library('lib')
lib.add_source_files([
    join(src_path, '*.vhd'),
    join(src_path, '**', '*.vhd')
])

c_nobj = join(src_path, 'test', 'stubs.o')
c_obj = join(src_path, 'test', 'main.o')

print(popen(' '.join([
    'gcc -fPIC -rdynamic',
    '-c', join(ext_srcs, 'stubs.c'),
    '-o', c_nobj
])).read())

print(popen(' '.join([
    'gcc -fPIC -rdynamic',
    '-I', ext_srcs,
    '-c', join(src_path, '**', 'main.c'),
    '-o', c_obj
])).read())

vu.set_compile_option('ghdl.flags', ['--ieee=synopsys', '-frelaxed'])
vu.set_sim_option('ghdl.elab_flags', ['--ieee=synopsys', '-frelaxed', '-Wl,'+c_nobj])

for tb in lib.get_test_benches(pattern='*tb_c_*', allow_empty=False):
    tb.set_sim_option('ghdl.elab_flags', ['--ieee=synopsys', '-frelaxed', '-Wl,'+c_obj])
    tb.set_pre_config(preconf)

vu.set_sim_option('ghdl.elab_flags', ['-Wl,-Wl,--version-script=' + join(ext_srcs, 'grt.ver')], overwrite=False)

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
