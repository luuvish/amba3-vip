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
  parameter integer TXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 32,
                    MAX_DELAY = 10,
                    MAX_QUEUE = 10
);

  localparam integer STRB_SIZE = DATA_SIZE / 8;

  typedef virtual amba3_axi_if #(TXID_SIZE, ADDR_SIZE, DATA_SIZE).slave axi_t;
  typedef amba3_axi_tx_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) tx_t;
  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  axi_t axi;

  mailbox #(tx_t) waddr_q, wdata_q, wresp_q, raddr_q, rdata_q;

  logic [DATA_SIZE - 1:0] mems [logic [ADDR_SIZE - 1:4]];

  function new (input axi_t axi);
    this.axi = axi;
    this.waddr_q = new (MAX_QUEUE);
    this.wdata_q = new (MAX_QUEUE);
    this.wresp_q = new (MAX_QUEUE);
    this.raddr_q = new (MAX_QUEUE);
    this.rdata_q = new (MAX_QUEUE);
  endfunction

  virtual task listen ();
    fork
      listen_waddr();
      listen_wdata();
      listen_wresp();
      listen_raddr();
      listen_rdata();
    join_none
  endtask

  virtual task start ();
    axi.slave_start();
    fork
      listen();
    join_none
  endtask

  virtual task ticks (input int tick);
    axi.slave_ticks(tick);
  endtask

  virtual task reset ();
    axi.slave_reset();
  endtask

  virtual task listen_waddr ();
    forever begin
      axi.slave_cb.awready <= waddr_q.num < MAX_QUEUE;
      @(axi.slave_cb);

      wait (axi.slave_cb.awvalid == 1'b1);
      if (axi.slave_cb.awready == 1'b1) begin
        tx_t tx = new;
        tx.mode       = tx_t::WRITE;
        tx.txid       = axi.slave_cb.awid;
        tx.addr.addr  = axi.slave_cb.awaddr;
        tx.addr.len   = axi.slave_cb.awlen;
        tx.addr.size  = axi.slave_cb.awsize;
        tx.addr.burst = axi.slave_cb.awburst;
        tx.addr.lock  = axi.slave_cb.awlock;
        tx.addr.cache = axi.slave_cb.awcache;
        tx.addr.prot  = axi.slave_cb.awprot;
        //tx.report($sformatf("@%0dns waddr", $time));
        waddr_q.put(tx);
      end

      axi.slave_cb.awready <= 1'b0;
    end
  endtask

  virtual task listen_wdata ();
    tx_t wdata_q [$];

    forever begin
      axi.slave_cb.wready <= 1'b1;
      @(axi.slave_cb);

      wait (axi.slave_cb.wvalid == 1'b1);
      if (axi.slave_cb.wready == 1'b1) begin
        tx_t tx;
        int qi [$];
        int i;

        while (waddr_q.try_get(tx)) wdata_q.push_back(tx);
        qi = wdata_q.find_first_index with (item.txid == axi.slave_cb.wid);
        tx = wdata_q[qi[0]];
        i = tx.data.size;
        assert(tx.txid == axi.slave_cb.wid);
        tx.data[i].data = axi.slave_cb.wdata;
        tx.data[i].strb = axi.slave_cb.wstrb;
        assert((i == tx.addr.len) == axi.slave_cb.wlast);
        tx.report($sformatf("@%0dns wdata", $time));
        if (axi.slave_cb.wlast) begin
          wdata_q.delete(qi[0]);
          wresp_q.put(tx);
        end
      end

      axi.slave_cb.wready <= 1'b0;
    end
  endtask

  virtual task listen_wresp ();
    forever begin
      tx_t tx;
      wresp_q.get(tx);

      axi.slave_cb.bid    <= tx.txid;
      axi.slave_cb.bresp  <= OKAY;
      axi.slave_cb.bvalid <= 1'b1;
      @(axi.slave_cb);

      wait (axi.slave_cb.bready == 1'b1);
      axi.slave_cb.bvalid <= 1'b0;
    end
  endtask

  virtual task listen_raddr ();
    forever begin
      axi.slave_cb.arready <= raddr_q.num < MAX_QUEUE;
      @(axi.slave_cb);

      wait (axi.slave_cb.arvalid == 1'b1);
      if (axi.slave_cb.arready == 1'b1) begin
        tx_t tx = new;
        tx.mode       = tx_t::READ;
        tx.txid       = axi.slave_cb.arid;
        tx.addr.addr  = axi.slave_cb.araddr;
        tx.addr.len   = axi.slave_cb.arlen;
        tx.addr.size  = axi.slave_cb.arsize;
        tx.addr.burst = axi.slave_cb.arburst;
        tx.addr.lock  = axi.slave_cb.arlock;
        tx.addr.cache = axi.slave_cb.arcache;
        tx.addr.prot  = axi.slave_cb.arprot;
        //tx.report($sformatf("@%0dns raddr", $time));
        raddr_q.put(tx);
      end

      axi.slave_cb.arready <= 1'b0;
    end
  endtask

  virtual task listen_rdata ();
    forever begin
      tx_t tx;
      raddr_q.get(tx);

      for (int i = 0; i < tx.addr.len + 1; i++) begin
        axi.slave_cb.rid    <= tx.txid;
        axi.slave_cb.rdata  <= tx.data[i].data;
        axi.slave_cb.rresp  <= OKAY;
        axi.slave_cb.rlast  <= (i == tx.addr.len);
        axi.slave_cb.rvalid <= 1'b1;
        @(axi.slave_cb);

        wait (axi.slave_cb.rready == 1'b1);
        //tx.report($sformatf("@%0dns rdata", $time));
      end

      axi.slave_cb.rlast  <= 1'b0;
      axi.slave_cb.rvalid <= 1'b0;
    end
  endtask

  virtual function int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
