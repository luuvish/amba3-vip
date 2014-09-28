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
    Author(s)    : luuvish (github.com/luuvish)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi interface
  
==============================================================================*/

interface amba3_axi_if (input logic aclk, input logic areset_n);

  import pkg_amba3::*;

  parameter integer AXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 128;

  localparam integer STRB_SIZE = DATA_SIZE / 8;

  // write address channel signals
  logic [AXID_SIZE - 1:0] awid;
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
  logic [AXID_SIZE - 1:0] wid;
  logic [DATA_SIZE - 1:0] wdata;
  logic [STRB_SIZE - 1:0] wstrb;
  logic                   wlast;
  logic                   wvalid;
  logic                   wready;

  // write response channel signals
  logic [AXID_SIZE - 1:0] bid;
  resp_type_e             bresp;
  logic                   bvalid;
  logic                   bready;

  // read address channel signals
  logic [AXID_SIZE - 1:0] arid;
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
  logic [AXID_SIZE - 1:0] rid;
  logic [DATA_SIZE - 1:0] rdata;
  resp_type_e             rresp;
  logic                   rlast;
  logic                   rvalid;
  logic                   rready;

  clocking master_wr_cb @(posedge aclk);
    output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot;
    output awvalid; input awready;
    output wid, wdata, wstrb, wlast, wvalid; input wready;
    input  bid, bresp, bvalid; output bready;
  endclocking

  clocking slave_wr_cb @(posedge aclk);
    input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot;
    input  awvalid; output awready;
    input  wid, wdata, wstrb, wlast, wvalid; output wready;
    output bid, bresp, bvalid; input bready;
  endclocking

  clocking master_rd_cb @(posedge aclk);
    output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot;
    output arvalid; input arready;
    input  rid, rdata, rresp, rlast, rvalid; output rready;
  endclocking

  clocking slave_rd_cb @(posedge aclk);
    input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot;
    input  arvalid; output arready;
    output rid, rdata, rresp, rlast, rvalid; input rready;
  endclocking

  modport master (clocking master_wr_cb, master_rd_cb, import master_reset);
  modport slave  (clocking slave_wr_cb, slave_rd_cb, import slave_reset);

  modport master_wr (clocking master_wr_cb);
  modport slave_wr  (clocking slave_wr_cb);
  modport master_rd (clocking master_rd_cb);
  modport slave_rd  (clocking slave_rd_cb);

  task master_reset ();
    master_wr_cb.awid    <= 'b0;
    master_wr_cb.awaddr  <= 'b0;
    master_wr_cb.awlen   <= 'b0;
    master_wr_cb.awsize  <= 'b0;
    master_wr_cb.awburst <= FIXED;
    master_wr_cb.awlock  <= NORMAL;
    master_wr_cb.awcache <= cache_attr_e'('b0);
    master_wr_cb.awprot  <= prot_attr_e'('b0);
    master_wr_cb.awvalid <= 1'b0;
    master_wr_cb.wid     <= 'b0;
    master_wr_cb.wdata   <= 'b0;
    master_wr_cb.wstrb   <= 'b0;
    master_wr_cb.wlast   <= 1'b0;
    master_wr_cb.wvalid  <= 1'b0;
    master_wr_cb.bready  <= 1'b0;

    master_rd_cb.arid    <= 'b0;
    master_rd_cb.araddr  <= 'b0;
    master_rd_cb.arlen   <= 'b0;
    master_rd_cb.arsize  <= 'b0;
    master_rd_cb.arburst <= FIXED;
    master_rd_cb.arlock  <= NORMAL;
    master_rd_cb.arcache <= cache_attr_e'('b0);
    master_rd_cb.arprot  <= prot_attr_e'('b0);
    master_rd_cb.arvalid <= 1'b0;
    master_rd_cb.rready  <= 1'b0;
  endtask

  task slave_reset ();
    slave_wr_cb.awready  <= 1'b0;
    slave_wr_cb.wready   <= 1'b0;
    slave_wr_cb.bid      <= 'b0;
    slave_wr_cb.bresp    <= OKAY;
    slave_wr_cb.bvalid   <= 1'b0;

    slave_rd_cb.arready  <= 1'b0;
    slave_rd_cb.rid      <= 'b0;
    slave_rd_cb.rdata    <= 'b0;
    slave_rd_cb.rresp    <= OKAY;
    slave_rd_cb.rlast    <= 1'b0;
    slave_rd_cb.rvalid   <= 1'b0;
  endtask

endinterface
