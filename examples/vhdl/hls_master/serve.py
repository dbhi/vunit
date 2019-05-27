#x11docker -i --user=0 --clipboard -- -v /$(pwd)://src -w //src -p 5000:5000 -- aptman/dbhi:bionic-cosim bash


import ctypes
from os.path import join, dirname
from vunit import VUnit
from websim import *


root = dirname(__file__)


# Allocate and define shared data buffers

data = [111, 122, 133, 144, 155]

buf = int_buf(data + [0 for x in range(len(data))])

buf = [[] for c in range(3)]
buf[2] = int_buf(data + [0 for x in range(len(data))])
buf[1] = byte_buf([0 for x in range(5)])

buf[0] = int_buf([
    -2**31+10,
    -2**31,
    0,             # clk_step
    1,             # update
    len(data),     # block_length
    32,
])


# Load args and define simulation callbacks

sim = None
args = [line.rstrip('\n') for line in open(join(root, 'args.txt'))]


def load():
    g = ctypes.CDLL(args[0])
    sim.handler(g)

    for idx, val in enumerate(buf):
        g.set_string_ptr(idx, val)

    xargs = enc_args(args)
    return(g.ghdl_main(len(xargs)-1, xargs))


def update_cb():
    p = read_int_buf(buf[0])[0:3]
    p[0] -= -2**31
    p[1] -= -2**31
    b = read_byte_buf(buf[2])
    h = int(len(b)/2)
    return {
        'name': 'hls_master',
        'params' : p,
        'data': {
          'imem'   : b[0:h],
          'omem'   : b[h:],
          'top'    : read_byte_buf(buf[1])
        }
    }


def unload():
    dlclose(sim.handler())


# Instantiate WebSim and run server

sim = WebSim(
    dist=join(root, 'vue', 'dist'),
    load_cb=load,
    unload_cb=unload,
    update_cb=update_cb
)

sim.run()
