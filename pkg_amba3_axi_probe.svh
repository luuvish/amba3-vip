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

    File         : pkg_amba3_axi_probe.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi probe

==============================================================================*/

class amba3_axi_probe_t #(TXID_BITS = 4, ADDR_BITS = 32, DATA_BITS = 32);

  localparam integer STRB_BITS = DATA_BITS / 8;
  localparam integer DATA_BASE = $clog2(DATA_BITS / 8);

  typedef virtual amba3_axi_if #(TXID_BITS, ADDR_BITS, DATA_BITS).monitor axi_t;
  typedef amba3_axi_tx_t #(TXID_BITS, ADDR_BITS, DATA_BITS) tx_t;
  typedef logic [ADDR_BITS - 1:0] addr_t;
  typedef logic [DATA_BITS - 1:0] data_t;
  typedef logic [STRB_BITS - 1:0] strb_t;
  typedef struct {data_t data; strb_t strb;} item_t;

  protected axi_t axi;

  local mailbox #(tx_t) waddr_q, wresp_q, raddr_q;
  local tx_t wdata_q [$], paddr_q [$], pdata_q [$], rdata_q [$];

  local item_t fifo [addr_t[ADDR_BITS - 1:DATA_BASE]][$];
  local data_t mems [addr_t[ADDR_BITS - 1:DATA_BASE]];

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
    waddr_q = new;
    wresp_q = new;
    raddr_q = new;
    wdata_q.delete();
    paddr_q.delete();
    pdata_q.delete();
    rdata_q.delete();

    fork : loop
      begin
        axi.monitor_reset();
        disable loop;
      end
      forever waddr();
      forever wdata();
      forever wresp();
      forever raddr();
      forever rdata();
    join_any
    disable fork;
  endtask

  virtual task clear ();
    axi.monitor_clear();
  endtask

  virtual protected task waddr ();
    tx_t tx;
    axi.monitor_waddr(tx);
    waddr_q.put(tx);
  endtask

  virtual protected task wdata ();
    tx_t tx, rx;

    axi.monitor_wdata(rx);
    tx = find_tx(wdata_q, rx.txid);

    if (tx != null) begin
      tx.data[tx.data.size] = rx.data[0];
    end
    else begin
      tx = rx;
      wdata_q.push_back(tx);
    end
    if (rx.data[0].last == 1'b1) begin
      remove_tx(wdata_q, rx.txid);
      wresp_q.put(tx);
    end
  endtask

  virtual protected task wresp ();
    tx_t tx, rx;

    axi.monitor_wresp(rx);

    fill_q(paddr_q, waddr_q);
    fill_q(pdata_q, wresp_q);
    tx = find_tx(pdata_q, rx.txid);
    rx = find_tx(paddr_q, tx.txid);

    assert (rx != null && tx != null);
    if (rx != null && tx != null) begin
      tx.mode = rx.mode;
      tx.addr = rx.addr;
      assert (tx.data[tx.addr.len].last == (tx.data.size == tx.addr.len + 1));
      remove_tx(paddr_q, tx.txid);
      remove_tx(pdata_q, tx.txid);

      write(tx);
    end
  endtask

  virtual protected task raddr ();
    tx_t tx;
    axi.monitor_raddr(tx);
    raddr_q.put(tx);
  endtask

  virtual protected task rdata ();
    tx_t tx, rx;

    axi.monitor_rdata(rx);

    fill_q(rdata_q, raddr_q);
    tx = find_tx(rdata_q, rx.txid);

    assert (tx != null);
    if (tx != null) begin
      assert (rx.data[0].last == (tx.data.size == tx.addr.len));
      tx.data[tx.data.size] = rx.data[0];
      if (rx.data[0].last == 1'b1) begin
        remove_tx(rdata_q, rx.txid);

        read(tx);
      end
    end
  endtask

  virtual protected task write (input tx_t tx);
    for (int i = 0; i < tx.addr.len + 1; i++) begin
      int upper, lower;
      addr_t addr = tx.beat(i, upper, lower);

      item_t item = '{data: tx.data[i].data, strb:tx.data[i].strb};
      if (tx.addr.burst == FIXED) begin
        fifo[addr[ADDR_BITS - 1:DATA_BASE]].push_back(item);
      end
      else begin
        data_t data = mems[addr[ADDR_BITS - 1:DATA_BASE]];
        mems[addr[ADDR_BITS - 1:DATA_BASE]] = get_data(data, item);
      end
    end
  endtask

  virtual protected task read (input tx_t tx);
    for (int i = 0; i < tx.addr.len + 1; i++) begin
      int upper, lower;
      addr_t addr = tx.beat(i, upper, lower);

      item_t item;
      if (tx.addr.burst == FIXED) begin
        item = fifo[addr[ADDR_BITS - 1:DATA_BASE]].pop_front();
      end
      else begin
        item = '{data: mems[addr[ADDR_BITS - 1:DATA_BASE]], strb: '1};
      end
      tx.data[i].data = item.data;
    end
  endtask

  virtual protected function data_t get_data (input data_t data, item_t item);
    data_t merged = '0;
    foreach (item.strb [i]) begin
      data_t bytes = (item.strb[i] ? item.data : data);
      merged |= ((bytes >> (i * 8)) & 8'hFF) << (i * 8);
    end
    return merged;
  endfunction

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

endclass
