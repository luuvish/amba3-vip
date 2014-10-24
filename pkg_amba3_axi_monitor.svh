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

    File         : pkg_amba3_axi_monitor.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi monitor

==============================================================================*/

class amba3_axi_monitor_t #(
  parameter integer TXID_BITS = 4,
                    ADDR_BITS = 32,
                    DATA_BITS = 32
);

  typedef virtual amba3_axi_if #(TXID_BITS, ADDR_BITS, DATA_BITS).monitor axi_t;
  typedef amba3_axi_tx_t #(TXID_BITS, ADDR_BITS, DATA_BITS) tx_t;

  protected axi_t axi;
  protected integer file;

  local mailbox #(tx_t) waddr_q, wresp_q, raddr_q;
  local tx_t wdata_q [$], paddr_q [$], pdata_q [$], rdata_q [$];

  function new (input axi_t axi, string filename = "");
    this.axi = axi;
    this.file = -1;
    if (filename != "") begin
      this.file = $fopen(filename, "w");
    end
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
      forever begin
        tx_t tx;
        waddr(tx);
      end
      forever begin
        tx_t tx;
        wdata(tx);
      end
      forever begin
        tx_t tx;
        wresp(tx);
      end
      forever begin
        tx_t tx;
        raddr(tx);
      end
      forever begin
        tx_t tx;
        rdata(tx);
      end
    join_any
    disable fork;
  endtask

  virtual task clear ();
    axi.monitor_clear();
  endtask

  virtual protected task waddr (output tx_t tx);
    string log;

    axi.monitor_waddr(tx);

    log = $sformatf("@%0dns axi waddr %x %x %0d %0d %s %s %x %x", $time,
      tx.txid,
      tx.addr.addr, tx.addr.len, tx.addr.size, tx.addr.burst.name,
      tx.addr.lock.name, tx.addr.cache, tx.addr.prot
    );
    if (file == -1) $display(log); else $fdisplay(file, log);

    waddr_q.put(tx);
  endtask

  virtual protected task wdata (output tx_t tx);
    string log;
    tx_t rx;

    axi.monitor_wdata(rx);

    log = $sformatf("@%0dns axi wdata %x %x %x %0d", $time,
      rx.txid, rx.data[0].data, rx.data[0].strb, rx.data[0].last
    );
    if (file == -1) $display(log); else $fdisplay(file, log);

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

  virtual protected task wresp (output tx_t tx);
    string log;
    tx_t rx;

    axi.monitor_wresp(rx);

    log = $sformatf("@%0dns axi wresp %x %s", $time, rx.txid, rx.resp.name);
    if (file == -1) $display(log); else $fdisplay(file, log);

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
    end
  endtask

  virtual protected task raddr (output tx_t tx);
    string log;

    axi.monitor_raddr(tx);

    log = $sformatf("@%0dns axi raddr %x %x %0d %0d %s %s %x %x", $time,
      tx.txid,
      tx.addr.addr, tx.addr.len, tx.addr.size, tx.addr.burst.name,
      tx.addr.lock.name, tx.addr.cache, tx.addr.prot
    );
    if (file == -1) $display(log); else $fdisplay(file, log);

    raddr_q.put(tx);
  endtask

  virtual protected task rdata (output tx_t tx);
    string log;
    tx_t rx;

    axi.monitor_rdata(rx);

    log = $sformatf("@%0dns axi rdata %x %x %s %0d", $time,
      rx.txid, rx.data[0].data, rx.data[0].resp.name, rx.data[0].last
    );
    if (file == -1) $display(log); else $fdisplay(file, log);

    fill_q(rdata_q, raddr_q);
    tx = find_tx(rdata_q, rx.txid);

    assert (tx != null);
    if (tx != null) begin
      assert (rx.data[0].last == (tx.data.size == tx.addr.len));
      tx.data[tx.data.size] = rx.data[0];
      if (rx.data[0].last == 1'b1) begin
        remove_tx(rdata_q, rx.txid);
      end
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

endclass
