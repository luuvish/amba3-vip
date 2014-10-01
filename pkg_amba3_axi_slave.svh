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
  localparam integer ADDR_BASE = $clog2(STRB_SIZE);

  typedef virtual amba3_axi_if #(TXID_SIZE, ADDR_SIZE, DATA_SIZE).slave axi_t;
  typedef amba3_axi_tx_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) tx_t;
  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  axi_t axi;

  mailbox #(tx_t) waddr_q, wresp_q, raddr_q;
  tx_t wdata_q [$];

  data_t mems [addr_t[ADDR_SIZE - 1:ADDR_BASE]];

  function new (input axi_t axi);
    this.axi = axi;
    this.waddr_q = new (MAX_QUEUE);
    this.wresp_q = new (MAX_QUEUE);
    this.raddr_q = new (MAX_QUEUE);
  endfunction

  virtual task listen ();
    fork
      forever begin
        tx_t rx;
        ticks(random_delay());
        axi.slave_waddr(rx);

        if (rx != null)
          waddr_q.put(rx);
      end
      forever begin
        tx_t rx, tx;
        ticks(random_delay());
        axi.slave_wdata(rx);

        if (rx != null) begin
          while (waddr_q.try_get(tx))
            wdata_q.push_back(tx);

          tx = find_tx(wdata_q, rx.txid, rx.data[0].last);
          assert(rx.data[0].last == (tx.data.size == tx.addr.len));

          tx.data[tx.data.size] = rx.data[0];
          if (rx.data[0].last)
            wresp_q.put(tx);
        end
      end
      forever begin
        tx_t tx;
        wresp_q.get(tx);

        ticks(random_delay());
        write(tx);
        axi.slave_wresp(tx);
      end
      forever begin
        tx_t rx;
        ticks(random_delay());
        axi.slave_raddr(rx);

        if (rx != null)
          raddr_q.put(rx);
      end
      forever begin
        tx_t tx;
        raddr_q.get(tx);
        read(tx);

        for (int i = 0; i < tx.addr.len + 1; i++) begin
          ticks(random_delay());
          axi.slave_rdata(tx, i);
          //tx.report($sformatf("@%0dns rdata", $time));
        end
      end
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

  virtual task write (input tx_t tx);
    if (tx.addr.burst == FIXED) begin
      mems[tx.addr.addr[ADDR_SIZE - 1:ADDR_BASE]] = tx.data[tx.addr.len].data;
    end
    if (tx.addr.burst == INCR) begin
      for (int i = 0; i < tx.addr.len + 1; i++) begin
        mems[tx.addr.addr[ADDR_SIZE - 1:ADDR_BASE] + i] = tx.data[i].data;
      end
    end
  endtask

  virtual task read (input tx_t tx);
    for (int i = 0; i < tx.addr.len + 1; i++) begin
      if (tx.addr.burst == FIXED) begin
        tx.data[i].data = mems[tx.addr.addr[ADDR_SIZE - 1:ADDR_BASE]];
      end
      if (tx.addr.burst == INCR) begin
        tx.data[i].data = mems[tx.addr.addr[ADDR_SIZE - 1:ADDR_BASE] + i];
      end
    end
  endtask

  virtual function tx_t find_tx (ref tx_t q [$], input int txid, bit remove=1);
    tx_t tx;
    int qi [$];
    qi = q.find_first_index with (item.txid == txid);
    tx = q[qi[0]];
    if (remove) q.delete(qi[0]);
    return tx;
  endfunction

  virtual function int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
