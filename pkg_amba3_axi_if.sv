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

interface amba3_axi_if (input logic aclk, input logic areset_n);

  import pkg_amba3::*;

  parameter integer TXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 32;

  localparam integer STRB_SIZE = DATA_SIZE / 8;

  typedef amba3_axi_tx_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) tx_t;
  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;
  typedef logic [STRB_SIZE - 1:0] strb_t;

  // write address channel signals
  logic [TXID_SIZE - 1:0] awid;
  logic [ADDR_SIZE - 1:0] awaddr;
  logic [            3:0] awlen;
  logic [            2:0] awsize;
  burst_type_e            awburst;
  lock_type_e             awlock;
  cache_attr_e            awcache;
  prot_attr_e             awprot;
  logic                   awvalid;
  logic                   awready;

  // write data channel signals
  logic [TXID_SIZE - 1:0] wid;
  logic [DATA_SIZE - 1:0] wdata;
  logic [STRB_SIZE - 1:0] wstrb;
  logic                   wlast;
  logic                   wvalid;
  logic                   wready;

  // write response channel signals
  logic [TXID_SIZE - 1:0] bid;
  resp_type_e             bresp;
  logic                   bvalid;
  logic                   bready;

  // read address channel signals
  logic [TXID_SIZE - 1:0] arid;
  logic [ADDR_SIZE - 1:0] araddr;
  logic [            3:0] arlen;
  logic [            2:0] arsize;
  burst_type_e            arburst;
  lock_type_e             arlock;
  cache_attr_e            arcache;
  prot_attr_e             arprot;
  logic                   arvalid;
  logic                   arready;

  // read data channel signals
  logic [TXID_SIZE - 1:0] rid;
  logic [DATA_SIZE - 1:0] rdata;
  resp_type_e             rresp;
  logic                   rlast;
  logic                   rvalid;
  logic                   rready;

  clocking master_cb @(posedge aclk);
    output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot;
    output awvalid; input awready;
    output wid, wdata, wstrb, wlast, wvalid; input wready;
    input  bid, bresp, bvalid; output bready;
    output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot;
    output arvalid; input arready;
    input  rid, rdata, rresp, rlast, rvalid; output rready;
  endclocking

  clocking slave_cb @(posedge aclk);
    input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot;
    input  awvalid; output awready;
    input  wid, wdata, wstrb, wlast, wvalid; output wready;
    output bid, bresp, bvalid; input bready;
    input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot;
    input  arvalid; output arready;
    output rid, rdata, rresp, rlast, rvalid; input rready;
  endclocking

  modport master (
    clocking master_cb, input areset_n,
    import master_start, master_ticks, master_reset, master_write, master_read
  );
  modport slave (
    clocking slave_cb, input areset_n,
    import slave_start, slave_ticks, slave_reset
  );

  task master_start ();
    master_reset();
    fork
      forever begin
        wait (areset_n == 1'b0);
        master_reset();
        wait (areset_n == 1'b1);
      end
    join_none
  endtask

  task master_ticks (input int tick);
    repeat (tick) @(master_cb);
  endtask

  task master_reset ();
    master_cb.awid    <= 'b0;
    master_cb.awaddr  <= 'b0;
    master_cb.awlen   <= 'b0;
    master_cb.awsize  <= 'b0;
    master_cb.awburst <= FIXED;
    master_cb.awlock  <= NORMAL;
    master_cb.awcache <= cache_attr_e'('b0);
    master_cb.awprot  <= prot_attr_e'('b0);
    master_cb.awvalid <= 1'b0;
    master_cb.wid     <= 'b0;
    master_cb.wdata   <= 'b0;
    master_cb.wstrb   <= 'b0;
    master_cb.wlast   <= 1'b0;
    master_cb.wvalid  <= 1'b0;
    master_cb.bready  <= 1'b0;

    master_cb.arid    <= 'b0;
    master_cb.araddr  <= 'b0;
    master_cb.arlen   <= 'b0;
    master_cb.arsize  <= 'b0;
    master_cb.arburst <= FIXED;
    master_cb.arlock  <= NORMAL;
    master_cb.arcache <= cache_attr_e'('b0);
    master_cb.arprot  <= prot_attr_e'('b0);
    master_cb.arvalid <= 1'b0;
    master_cb.rready  <= 1'b0;

    @(master_cb);
  endtask

  task master_write (input tx_t tx);
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
    master_cb.awvalid <= 1'b0;
  endtask

  task master_read (input tx_t tx);
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
    master_cb.arvalid <= 1'b0;
  endtask

  task slave_start ();
    slave_reset();
    fork
      forever begin
        wait (areset_n == 1'b0);
        slave_reset();
        wait (areset_n == 1'b1);
      end
    join_none
  endtask

  task slave_ticks (input int tick);
    repeat (tick) @(slave_cb);
  endtask

  task slave_reset ();
    slave_cb.awready  <= 1'b0;
    slave_cb.wready   <= 1'b0;
    slave_cb.bid      <= 'b0;
    slave_cb.bresp    <= OKAY;
    slave_cb.bvalid   <= 1'b0;

    slave_cb.arready  <= 1'b0;
    slave_cb.rid      <= 'b0;
    slave_cb.rdata    <= 'b0;
    slave_cb.rresp    <= OKAY;
    slave_cb.rlast    <= 1'b0;
    slave_cb.rvalid   <= 1'b0;

    @(slave_cb);
  endtask

endinterface
