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

  localparam integer STRB_BITS = DATA_BITS / 8;

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
      forever report_waddr();
      forever report_wdata();
      forever report_wresp();
      forever report_raddr();
      forever report_rdata();
      forever check_waddr();
      forever check_wdata();
      forever check_wresp();
      forever check_raddr();
      forever check_rdata();
      forever check_waddr_4k_boundary();
      forever check_raddr_4k_boundary();
    join_any
    disable fork;
  endtask

  virtual task clear ();
    axi.monitor_clear();
  endtask

  virtual protected task report_waddr ();
    tx_t tx;

    axi.monitor_waddr(tx);
    waddr_q.put(tx);

    report($sformatf("axi waddr %x %x %0d %0d %s %s %x %x",
      tx.txid, tx.addr.addr, tx.addr.len, tx.addr.size, tx.addr.burst.name,
      tx.addr.lock.name, tx.addr.cache, tx.addr.prot
    ));
  endtask

  virtual protected task report_wdata ();
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

    report($sformatf("axi wdata %x %x %x %0d",
      tx.txid,
      tx.data[tx.data.size - 1].data,
      tx.data[tx.data.size - 1].strb,
      tx.data[tx.data.size - 1].last
    ));
  endtask

  virtual protected task report_wresp ();
    int upper, lower;
    tx_t tx, rx;

    axi.monitor_wresp(rx);

    report($sformatf("axi wresp %x %s", rx.txid, rx.resp.name));

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

      foreach (tx.data [i]) begin
        report($sformatf("axi wresp %x %x %0d/%0d %s %x %x %0d",
          tx.txid, tx.beat(i, upper, lower),
          i, tx.addr.len + 1, tx.addr.burst.name,
          tx.data[i].data, tx.data[i].strb, tx.data[i].last
        ));
      end
    end
  endtask

  virtual protected task report_raddr ();
    tx_t tx;
    axi.monitor_raddr(tx);
    raddr_q.put(tx);

    report($sformatf("axi raddr %x %x %0d %0d %s %s %x %x",
      tx.txid, tx.addr.addr, tx.addr.len, tx.addr.size, tx.addr.burst.name,
      tx.addr.lock.name, tx.addr.cache, tx.addr.prot
    ));
  endtask

  virtual protected task report_rdata ();
    int upper, lower;
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
      end

      report($sformatf("axi rdata %x %x %0d/%0d %s %x %s %0d",
        tx.txid,
        tx.beat(tx.data.size - 1, upper, lower),
        tx.data.size - 1, tx.addr.len + 1, tx.addr.burst.name,
        tx.data[tx.data.size - 1].data,
        tx.data[tx.data.size - 1].resp.name,
        tx.data[tx.data.size - 1].last
      ));
    end
  endtask

  virtual protected task check_waddr ();
    typedef struct {
      logic [TXID_BITS - 1:0] awid;
      logic [ADDR_BITS - 1:0] awaddr;
      logic [            3:0] awlen;
      logic [            2:0] awsize;
      burst_type_t            awburst;
      lock_type_t             awlock;
      cache_attr_t            awcache;
      prot_attr_t             awprot;
      logic                   awvalid;
      logic                   awready;
    } hold_t;

    static hold_t zero = '{
      awburst: burst_type_t'(2'b0),
      awlock : lock_type_t'(2'b0),
      awcache: cache_attr_t'(4'b0),
      awprot : prot_attr_t'(3'b0),
      default: '0
    };
    static hold_t hold = zero;

    hold_t now = '{
      awid   : axi.monitor_cb.awid,
      awaddr : axi.monitor_cb.awaddr,
      awlen  : axi.monitor_cb.awlen,
      awsize : axi.monitor_cb.awsize,
      awburst: axi.monitor_cb.awburst,
      awlock : axi.monitor_cb.awlock,
      awcache: axi.monitor_cb.awcache,
      awprot : axi.monitor_cb.awprot,
      awvalid: axi.monitor_cb.awvalid,
      awready: axi.monitor_cb.awready
    };

    if (hold.awvalid == 1'b1) begin
      if (hold.awid != now.awid)
        report($sformatf("axi check awid %x is changed before awready",
          now.awid
        ));
      if (hold.awaddr != now.awaddr)
        report($sformatf("axi check awaddr %x is changed before awready",
          now.awaddr
        ));
      if (hold.awlen != now.awlen)
        report($sformatf("axi check awlen %0d is changed before awready",
          now.awlen
        ));
      if (hold.awsize != now.awsize)
        report($sformatf("axi check awsize %0d is changed before awready",
          now.awsize
        ));
      if (hold.awburst != now.awburst)
        report($sformatf("axi check awburst %s is changed before awready",
          now.awburst.name
        ));
      if (hold.awlock != now.awlock)
        report($sformatf("axi check awlock %s is changed before awready",
          now.awlock.name
        ));
      if (hold.awcache != now.awcache)
        report($sformatf("axi check awcache %x is changed before awready",
          now.awcache
        ));
      if (hold.awprot != now.awprot)
        report($sformatf("axi check awprot %x is changed before awready",
          now.awprot
        ));
    end

    if (now.awvalid == 1'b1 && now.awready == 1'b1)
      hold <= zero;
    else
      hold <= now;

    @(axi.monitor_cb);
  endtask

  virtual protected task check_wdata ();
    typedef struct {
      logic [TXID_BITS - 1:0] wid;
      logic [DATA_BITS - 1:0] wdata;
      logic [STRB_BITS - 1:0] wstrb;
      logic                   wlast;
      logic                   wvalid;
      logic                   wready;
    } hold_t;

    static hold_t hold = '{default: '0};

    hold_t now = '{
      wid   : axi.monitor_cb.wid,
      wdata : axi.monitor_cb.wdata,
      wstrb : axi.monitor_cb.wstrb,
      wlast : axi.monitor_cb.wlast,
      wvalid: axi.monitor_cb.wvalid,
      wready: axi.monitor_cb.wready
    };

    if (hold.wvalid == 1'b1) begin
      if (hold.wid != now.wid)
        report($sformatf("axi check wid %x is changed before wready",
          now.wid
        ));
      if (hold.wdata != now.wdata)
        report($sformatf("axi check wdata %x is changed before wready",
          now.wdata
        ));
      if (hold.wstrb != now.wstrb)
        report($sformatf("axi check wstrb %x is changed before wready",
          now.wstrb
        ));
      if (hold.wlast != now.wlast)
        report($sformatf("axi check wlast %0d is changed before wready",
          now.wlast
        ));
    end

    if (now.wvalid == 1'b1 && now.wready == 1'b1)
      hold <= '{default: '0};
    else
      hold <= now;

    @(axi.monitor_cb);
  endtask

  virtual protected task check_wresp ();
    typedef struct {
      logic [TXID_BITS - 1:0] bid;
      resp_type_t             bresp;
      logic                   bvalid;
      logic                   bready;
    } hold_t;

    static hold_t hold = '{bresp: resp_type_t'(2'b0), default: '0};

    hold_t now = '{
      bid   : axi.monitor_cb.bid,
      bresp : axi.monitor_cb.bresp,
      bvalid: axi.monitor_cb.bvalid,
      bready: axi.monitor_cb.bready
    };

    if (hold.bvalid == 1'b1) begin
      if (hold.bid != now.bid)
        report($sformatf("axi check bid %x is changed before bready",
          now.bid
        ));
      if (hold.bresp != now.bresp)
        report($sformatf("axi check bresp %s is changed before bready",
          now.bresp.name
        ));
    end

    if (now.bvalid == 1'b1 && now.bready == 1'b1)
      hold <= '{bresp: resp_type_t'(2'b0), default: '0};
    else
      hold <= now;

    @(axi.monitor_cb);
  endtask

  virtual protected task check_raddr ();
    typedef struct {
      logic [TXID_BITS - 1:0] arid;
      logic [ADDR_BITS - 1:0] araddr;
      logic [            3:0] arlen;
      logic [            2:0] arsize;
      burst_type_t            arburst;
      lock_type_t             arlock;
      cache_attr_t            arcache;
      prot_attr_t             arprot;
      logic                   arvalid;
      logic                   arready;
    } hold_t;

    static hold_t zero = '{
      arburst: burst_type_t'(2'b0),
      arlock : lock_type_t'(2'b0),
      arcache: cache_attr_t'(4'b0),
      arprot : prot_attr_t'(3'b0),
      default: '0
    };
    static hold_t hold = zero;

    hold_t now = '{
      arid   : axi.monitor_cb.arid,
      araddr : axi.monitor_cb.araddr,
      arlen  : axi.monitor_cb.arlen,
      arsize : axi.monitor_cb.arsize,
      arburst: axi.monitor_cb.arburst,
      arlock : axi.monitor_cb.arlock,
      arcache: axi.monitor_cb.arcache,
      arprot : axi.monitor_cb.arprot,
      arvalid: axi.monitor_cb.arvalid,
      arready: axi.monitor_cb.arready
    };

    if (hold.arvalid == 1'b1) begin
      if (hold.arid != now.arid)
        report($sformatf("axi check arid %x is changed before arready",
          now.arid
        ));
      if (hold.araddr != now.araddr)
        report($sformatf("axi check araddr %x is changed before arready",
          now.araddr
        ));
      if (hold.arlen != now.arlen)
        report($sformatf("axi check arlen %0d is changed before arready",
          now.arlen
        ));
      if (hold.arsize != now.arsize)
        report($sformatf("axi check arsize %0d is changed before arready",
          now.arsize
        ));
      if (hold.arburst != now.arburst)
        report($sformatf("axi check arburst %s is changed before arready",
          now.arburst.name
        ));
      if (hold.arlock != now.arlock)
        report($sformatf("axi check arlock %s is changed before arready",
          now.arlock.name
        ));
      if (hold.arcache != now.arcache)
        report($sformatf("axi check arcache %x is changed before arready",
          now.arcache
        ));
      if (hold.arprot != now.arprot)
        report($sformatf("axi check arprot %x is changed before arready",
          now.arprot
        ));
    end

    if (now.arvalid == 1'b1 && now.arready == 1'b1)
      hold <= zero;
    else
      hold <= now;

    @(axi.monitor_cb);
  endtask

  virtual protected task check_rdata ();
    typedef struct {
      logic [TXID_BITS - 1:0] rid;
      logic [DATA_BITS - 1:0] rdata;
      resp_type_t             rresp;
      logic                   rlast;
      logic                   rvalid;
      logic                   rready;
    } hold_t;

    static hold_t hold = '{rresp: resp_type_t'(2'b0), default: '0};

    hold_t now = '{
      rid   : axi.monitor_cb.rid,
      rdata : axi.monitor_cb.rdata,
      rresp : axi.monitor_cb.rresp,
      rlast : axi.monitor_cb.rlast,
      rvalid: axi.monitor_cb.rvalid,
      rready: axi.monitor_cb.rready
    };

    if (hold.rvalid == 1'b1) begin
      if (hold.rid != now.rid)
        report($sformatf("axi check rid %x is changed before rready",
          now.rid
        ));
      if (hold.rdata != now.rdata)
        report($sformatf("axi check rdata %x is changed before rready",
          now.rdata
        ));
      if (hold.rresp != now.rresp)
        report($sformatf("axi check rresp %s is changed before rready",
          now.rresp.name
        ));
      if (hold.rlast != now.rlast)
        report($sformatf("axi check rlast %0d is changed before rready",
          now.rlast
        ));
    end

    if (now.rvalid == 1'b1 && now.rready == 1'b1)
      hold <= '{rresp: resp_type_t'(2'b0), default: '0};
    else
      hold <= now;

    @(axi.monitor_cb);
  endtask

  virtual protected task check_waddr_4k_boundary ();
    int addr, upper, lower;
    tx_t tx;

    axi.monitor_waddr(tx);

    addr = tx.beat(0, upper, lower) / 4096;
    for (int i = 1; i < tx.addr.len + 1; i++) begin
      if (addr != tx.beat(i, upper, lower) / 4096) begin
        report($sformatf("axi check waddr %x %x %0d %s 4k boundary violation",
          tx.txid, tx.addr.addr, tx.addr.len, tx.addr.burst.name
        ));
        break;
      end
    end
  endtask

  virtual protected task check_raddr_4k_boundary ();
    int addr, upper, lower;
    tx_t tx;

    axi.monitor_raddr(tx);

    addr = tx.beat(0, upper, lower) / 4096;
    for (int i = 1; i < tx.addr.len + 1; i++) begin
      if (addr != tx.beat(i, upper, lower) / 4096) begin
        report($sformatf("axi check raddr %x %x %0d %s 4k boundary violation",
          tx.txid, tx.addr.addr, tx.addr.len, tx.addr.burst.name
        ));
        break;
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

  virtual task report (input string text);
    string log = $sformatf("@%0dns %s", $time, text);

    if (file == -1)
      $display(log);
    else
      $fdisplay(file, log);
  endtask

endclass
