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

    File         : pkg_amba3_axi_tx_fixed.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi fixed transaction

==============================================================================*/

class amba3_axi_tx_fixed_t
#(
  parameter integer TXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 32
)
extends amba3_axi_tx_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE);

  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  constraint mode_c {
    addr.burst == FIXED;
  }

  function new (addr_t addr, data_t data [] = {}, int size = 0);
    this.mode = size > 0 ? READ : WRITE;
    this.txid = $urandom_range(0, 'b1111);

    this.addr = '{
      addr : addr,
      len  : (size > 0 ? size : data.size()) - 1,
      size : $clog2(DATA_SIZE / 8),
      burst: FIXED,
      lock : lock_type_e'(2'b0),
      cache: cache_attr_e'(4'b0),
      prot : NON_SECURE
    };

    foreach (data [i]) begin
      this.data[i] = '{data:data[i], strb:{(STRB_SIZE){1'b1}}};
    end

    this.resp = OKAY;
  endfunction

endclass
