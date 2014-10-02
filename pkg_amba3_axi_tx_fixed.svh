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

  localparam integer STRB_SIZE = DATA_SIZE / 8;
  localparam integer ADDR_BASE = $clog2(DATA_SIZE / 8);
  localparam integer BEAT_BASE = $clog2(BEAT_SIZE / 8);

  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;
  typedef logic [STRB_SIZE - 1:0] strb_t;
  typedef logic [BEAT_SIZE - 1:0] beat_t;

  constraint mode_c {
    addr.burst == FIXED;
    BEAT_SIZE <= DATA_SIZE;
  }

  function new (mode_t mode, addr_t addr, beat_t beat [] = {}, int size = 0);
    assert((mode == READ ? size : beat.size) > 0);

    this.mode = mode;
    this.txid = $urandom_range(0, 'b1111);

    this.addr = '{
      addr : addr,
      len  : (mode == READ ? size : beat.size) - 1,
      size : $clog2(DATA_SIZE / 8),
      burst: FIXED,
      lock : NORMAL,
      cache: cache_attr_t'('0),
      prot : NON_SECURE
    };

    write(beat);

    this.resp = OKAY;
  endfunction

  function void write (beat_t beat []);
    int    number_bytes    = BEAT_SIZE / 8;
    addr_t start_address   = this.addr.addr;
    addr_t aligned_address = aligned_beat_address(start_address);
    addr_t address_n;
    int    lower_byte_lane;
    int    upper_byte_lane;

    foreach (beat [i]) begin
      address_n = start_address;
      lower_byte_lane = start_address[ADDR_BASE - 1:0];
      upper_byte_lane = aligned_address + (number_bytes - 1) -
        aligned_data_address(start_address);

      this.data[i] = '{
        data: set_data(beat[i], upper_byte_lane * 8 + 8, lower_byte_lane * 8),
        strb: set_strb('1, upper_byte_lane + 1, lower_byte_lane),
        resp: OKAY,
        last: (i == this.addr.len)
      };
    end
  endfunction

  function void read (beat_t beat []);
    int    number_bytes    = BEAT_SIZE / 8;
    addr_t start_address   = this.addr.addr;
    addr_t aligned_address = aligned_beat_address(start_address);
    addr_t address_n;
    int    lower_byte_lane;
    int    upper_byte_lane;

    for (int i = 0; i < this.addr.len + 1; i++) begin
      address_n = start_address;
      lower_byte_lane = start_address[ADDR_BASE - 1:0];
      upper_byte_lane = aligned_address + (number_bytes - 1) -
        aligned_data_address(start_address);

      beat[i] = get_data(this.data[i].data, upper_byte_lane * 8 + 8, lower_byte_lane * 8);
    end
  endfunction

  function data_t set_data (beat_t beat, int upper, int lower);
    return (beat << lower);
  endfunction

  function strb_t set_strb (strb_t strb, int upper, int lower);
    return ((strb >> lower) & ((1 << (upper - lower)) - 1)) << lower;
  endfunction

  function beat_t get_data (data_t data, int upper, int lower);
    return ((data >> lower) & ((1 << (upper - lower)) - 1));
  endfunction

  function addr_t aligned_data_address (input addr_t addr);
    return (addr >> ADDR_BASE) << ADDR_BASE;
  endfunction

  function addr_t aligned_beat_address (input addr_t addr);
    return (addr >> BEAT_BASE) << BEAT_BASE;
  endfunction

endclass
