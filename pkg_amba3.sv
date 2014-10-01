/*==============================================================================

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

    File         : pkg_amba3.sv
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 apb/axi

==============================================================================*/

package pkg_amba3;

  typedef enum logic [1:0] {
    FIXED, INCR, WRAP
  } burst_type_e;

  typedef enum logic [1:0] {
    OKAY, EXOKAY, SLVERR, DECERR
  } resp_type_e;

  typedef enum logic [3:0] {
    BUFFERABLE     = 4'b0001,
    CACHEABLE      = 4'b0010,
    READ_ALLOCATE  = 4'b0100,
    WRITE_ALLOCATE = 4'b1000
  } cache_attr_e;

  typedef enum logic [2:0] {
    PRIVILEGED  = 3'b001,
    NON_SECURE  = 3'b010,
    INSTRUCTION = 3'b100
  } prot_attr_e;

  typedef enum logic [1:0] {
    NORMAL, EXCLUSIVE, LOCKED
  } lock_type_e;

  `include "pkg_amba3_apb_master.svh"
  `include "pkg_amba3_apb_slave.svh"
  `include "pkg_amba3_axi_tx.svh"
  `include "pkg_amba3_axi_tx_fixed.svh"
  `include "pkg_amba3_axi_tx_incr.svh"
  `include "pkg_amba3_axi_tx_wrap.svh"
  `include "pkg_amba3_axi_master.svh"
  `include "pkg_amba3_axi_slave.svh"

endpackage
