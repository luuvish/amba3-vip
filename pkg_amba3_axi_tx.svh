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

    File         : pkg_amba3_axi_tx.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi transaction

==============================================================================*/

class amba3_axi_tx_t #(TXID_BITS = 4, ADDR_BITS = 32, DATA_BITS = 32);

  localparam integer STRB_BITS = DATA_BITS / 8;
  localparam integer DATA_BASE = $clog2(DATA_BITS / 8);

  typedef logic [ADDR_BITS - 1:0] addr_t;
  typedef logic [DATA_BITS - 1:0] data_t;
  typedef logic [STRB_BITS - 1:0] strb_t;

  typedef enum logic [1:0] {READ, WRITE, DATA, RESP} mode_t;

  mode_t                  mode;
  logic [TXID_BITS - 1:0] txid;

  struct {
    logic [ADDR_BITS - 1:0] addr;
    logic [            3:0] len;
    logic [            2:0] size;
    burst_type_t            burst;
    lock_type_t             lock;
    cache_attr_t            cache;
    prot_attr_t             prot;
  } addr;

  struct {
    logic [DATA_BITS - 1:0] data;
    logic [STRB_BITS - 1:0] strb;
    resp_type_t             resp;
    logic                   last;
  } data [$:16];

  resp_type_t resp;
  event       done;

  constraint mode_c {
    mode inside {READ, WRITE};
    addr.burst inside {FIXED, INCR, WRAP};
    addr.lock inside {NORMAL, EXCLUSIVE, LOCKED};
    data.size == addr.len + 1;
    resp inside {OKAY, EXOKAY, SLVERR, DECERR};
  }

  virtual function addr_t beat (input int i, output int upper, lower);
    int beat_base    = this.addr.size;
    int number_bytes = 1 << beat_base;
    int burst_length = this.addr.len + 1;
    int burst_totals = number_bytes * burst_length;

    addr_t wrap_boundary = (this.addr.addr / burst_totals) * burst_totals;
    addr_t address_n;
    int lower_byte_lane;
    int upper_byte_lane;

    address_n = this.addr.addr;
    if (this.addr.burst != FIXED) begin
      if (i != 0)
        address_n = (address_n >> beat_base) << beat_base;
      address_n += i * number_bytes;
    end
    if (this.addr.burst == WRAP) begin
      if (address_n >= wrap_boundary + burst_totals)
        address_n -= burst_totals;
    end

    lower_byte_lane = address_n & ((1 << DATA_BASE) - 1);

    upper_byte_lane = lower_byte_lane;
    if (this.addr.burst == FIXED || i == 0)
      upper_byte_lane = (upper_byte_lane >> beat_base) << beat_base;
    upper_byte_lane += (number_bytes - 1);

    upper = upper_byte_lane;
    lower = lower_byte_lane;
    return address_n;
  endfunction

  virtual function void random (input mode_t mode = WRITE);
    this.mode       = mode;
    this.txid       = $urandom_range(0, (1 << TXID_BITS) - 1);

    this.addr.addr  = $urandom_range(0, 'hFFFFFFFF);
    this.addr.len   = $urandom_range(0, 'b1111);
    this.addr.size  = $urandom_range(0, 'b111);
    this.addr.burst = burst_type_t'($urandom_range(int'(FIXED), int'(WRAP)));
    this.addr.lock  = NORMAL;
    this.addr.cache = cache_attr_t'('0);
    this.addr.prot  = NON_SECURE;

    if (this.mode == WRITE) begin
      for (int i = 0; i < this.addr.len + 1; i++) begin
        strb_t strb = $urandom_range(0, (1 << STRB_BITS) - 1);
        data_t data = '0;
        foreach (strb [i]) begin
          if (strb[i])
            data |= ($urandom_range(0, 'hFF) & 8'hFF) << (i * 8);
        end
        this.data[i] = '{
          data: data,
          strb: strb,
          resp: OKAY,
          last: (i == this.addr.len)
        };
      end
    end
  endfunction

  virtual function void report (string title = "", int tab = 0);
    string tabs = tab == 0 ? "" : {(tab){" "}};

    if (title != "") $display("%s%s", tabs, title);

    $display("%s  mode     : %s", tabs, mode.name);

    if (mode == READ) begin
      $display("%s  arid     : %0d", tabs, txid);
      $display("%s  araddr   : %x",  tabs, addr.addr);
      $display("%s  arlen    : %0d", tabs, addr.len);
      $display("%s  arsize   : %0d", tabs, addr.size);
      $display("%s  arburst  : %0s", tabs, addr.burst.name);
      $display("%s  arlock   : %0s", tabs, addr.lock.name);
      $display("%s  arcache  : %0x", tabs, addr.cache);
      $display("%s  arprot   : %0x", tabs, addr.prot);
      foreach (data [i]) begin
        $display("%s  rid  [%2d]: %0d", tabs, i, txid);
        $display("%s  rdata[%2d]: %x",  tabs, i, data[i].data);
        $display("%s  rresp[%2d]: %0s", tabs, i, data[i].resp.name);
        $display("%s  rlast[%2d]: %x",  tabs, i, data[i].last);
      end
    end

    if (mode == WRITE) begin
      $display("%s  awid     : %0d", tabs, txid);
      $display("%s  awaddr   : %x",  tabs, addr.addr);
      $display("%s  awlen    : %0d", tabs, addr.len);
      $display("%s  awsize   : %0d", tabs, addr.size);
      $display("%s  awburst  : %0s", tabs, addr.burst.name);
      $display("%s  awlock   : %0s", tabs, addr.lock.name);
      $display("%s  awcache  : %0x", tabs, addr.cache);
      $display("%s  awprot   : %0x", tabs, addr.prot);
      foreach (data [i]) begin
        $display("%s  wid  [%2d]: %0d", tabs, i, txid);
        $display("%s  wdata[%2d]: %x",  tabs, i, data[i].data);
        $display("%s  wstrb[%2d]: %x",  tabs, i, data[i].strb);
        $display("%s  wlast[%2d]: %x",  tabs, i, data[i].last);
      end
      $display("%s  bresp    : %0s", tabs, resp.name);
    end

    if (mode == DATA) begin
      foreach (data [i]) begin
        $display("%s  wid  [%2d]: %0d", tabs, i, txid);
        $display("%s  wdata[%2d]: %x",  tabs, i, data[i].data);
        $display("%s  wstrb[%2d]: %x",  tabs, i, data[i].strb);
        $display("%s  wlast[%2d]: %x",  tabs, i, data[i].last);
      end
      $display("%s  bresp    : %0s", tabs, resp.name);
    end

    if (mode == RESP) begin
      $display("%s  bresp    : %0s", tabs, resp.name);
    end
  endfunction

endclass
