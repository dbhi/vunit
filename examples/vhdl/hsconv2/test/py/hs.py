from vunit.cosim import *
import numpy
from websim import *

def List2ListOfLists(d, bands, width, height, bpw=1):
    """
    Convert a (multi|hyper)spectral image encoded in Band Interleaved by Pixel (BIP)
    format and provided as a list of numbers to a list of lists (each corresponding to
    the spatial content of a band).

    :param bands: number of bands.
    :param width: spatial width.
    :param height: spatial height.
    """
    r = numpy.reshape(d, (width*height, bands*bpw))
    i = [[] for x in range(bands)]
    for y in range(bands):
        for z in range(bpw):
            for x in range(width*height):
                i[y].append(r[x][y+z])
    return i


def b64encCubeBuf(b, bands, width, height, scale=1, bpw=4, signed=True):
    """
    Convert a (multi|hyper)spectral image encoded in Band Interleaved by Pixel (BIP)
    format and provided as a buffer of integers to a list of base64 encoded PNG images.

    :param b: byte/string buffer (uint8_t* in C) to read from.
    :param bands: number of bands.
    :param width: spatial width.
    :param height: spatial height.
    :param scale: scale to remove the fractional part.
    :param bpw: number of bytes per word/integer.
    :param signed: whether to decode the numbers as signed.
    """
    return b64enc_list_of_int_lists(List2ListOfLists(
        [int(x * scale) for x in read_int_buf(b, bpw=bpw, signed=signed)],
        bands, width, height
    ), width, height)


def hs_ReadData(f):
    d = open(f, "rb").read()

    params = read_int_buf(d[0:16], bpw=2, signed=True)

    p = {
        'dwidth'   : params[0],
        'div'      : params[1],
        'wwidth'   : params[2],
        'bands'    : params[3],
        'swidth'   : params[4],
        'sheight'  : params[5],
        'zpadding' : params[6]
    }

    db = read_int_buf(d[16:], bpw=2, signed=True)

    dl = List2ListOfLists(
        [x for x in db], #int(x / (2**(p['dwidth']-9)))
        p['bands'],
        p['swidth'],
        p['sheight']
    )

    return p, {
        'bin': db,
        'lists': dl,
        'b64': b64enc_list_of_int_lists(dl, p['swidth'], p['sheight'])
    }


def hs_ReadRef(f, p):
    rb = read_int_buf(open(f, "rb").read(), bpw=2, signed=True)

    rl = List2ListOfLists(
        [x for x in rb], #int(x / (2**(p['dwidth']-9)))
        p['bands'],
        p['swidth'],
        p['sheight']
    )

    return {
        'bin': rb,
        'lists': rl,
        'b64': b64enc_list_of_int_lists(rl, p['swidth'], p['sheight'])
    }