#x11docker -i --user=0 --clipboard -- -v /$(pwd)://src -w //src -p 5000:5000 -- aptman/dbhi:bionic-cosim bash


from os.path import join, dirname
from vunit import VUnit
import ctypes

from hs import *
from websim import *


root = dirname(__file__)


# Load data

p, data = hs_ReadData(join(root, '..', 'data', 'data.bin'))
ref = hs_ReadRef(join(root, '..', 'data', 'ref.bin'), p)


# Compute diff

diff = [[] for x in range(p['bands'])]
for y in range(p['bands']):
    for x in range(p['swidth'] * p['sheight']):
        diff[y].append(2**16 - data['lists'][y][x] + ref['lists'][y][x])

db64 = [[] for x in range(p['bands'])]
for x in range(p['bands']):
    db64[x] = b64enc_int_list(diff[x], p['swidth'], p['sheight'])


# Allocate and define shared data buffers

buf = [[] for c in range(3)]
buf[2] = int_buf([0] * len(data['bin']))
buf[1] = int_buf(data['bin'])

buf[0] = int_buf([
    -2**31+5,
    -2**31,
    0,             # clk_step
    1,             # update
    16,            # data_width
    p['wwidth'],
    0,             # zpadding
    p['bands'],
    p['swidth'],
    p['sheight']
])

lx = read_byte_buf(buf[1])
print(int.from_bytes(buf[1][0], byteorder="little", signed=False))
print(int.from_bytes(buf[1][1], byteorder="little", signed=False))
print(int.from_bytes(buf[1][2], byteorder="little", signed=False))
print(int.from_bytes(buf[1][3], byteorder="little", signed=False))
print(len(lx))
print(lx[0:8])

#ll = List2ListOfLists(read_byte_buf(buf[1]), p['bands'], p['swidth'], p['sheight'], bpw=4)
#print(len(ll))
#print(len(ll[0]))
#print(buf[1][0:8])
#print(ll[0][0:8])
exit(0)

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
    pars = read_int_buf(buf[0])[0:3]
    pars[0] -= -2**31
    pars[1] -= -2**31
    return {
        'name': 'hsconv2',
        'params': pars,
        'data': {
            'bands' : p['bands'],
            'data'  : [0],
            'ref'   : [0],
            'wrk'   : [0],
            'diff'  : [0],
            'imgs': {
              'data' : b64encCubeBuf(buf[1], p['bands'], p['swidth'], p['sheight']), #, scale=1 / (2**(p['dwidth']-9))
              'ref'  : ref['b64'],
              'wrk'  : b64encCubeBuf(buf[2], p['bands'], p['swidth'], p['sheight']), #, scale=1 / (2**(p['dwidth']-9))
              'diff' : db64,
            }
        }
    }

#List2ListOfLists(read_byte_buf(buf[1]), p['bands'], p['swidth'], p['sheight'], bpw=4)

def unload():
    dlclose(sim.handler())


# Instantiate WebSim and run server

sim = WebSim(
    dist=join(root, '..', '..', '..', 'vue', 'dist'),
    load_cb=load,
    unload_cb=unload,
    update_cb=update_cb
)

#sim.add_url_rules([
#    ['/api/update', 'update', update],
#])

sim.run()
