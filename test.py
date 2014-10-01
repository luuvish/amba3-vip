#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
================================================================================

The MIT License (MIT)

Copyright (c) 2014 Luuvish Hwang

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

================================================================================

    File         : test.py
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : test python script 

================================================================================
'''

import os
import subprocess
import sys


ROOT_DIR = os.path.abspath(os.path.dirname(__file__))
RTL_DIR  = os.path.join(ROOT_DIR, '.')
LIB_DIR  = os.path.join(ROOT_DIR, 'build', 'sim')
TEST_DIR = os.path.join(ROOT_DIR, 'test')

VLOG = 'ncvlog'
VLIB = 'ncelab'
VSIM = 'ncsim'

NCFLAGS = ['-nocopyright', '-nolog']


TB_AMBA_DIR = os.path.join(RTL_DIR, '.');

test_vectors = {
  'options': {
    'vlog': ['-sv', '-work', 'worklib', '+incdir+'+TB_AMBA_DIR],
    'vlib': ['-dpiheader', 'dpi.h', '-access', 'r', '-timescale', '1ns/10ps'],
    'vsim': ['-sv_root', LIB_DIR, '-sv_lib', 'dpi_amba3.so'],
    'files': []
  },
  'worklib.tb_amba3_apb:module': {
    'module': 'worklib.tb_amba3_apb',
    'files': [os.path.join(TB_AMBA_DIR, 'tb_amba3_apb.sv')],
    'args': ['+testname=tb_amba3_apb']
  },
  'worklib.tb_amba3_axi:module': {
    'module': 'worklib.tb_amba3_axi',
    'files': [os.path.join(TB_AMBA_DIR, 'tb_amba3_axi.sv')],
    'args': ['+testname=tb_amba3_axi']
  }
}


def main():
  if not os.path.exists(LIB_DIR):
    os.makedirs(LIB_DIR)
  if not os.path.exists(TEST_DIR):
    os.makedirs(TEST_DIR)
  os.chdir(TEST_DIR)

  with open('hdl.var', 'wt') as f:
    f.write('DEFINE WORK worklib\n')
  with open('cds.lib', 'wt') as f:
    f.write('INCLUDE $CDS_INST_DIR/tools/inca/files/cds.lib\n')
    f.write('DEFINE worklib %s\n' % os.path.join(LIB_DIR, 'worklib'))
    f.write('DEFINE ambalib %s\n' % os.path.join(LIB_DIR, 'ambalib'))

  arguments = ['+verbose', '+waveform']
  #arguments = ['+unittest=50', '+verbose', '+waveform']
  #arguments = ['+unittest=1000', '+verbose']

  #test(test_vectors['worklib.tb_amba3_apb:module'], arguments)
  test(test_vectors['worklib.tb_amba3_axi:module'], arguments)


def test(sets, args=[]):
  vlog(sets, args)
  vlib(sets, args)
  vsim(sets, args)


def vlog(sets, args=[]):
  files = test_vectors['options']['files'] + sets.get('files', [])
  options = test_vectors['options']['vlog']
  subprocess.call([VLOG] + NCFLAGS + options + files)


def vlib(sets, args=[]):
  module = [sets.get('module') + ':module']
  options = test_vectors['options']['vlib']
  subprocess.call([VLIB] + NCFLAGS + options + module)


def vsim(sets, args=[]):
  module = [sets.get('module') + ':module']
  options = test_vectors['options']['vsim'] + args
  subprocess.call([VSIM] + NCFLAGS + options + module)


if __name__ == '__main__':
  sys.exit(main())
