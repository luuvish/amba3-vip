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

  mailbox #(tx_t) waddr_q, wdata_q, raddr_q;

  function new (input axi_t axi);
    this.axi = axi;
  endfunction

  virtual task start ();
    clear();
    fork
      forever begin
        fork
          reset();
          listen();
        join
      end
    join_none
  endtask

  virtual task reset ();
    axi.master_reset();
  endtask

  virtual task listen ();
    tx_t wresp_q [$], rdata_q [$];

    waddr_q = new (MAX_QUEUE);
    wdata_q = new (MAX_QUEUE);
    raddr_q = new (MAX_QUEUE);

    fork
      forever begin
        tx_t tx;

        waddr_q.get(tx);
        for (int i = 0; i < tx.addr.len + 1; i++) begin
          ticks(random_delay());
          axi.master_wdata(tx, i);
        end
        wdata_q.put(tx);
      end
      forever begin
        tx_t rx, tx;

        wait_q(wresp_q, wdata_q);
        ticks(random_delay());
        axi.master_wresp(rx);

        fill_q(wresp_q, wdata_q);
        tx = find_tx(wresp_q, rx.txid);

        assert(rx.resp == OKAY);
        tx.resp = rx.resp;
        remove_tx(wresp_q, rx.txid);
        -> tx.done;
      end
      forever begin
        tx_t rx, tx;

        wait_q(rdata_q, raddr_q);
        ticks(random_delay());
        axi.master_rdata(rx);

        fill_q(rdata_q, raddr_q);
        tx = find_tx(rdata_q, rx.txid);

        assert(rx.data[0].resp == OKAY);
        assert(rx.data[0].last == (tx.data.size == tx.addr.len));
        tx.data[tx.data.size] = rx.data[0];
        if (rx.data[0].last == 1'b1) begin
          remove_tx(rdata_q, rx.txid);
          -> tx.done;
        end
      end
    join_none
  endtask

  virtual task clear ();
    axi.master_clear();
  endtask

  virtual task ticks (input int tick);
    axi.master_ticks(tick);
  endtask

  virtual task write (input tx_t tx, input bit resp = 0);
    ticks(random_delay());
    waddr_q.put(tx);
    axi.master_waddr(tx);

    if (resp == 1'b1)
      wait (tx.done.triggered);
  endtask

  virtual task read (input tx_t tx, input bit resp = 0);
    ticks(random_delay());
    axi.master_raddr(tx);
    raddr_q.put(tx);

    if (resp == 1'b1)
      wait (tx.done.triggered);
  endtask

  virtual task wait_q (ref tx_t q [$], mailbox #(tx_t) m);
    while (q.size == 0) begin
      fill_q(q, m);
      ticks(1);
    end
  endtask

  virtual function void fill_q (ref tx_t q [$], mailbox #(tx_t) m);
    tx_t tx;
    while (m.try_get(tx))
      q.push_back(tx);
  endfunction

  virtual function tx_t find_tx (ref tx_t q [$], input int txid);
    int qi [$] = q.find_first_index with (item.txid == txid);
    assert(qi.size > 0);
    return q[qi[0]];
  endfunction

  virtual function void remove_tx (ref tx_t q [$], input int txid);
    int qi [$] = q.find_first_index with (item.txid == txid);
    assert(qi.size > 0);
    q.delete(qi[0]);
  endfunction

  virtual function int random_delay ();
    int zero_delay = MAX_DELAY == 0 || $urandom_range(0, 1);
    return zero_delay ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
