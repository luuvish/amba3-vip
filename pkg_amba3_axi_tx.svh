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

class amba3_axi_tx_t
#(
  parameter integer AXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 32
);

  localparam integer STRB_SIZE = DATA_SIZE / 8;

  typedef enum logic {READ, WRITE} mode_e;

  mode_e                  mode;
  logic [AXID_SIZE - 1:0] axid;

  struct {
    logic [ADDR_SIZE - 1:0] addr;
    logic [            3:0] len;
    logic [            2:0] size;
    burst_type_e            burst;
    lock_type_e             lock;
    cache_attr_e            cache;
    prot_attr_e             prot;
  } addr;

  struct {
    logic [DATA_SIZE - 1:0] data;
    logic [STRB_SIZE - 1:0] strb;
  } data [$:16];

  resp_type_e resp;

  constraint mode_c {
    mode inside {READ, WRITE};
    addr.size == 3'b101;
    addr.burst inside {FIXED, INCR, WRAP};
    addr.lock inside {NORMAL, EXCLUSIVE, LOCKED};
    data.size() == addr.len + 1;
    resp inside {OKAY, EXOKAY, SLVERR, DECERR};
  }

  virtual function void report ();
    $display("axi3 transaction");
    $display("mode : %s", mode);

    if (mode == READ) begin
      $display("  arid    : %0d", axid);
      $display("  araddr  : %0x", addr.addr);
      $display("  arlen   : %0d", addr.len);
      $display("  arsize  : %0d", addr.size);
      $display("  arburst : %0s", addr.burst);
      $display("  arlock  : %0s", addr.lock);
      $display("  arcache : %0x", addr.cache);
      $display("  arprot  : %0x", addr.prot);
      foreach (data [i]) begin
        $display("  rid  [%02d] : %0d", i, axid);
        $display("  rdata[%02d] : %0x", i, data[i].data);
      end
    end

    if (mode == WRITE) begin
      $display("  awid    : %0d", axid);
      $display("  awaddr  : %0x", addr.addr);
      $display("  awlen   : %0d", addr.len);
      $display("  awsize  : %0d", addr.size);
      $display("  awburst : %0s", addr.burst);
      $display("  awlock  : %0s", addr.lock);
      $display("  awcache : %0x", addr.cache);
      $display("  awprot  : %0x", addr.prot);
      foreach (data [i]) begin
        $display("  wid  [%02d] : %0d", i, axid);
        $display("  wdata[%02d] : %0x", i, data[i].data);
        $display("  wstrb[%02d] : %0x", i, data[i].strb);
      end
      $display("  bresp   : %0s", resp);
    end
  endfunction

endclass
