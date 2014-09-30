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
  
    File         : pkg_amba3_axi_slave.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi slave
  
==============================================================================*/

class amba3_axi_slave_t
#(
  parameter integer AXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 32,
                    MAX_DELAY = 10
);

  typedef virtual amba3_axi_if #(AXID_SIZE, ADDR_SIZE, DATA_SIZE).slave axi_t;
  typedef amba3_axi_tx_t #(AXID_SIZE, ADDR_SIZE, DATA_SIZE) tx_t;
  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  axi_t axi;

  mailbox #(tx_t) waddr_q, wdata_q, wresp_q, raddr_q, rdata_q;

  logic [DATA_SIZE - 1:0] mems [logic [ADDR_SIZE - 1:4]];

  function new (input axi_t axi);
    this.axi = axi;
    this.waddr_q = new;
    this.wdata_q = new;
    this.wresp_q = new;
    this.raddr_q = new;
    this.rdata_q = new;
  endfunction

  virtual task start ();
    fork
      axi.slave_start();
      ready();
    join_none
  endtask

  virtual task ticks (input int tick);
    axi.slave_ticks(tick);
  endtask

  virtual task reset ();
    axi.slave_reset();
  endtask

  virtual task ready ();
    fork
      ready_waddr();
      ready_wdata();
      ready_wresp();
      ready_raddr();
      ready_rdata();
    join_none
  endtask

  virtual task ready_waddr ();
    forever begin
      tx_t tx = new;

      axi.slave_cb.awready <= 1'b1;
      @(axi.slave_cb);

      wait (axi.slave_cb.awvalid == 1'b1);

      tx.axid       = axi.slave_cb.awid;
      tx.addr.addr  = axi.slave_cb.awaddr;
      tx.addr.len   = axi.slave_cb.awlen;
      tx.addr.size  = axi.slave_cb.awsize;
      tx.addr.burst = axi.slave_cb.awburst;
      tx.addr.lock  = axi.slave_cb.awlock;
      tx.addr.cache = axi.slave_cb.awcache;
      tx.addr.prot  = axi.slave_cb.awprot;
      waddr_q.put(tx);
      axi.slave_cb.awready <= 1'b0;
    end
  endtask

  virtual task ready_wdata ();
    forever begin
      tx_t tx;
      waddr_q.get(tx);

      for (int i = 0; i < tx.addr.len; i++) begin
        axi.slave_cb.wready <= 1'b1;
        @(axi.slave_cb);

        wait (axi.slave_cb.wvalid == 1'b1);

        tx.data[i].data = axi.slave_cb.wdata;
      end

      wdata_q.put(tx);
      axi.slave_cb.wready <= 1'b0;
    end
  endtask

  virtual task ready_wresp ();
    forever begin
      tx_t tx;
      wdata_q.get(tx);

      axi.slave_cb.bid    <= tx.axid;
      axi.slave_cb.bresp  <= OKAY;
      axi.slave_cb.bvalid <= 1'b1;
      @(axi.slave_cb);

      wait (axi.slave_cb.bready == 1'b1);

      axi.slave_cb.bid    <= 'b0;
      axi.slave_cb.bresp  <= OKAY;
      axi.slave_cb.bvalid <= 1'b0;
    end
  endtask

  virtual task ready_raddr ();
    forever begin
      tx_t tx;

      axi.slave_cb.arready <= 1'b1;
      @(axi.slave_cb);

      wait (axi.slave_cb.arvalid == 1'b1);

      axi.slave_cb.arready <= 1'b1;
      tx = new;
      raddr_q.put(tx);
    end
  endtask

  virtual task ready_rdata ();
    forever begin
      tx_t tx;
      raddr_q.get(tx);

      axi.slave_cb.rvalid <= 1'b1;
      @(axi.slave_cb);

      wait (axi.slave_cb.rready == 1'b1);

      axi.slave_cb.rvalid <= 1'b0;
      rdata_q.put(tx);
    end
  endtask

  virtual function int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
