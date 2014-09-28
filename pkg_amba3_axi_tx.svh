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
                    DATA_SIZE = 128
);

  localparam integer STRB_SIZE = DATA_SIZE / 8;

  typedef enum logic {READ, WRITE} rw_mode_e;

  rw_mode_e               rw;
  logic [AXID_SIZE - 1:0] id;

  struct {
    logic [ADDR_SIZE - 1:0] addr;
    logic [            3:0] len;
    logic [            2:0] size;
    burst_type_e            burst;
    lock_type_e             lock;
    cache_attr_e            cache;
    prot_attr_e             prot;
  } addr_channel;

  struct {
    logic [DATA_SIZE - 1:0] data;
    logic [STRB_SIZE - 1:0] strb;
  } data_channel [$:16];

  resp_type_e resp;

  constraint rw_mode_c {
    rw inside {READ, WRITE};
  }

  constraint addr_channel_c {
    addr_channel.size == 3'b111;
    addr_channel.burst inside {FIXED, INCR, WRAP};
    addr_channel.lock inside {NORMAL, EXCLUSIVE, LOCKED};
  }

  constraint data_channel_c {
    data_channel.size() == addr_channel.len + 1;
  }

  constraint resp_channel_c {
    resp inside {OKAY, EXOKAY, SLVERR, DECERR};
  }

  function void make_burst (logic [ADDR_SIZE - 1:0] addr, logic [7:0] data []);

  endfunction

  function void report ();
    $display("axi3 transaction");
    $display("  rw : %s", rw);
    case (rw)
      READ: begin
        $display("  arid    : %0d", id);
        $display("  araddr  : %08x", addr_channel.addr);
        $display("  arlen   : %0d", addr_channel.len);
        $display("  arsize  : %0d", addr_channel.size);
        $display("  arburst : %0x", addr_channel.burst);
        $display("  arlock  : %0x", addr_channel.lock);
        $display("  arcache : %0x", addr_channel.cache);
        $display("  arprot  : %0x", addr_channel.prot);
        foreach (data_channel [i]) begin
          $display("  rid  [%02d] : %0d", i, id);
          $display("  rdata[%02d] : %032x", i, data_channel[i].data);
        end
      end
      WRITE: begin
        $display("  awid    : %0d", id);
        $display("  awaddr  : %08x", addr_channel.addr);
        $display("  awlen   : %0d", addr_channel.len);
        $display("  awsize  : %0d", addr_channel.size);
        $display("  awburst : %0x", addr_channel.burst);
        $display("  awlock  : %0x", addr_channel.lock);
        $display("  awcache : %0x", addr_channel.cache);
        $display("  awprot  : %0x", addr_channel.prot);
        foreach (data_channel [i]) begin
          $display("  wid  [%02d] : %0d", i, id);
          $display("  wdata[%02d] : %032x", i, data_channel[i].data);
          $display("  wstrb[%02d] : %04x", i, data_channel[i].strb);
        end
      end
    endcase
  endfunction
endclass
