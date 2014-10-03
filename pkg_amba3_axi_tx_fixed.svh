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
                    DATA_SIZE = 32,
                    BEAT_SIZE = 32
)
extends amba3_axi_tx_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE);

  localparam integer BEAT_BASE = $clog2(BEAT_SIZE / 8);

  typedef logic [BEAT_SIZE - 1:0] beat_t;

  constraint mode_c {
    BEAT_SIZE <= DATA_SIZE;
    addr.burst == FIXED;
  }

  function new (mode_t mode, addr_t addr, beat_t beat [] = {}, int size = 0);
    assert(BEAT_SIZE <= DATA_SIZE);
    assert((mode == READ ? size : beat.size) > 0);

    this.mode = mode;
    this.txid = $urandom_range(0, (1 << TXID_SIZE) - 1);

    this.addr = '{
      addr : addr,
      len  : (mode == READ ? size : beat.size) - 1,
      size : BEAT_BASE,
      burst: FIXED,
      lock : NORMAL,
      cache: cache_attr_t'('0),
      prot : NON_SECURE
    };

    write(beat);

    this.resp = OKAY;
  endfunction

  function void write (beat_t beat []);
    foreach (beat [i]) begin
      int upper, lower;
      addr_t addr = get_addr(i, upper, lower);

      this.data[i] = '{
        data: set_data(beat[i], (upper + 1) * 8, lower * 8),
        strb: set_strb('1, upper + 1, lower),
        resp: OKAY,
        last: (i == this.addr.len)
      };
    end
  endfunction

  function void read (beat_t beat []);
    for (int i = 0; i < this.addr.len + 1; i++) begin
      int upper, lower;
      addr_t addr = get_addr(i, upper, lower);

      beat[i] = get_data(this.data[i].data, (upper + 1) * 8, lower * 8);
    end
  endfunction

  function data_t set_data (beat_t beat, int upper, int lower);
    return (beat << lower);
  endfunction

  function beat_t get_data (data_t data, int upper, int lower);
    return ((data >> lower) & ((1 << (upper - lower)) - 1));
  endfunction

endclass
