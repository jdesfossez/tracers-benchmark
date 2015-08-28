#!/usr/bin/env python

import itertools
import math
import pprint

def powrange(rmin, rmax, base=2):
    return [int(math.pow(base, x)) for x in range(rmin, rmax + 1)]

params = {
    'no_thread': range(4),
    'sample_size': powrange(13, 23),
    'output': ['mmap', 'splice'],
    'overflow': ['discard', 'overwrite'],
    'num_subbuf': powrange(0, 13),
    'total_buf_size': powrange(8, 10),
}

def dict_product(params):
    keys = []
    values = []
    for k, v in params.items():
        keys.append(k)
        values.append(v)
    prod = itertools.product(*values)
    for item in prod:
        d = {}
        for k, v in zip(keys, item):
            d[k] = v
        yield d

pprint.pprint(params)
num_exp = 0
for d in dict_product(params):
    #pprint.pprint(d)
    num_exp += 1
print("num_exp=%d" % (num_exp))



