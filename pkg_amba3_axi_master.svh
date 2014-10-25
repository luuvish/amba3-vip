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

class amba3_axi_master_t #(
  parameter integer TXID_BITS = 4,
                    ADDR_BITS = 32,
                    DATA_BITS = 32,
                    MAX_DELAY = 10,
                    MAX_QUEUE = 10
);

  typedef virtual amba3_axi_if #(TXID_BITS, ADDR_BITS, DATA_BITS).master axi_t;
  typedef amba3_axi_tx_t #(TXID_BITS, ADDR_BITS, DATA_BITS) tx_t;
  typedef logic [ADDR_BITS - 1:0] addr_t;
  typedef logic [DATA_BITS - 1:0] data_t;

  protected axi_t axi;

  local mailbox #(tx_t) waddr_q, wdata_q, raddr_q;
  local tx_t wresp_q [$], rdata_q [$];

  function new (input axi_t axi);
    this.axi = axi;
  endfunction

  virtual task start ();
    clear();
    fork
      forever begin
        listen();
      end
    join_none
  endtask

  virtual task listen ();
    waddr_q = new (MAX_QUEUE);
    wdata_q = new (MAX_QUEUE);
    raddr_q = new (MAX_QUEUE);
    wresp_q.delete();
    rdata_q.delete();

    fork : loop
      begin
        axi.master_reset();
        disable loop;
      end
      forever wdata();
      forever wresp();
      forever rdata();
    join_any
    disable fork;
  endtask

  virtual task clear ();
    axi.master_clear();
  endtask

  virtual task ticks (input int tick);
    axi.master_ticks(tick);
  endtask

  virtual task write (input tx_t tx, bit resp = 1'b0);
    bit pre_wdata = MAX_DELAY > 0 && $urandom_range(0, 1);

    tx.mode = tx_t::WRITE;
    assert (tx.data.size == tx.addr.len + 1);
    ticks(random_delay());
    if (pre_wdata == 1'b1) waddr_q.put(tx);
    axi.master_waddr(tx);
    if (pre_wdata == 1'b0) waddr_q.put(tx);

    if (resp == 1'b1)
      wait (tx.done.triggered);
  endtask

  virtual task read (input tx_t tx, bit resp = 1'b0);
    tx.mode = tx_t::READ;
    tx.data.delete();
    ticks(random_delay());
    axi.master_raddr(tx);
    raddr_q.put(tx);

    if (resp == 1'b1)
      wait (tx.done.triggered);
  endtask

  virtual protected task wdata ();
    tx_t tx;
    waddr_q.get(tx);
    for (int i = 0; i < tx.addr.len + 1; i++) begin
      ticks(random_delay());
      axi.master_wdata(tx, i);
    end
    wdata_q.put(tx);
  endtask

  virtual protected task wresp ();
    tx_t tx, rx;

    wait_q(wresp_q, wdata_q);
    ticks(random_delay());
    axi.master_wresp(rx);

    fill_q(wresp_q, wdata_q);
    tx = find_tx(wresp_q, rx.txid);

    assert (tx != null);
    if (tx != null) begin
      tx.resp = rx.resp;
      remove_tx(wresp_q, rx.txid);
      -> tx.done;
    end
  endtask

  virtual protected task rdata ();
    tx_t tx, rx;

    wait_q(rdata_q, raddr_q);
    ticks(random_delay());
    axi.master_rdata(rx);

    fill_q(rdata_q, raddr_q);
    tx = find_tx(rdata_q, rx.txid);

    assert (tx != null);
    if (tx != null) begin
      assert (rx.data[0].resp == OKAY);
      assert (rx.data[0].last == (tx.data.size == tx.addr.len));
      tx.data[tx.data.size] = rx.data[0];
      if (rx.data[0].last == 1'b1) begin
        remove_tx(rdata_q, rx.txid);
        -> tx.done;
      end
    end
  endtask

  virtual protected task wait_q (ref tx_t q [$], mailbox #(tx_t) m);
    while (q.size == 0) begin
      fill_q(q, m);
      ticks(1);
    end
  endtask

  virtual protected function void fill_q (ref tx_t q [$], mailbox #(tx_t) m);
    tx_t tx;
    while (m.try_get(tx))
      q.push_back(tx);
  endfunction

  virtual protected function tx_t find_tx (ref tx_t q [$], input int txid);
    int qi [$] = q.find_first_index with (item.txid == txid);
    return qi.size > 0 ? q[qi[0]] : null;
  endfunction

  virtual protected function void remove_tx (ref tx_t q [$], input int txid);
    int qi [$] = q.find_first_index with (item.txid == txid);
    assert (qi.size > 0);
    if (qi.size > 0)
      q.delete(qi[0]);
  endfunction

  virtual protected function int random_delay ();
    int zero_delay = MAX_DELAY == 0 || $urandom_range(0, 1);
    return zero_delay ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
