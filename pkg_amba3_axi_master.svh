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

    File         : pkg_amba3_axi_master.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi master

==============================================================================*/

class amba3_axi_master_t
#(
  parameter integer TXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 32,
                    MAX_DELAY = 10,
                    MAX_QUEUE = 10
);

  typedef virtual amba3_axi_if #(TXID_SIZE, ADDR_SIZE, DATA_SIZE).master axi_t;
  typedef amba3_axi_tx_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) tx_t;
  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  axi_t axi;

  mailbox #(tx_t) waddr_q, wdata_q, wresp_q, raddr_q, rdata_q;

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
      wdata();
      wresp();
      rdata();
    join_none
  endtask

  virtual task start ();
    axi.master_start();
    fork
      listen();
    join_none
  endtask

  virtual task ticks (input int tick);
    axi.master_ticks(tick);
  endtask

  virtual task reset ();
    axi.master_reset();
  endtask

  virtual task write (input tx_t tx, input bit resp = 0);
    waddr_q.put(tx);
    ticks(random_delay());
    axi.master_write(tx);
  endtask

  virtual task read (input tx_t tx, input bit resp = 0);
    ticks(random_delay());
    axi.master_read(tx);
    raddr_q.put(tx);
  endtask

  virtual task wdata ();
    forever begin
      tx_t tx;
      waddr_q.get(tx);

      for (int i = 0; i < tx.addr.len + 1; i++) begin
        //ticks(random_delay());

        axi.master_cb.wid    <= tx.txid;
        axi.master_cb.wdata  <= tx.data[i].data;
        axi.master_cb.wstrb  <= tx.data[i].strb;
        axi.master_cb.wlast  <= (i == tx.addr.len);
        axi.master_cb.wvalid <= 1'b1;
        @(axi.master_cb);

        wait (axi.master_cb.wready == 1'b1);
      end

      axi.master_cb.wlast  <= 1'b0;
      axi.master_cb.wvalid <= 1'b0;
      wdata_q.put(tx);
    end
  endtask

  virtual task wresp ();
    tx_t wresp_q [$];

    forever begin
      axi.master_cb.bready <= 1'b1;
      @(axi.master_cb);

      wait (axi.master_cb.bvalid == 1'b1);
      if (axi.master_cb.bready == 1'b1) begin
        tx_t tx;
        int qi [$];

        while (wdata_q.try_get(tx)) wresp_q.push_back(tx);
        qi = wresp_q.find_first_index with (item.txid == axi.master_cb.bid);
        tx = wresp_q[qi[0]];
        assert(tx.txid == axi.master_cb.bid);
        assert(OKAY == axi.master_cb.bresp);
        tx.resp = axi.master_cb.bresp;
        wresp_q.delete(qi[0]);
      end

      axi.master_cb.bready <= 1'b0;
    end
  endtask

  virtual task rdata ();
    tx_t rdata_q [$];

    forever begin
      axi.master_cb.rready <= 1'b1;
      @(axi.master_cb);

      wait (axi.master_cb.rvalid == 1'b1);
      if (axi.master_cb.rready == 1'b1) begin
        tx_t tx;
        int qi [$];
        int i;

        while (raddr_q.try_get(tx)) rdata_q.push_back(tx);
        qi = rdata_q.find_first_index with (item.txid == axi.master_cb.rid);
        tx = rdata_q[qi[0]];
        i = tx.data.size;
        assert(tx.txid == axi.master_cb.rid);
        tx.data[i].data = axi.master_cb.rdata;
        assert(OKAY == axi.master_cb.rresp);
        assert((i == tx.addr.len) == axi.master_cb.rlast);
        if (axi.master_cb.rlast) begin
          rdata_q.delete(qi[0]);
        end
      end

      axi.master_cb.rready <= 1'b0;
    end
  endtask

  virtual function int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
