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

    File         : pkg_amba3_axi_if.sv
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi interface

==============================================================================*/

interface amba3_axi_if #(
  parameter integer TXID_BITS = 4,
                    ADDR_BITS = 32,
                    DATA_BITS = 32
) (input logic aclk, input logic areset_n);

  import pkg_amba3::*;

  localparam integer STRB_BITS = DATA_BITS / 8;

  typedef amba3_axi_tx_t #(TXID_BITS, ADDR_BITS, DATA_BITS) tx_t;
  typedef logic [ADDR_BITS - 1:0] addr_t;
  typedef logic [DATA_BITS - 1:0] data_t;
  typedef logic [STRB_BITS - 1:0] strb_t;

  // write address channel signals
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

  // write data channel signals
  logic [TXID_BITS - 1:0] wid;
  logic [DATA_BITS - 1:0] wdata;
  logic [STRB_BITS - 1:0] wstrb;
  logic                   wlast;
  logic                   wvalid;
  logic                   wready;

  // write response channel signals
  logic [TXID_BITS - 1:0] bid;
  resp_type_t             bresp;
  logic                   bvalid;
  logic                   bready;

  // read address channel signals
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

  // read data channel signals
  logic [TXID_BITS - 1:0] rid;
  logic [DATA_BITS - 1:0] rdata;
  resp_type_t             rresp;
  logic                   rlast;
  logic                   rvalid;
  logic                   rready;

  clocking master_cb @(posedge aclk);
    output awid, awaddr, awlen, awsize, awburst;
    output awlock, awcache, awprot, awvalid; input awready;
    output wid, wdata, wstrb, wlast, wvalid; input wready;
    input  bid, bresp, bvalid; output bready;
    output arid, araddr, arlen, arsize, arburst;
    output arlock, arcache, arprot, arvalid; input arready;
    input  rid, rdata, rresp, rlast, rvalid; output rready;
  endclocking

  clocking slave_cb @(posedge aclk);
    input  awid, awaddr, awlen, awsize, awburst;
    input  awlock, awcache, awprot, awvalid; output awready;
    input  wid, wdata, wstrb, wlast, wvalid; output wready;
    output bid, bresp, bvalid; input bready;
    input  arid, araddr, arlen, arsize, arburst;
    input  arlock, arcache, arprot, arvalid; output arready;
    output rid, rdata, rresp, rlast, rvalid; input rready;
  endclocking

  modport master (
    clocking master_cb, input areset_n,
    import master_start, master_reset, master_clear, master_ticks,
    import master_waddr, master_wdata, master_wresp, master_raddr, master_rdata
  );
  modport slave (
    clocking slave_cb, input areset_n,
    import slave_start, slave_reset, slave_clear, slave_ticks,
    import slave_waddr, slave_wdata, slave_wresp, slave_raddr, slave_rdata
  );

  task master_start ();
    master_clear();
    fork
      forever begin
        master_reset();
      end
    join_none
  endtask

  task master_reset ();
    wait (areset_n == 1'b0);
    master_clear();
    wait (areset_n == 1'b1);
  endtask

  task master_clear ();
    master_cb.awid    <= '0;
    master_cb.awaddr  <= '0;
    master_cb.awlen   <= '0;
    master_cb.awsize  <= '0;
    master_cb.awburst <= FIXED;
    master_cb.awlock  <= NORMAL;
    master_cb.awcache <= cache_attr_t'('0);
    master_cb.awprot  <= prot_attr_t'('0);
    master_cb.awvalid <= 1'b0;
    master_cb.wid     <= '0;
    master_cb.wdata   <= '0;
    master_cb.wstrb   <= '0;
    master_cb.wlast   <= 1'b0;
    master_cb.wvalid  <= 1'b0;
    master_cb.bready  <= 1'b0;

    master_cb.arid    <= '0;
    master_cb.araddr  <= '0;
    master_cb.arlen   <= '0;
    master_cb.arsize  <= '0;
    master_cb.arburst <= FIXED;
    master_cb.arlock  <= NORMAL;
    master_cb.arcache <= cache_attr_t'('0);
    master_cb.arprot  <= prot_attr_t'('0);
    master_cb.arvalid <= 1'b0;
    master_cb.rready  <= 1'b0;

    @(master_cb);
  endtask

  task master_ticks (input int tick);
    repeat (tick) @(master_cb);
  endtask

  task master_waddr (input tx_t tx);
    master_cb.awid    <= tx.txid;
    master_cb.awaddr  <= tx.addr.addr;
    master_cb.awlen   <= tx.addr.len;
    master_cb.awsize  <= tx.addr.size;
    master_cb.awburst <= tx.addr.burst;
    master_cb.awlock  <= tx.addr.lock;
    master_cb.awcache <= tx.addr.cache;
    master_cb.awprot  <= tx.addr.prot;
    master_cb.awvalid <= 1'b1;
    @(master_cb);

    wait (master_cb.awready == 1'b1);
    master_cb.awid    <= '0;
    master_cb.awaddr  <= '0;
    master_cb.awlen   <= '0;
    master_cb.awsize  <= '0;
    master_cb.awburst <= FIXED;
    master_cb.awlock  <= NORMAL;
    master_cb.awcache <= cache_attr_t'('0);
    master_cb.awprot  <= prot_attr_t'('0);
    master_cb.awvalid <= 1'b0;
  endtask

  task master_wdata (input tx_t tx, input int i);
    master_cb.wid    <= tx.txid;
    master_cb.wdata  <= tx.data[i].data;
    master_cb.wstrb  <= tx.data[i].strb;
    master_cb.wlast  <= (i == tx.addr.len);
    master_cb.wvalid <= 1'b1;
    @(master_cb);

    wait (master_cb.wready == 1'b1);
    master_cb.wid    <= '0;
    master_cb.wdata  <= '0;
    master_cb.wstrb  <= '0;
    master_cb.wlast  <= 1'b0;
    master_cb.wvalid <= 1'b0;
  endtask

  task master_wresp (output tx_t tx);
    master_cb.bready <= 1'b1;
    @(master_cb);

    wait (master_cb.bvalid == 1'b1);
    tx = new;
    tx.mode = tx_t::RESP;
    tx.txid = master_cb.bid;
    tx.resp = master_cb.bresp;
    master_cb.bready <= 1'b0;
  endtask

  task master_raddr (input tx_t tx);
    master_cb.arid    <= tx.txid;
    master_cb.araddr  <= tx.addr.addr;
    master_cb.arlen   <= tx.addr.len;
    master_cb.arsize  <= tx.addr.size;
    master_cb.arburst <= tx.addr.burst;
    master_cb.arlock  <= tx.addr.lock;
    master_cb.arcache <= tx.addr.cache;
    master_cb.arprot  <= tx.addr.prot;
    master_cb.arvalid <= 1'b1;
    @(master_cb);

    wait (master_cb.arready == 1'b1);
    master_cb.arid    <= '0;
    master_cb.araddr  <= '0;
    master_cb.arlen   <= '0;
    master_cb.arsize  <= '0;
    master_cb.arburst <= FIXED;
    master_cb.arlock  <= NORMAL;
    master_cb.arcache <= cache_attr_t'('0);
    master_cb.arprot  <= prot_attr_t'('0);
    master_cb.arvalid <= 1'b0;
  endtask

  task master_rdata (output tx_t tx);
    master_cb.rready <= 1'b1;
    @(master_cb);

    wait (master_cb.rvalid == 1'b1);
    tx = new;
    tx.mode         = tx_t::DATA;
    tx.txid         = master_cb.rid;
    tx.data[0].data = master_cb.rdata;
    tx.data[0].resp = master_cb.rresp;
    tx.data[0].last = master_cb.rlast;
    master_cb.rready <= 1'b0;
  endtask

  task slave_start ();
    slave_clear();
    fork
      forever begin
        slave_reset();
      end
    join_none
  endtask

  task slave_reset ();
    wait (areset_n == 1'b0);
    slave_clear();
    wait (areset_n == 1'b1);
  endtask

  task slave_clear ();
    slave_cb.awready <= '0;
    slave_cb.wready  <= '0;
    slave_cb.bid     <= '0;
    slave_cb.bresp   <= OKAY;
    slave_cb.bvalid  <= 1'b0;

    slave_cb.arready <= 1'b0;
    slave_cb.rid     <= '0;
    slave_cb.rdata   <= '0;
    slave_cb.rresp   <= OKAY;
    slave_cb.rlast   <= 1'b0;
    slave_cb.rvalid  <= 1'b0;

    @(slave_cb);
  endtask

  task slave_ticks (input int tick);
    repeat (tick) @(slave_cb);
  endtask

  task slave_waddr (output tx_t tx);
    slave_cb.awready <= 1'b1;
    @(slave_cb);

    wait (slave_cb.awvalid == 1'b1);
    tx = new;
    tx.mode       = tx_t::WRITE;
    tx.txid       = slave_cb.awid;
    tx.addr.addr  = slave_cb.awaddr;
    tx.addr.len   = slave_cb.awlen;
    tx.addr.size  = slave_cb.awsize;
    tx.addr.burst = slave_cb.awburst;
    tx.addr.lock  = slave_cb.awlock;
    tx.addr.cache = slave_cb.awcache;
    tx.addr.prot  = slave_cb.awprot;
    slave_cb.awready <= 1'b0;
  endtask

  task slave_wdata (output tx_t tx);
    slave_cb.wready <= 1'b1;
    @(slave_cb);

    wait (slave_cb.wvalid == 1'b1);
    tx = new;
    tx.mode         = tx_t::DATA;
    tx.txid         = slave_cb.wid;
    tx.data[0].data = slave_cb.wdata;
    tx.data[0].strb = slave_cb.wstrb;
    tx.data[0].last = slave_cb.wlast;
    slave_cb.wready <= 1'b0;
  endtask

  task slave_wresp (input tx_t tx);
    slave_cb.bid    <= tx.txid;
    slave_cb.bresp  <= OKAY;
    slave_cb.bvalid <= 1'b1;
    @(slave_cb);

    wait (slave_cb.bready == 1'b1);
    slave_cb.bid    <= '0;
    slave_cb.bresp  <= OKAY;
    slave_cb.bvalid <= 1'b0;
  endtask

  task slave_raddr (output tx_t tx);
    slave_cb.arready <= 1'b1;
    @(slave_cb);

    wait (slave_cb.arvalid == 1'b1);
    tx = new;
    tx.mode       = tx_t::READ;
    tx.txid       = slave_cb.arid;
    tx.addr.addr  = slave_cb.araddr;
    tx.addr.len   = slave_cb.arlen;
    tx.addr.size  = slave_cb.arsize;
    tx.addr.burst = slave_cb.arburst;
    tx.addr.lock  = slave_cb.arlock;
    tx.addr.cache = slave_cb.arcache;
    tx.addr.prot  = slave_cb.arprot;
    slave_cb.arready <= 1'b0;
  endtask

  task slave_rdata (input tx_t tx, input int i);
    slave_cb.rid    <= tx.txid;
    slave_cb.rdata  <= tx.data[i].data;
    slave_cb.rresp  <= OKAY;
    slave_cb.rlast  <= (i == tx.addr.len);
    slave_cb.rvalid <= 1'b1;
    @(slave_cb);

    wait (slave_cb.rready == 1'b1);
    slave_cb.rid    <= '0;
    slave_cb.rdata  <= '0;
    slave_cb.rresp  <= OKAY;
    slave_cb.rlast  <= 1'b0;
    slave_cb.rvalid <= 1'b0;
  endtask

endinterface
