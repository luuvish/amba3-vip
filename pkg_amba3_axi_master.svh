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
  parameter integer AXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 128
);

  typedef virtual amba3_axi_if #(AXID_SIZE, ADDR_SIZE, DATA_SIZE).master axi_t;
  typedef amba3_axi_tx_t #(AXID_SIZE, ADDR_SIZE, DATA_SIZE) tx_t;
  axi_t axi;

  function new (input axi_t axi);
    this.axi = axi;
  endfunction

  virtual task write_addr (tx_t tx);
    @(axi.master_wr_cb);
    axi.master_wr_cb.awid    <= tx.id;
    axi.master_wr_cb.awaddr  <= tx.addr_channel.addr;
    axi.master_wr_cb.awlen   <= tx.addr_channel.len;
    axi.master_wr_cb.awsize  <= tx.addr_channel.size;
    axi.master_wr_cb.awburst <= tx.addr_channel.burst;
    axi.master_wr_cb.awlock  <= tx.addr_channel.lock;
    axi.master_wr_cb.awcache <= tx.addr_channel.cache;
    axi.master_wr_cb.awprot  <= tx.addr_channel.prot;
    axi.master_wr_cb.awvalid <= 1'b1;
    wait (axi.master_wr_cb.awready == 1'b1);
    axi.master_wr_cb.awvalid <= 1'b0;
  endtask

  virtual task write_data (tx_t tx);
    foreach (tx.data_channel [i]) begin
      @(axi.master_wr_cb);
      axi.master_wr_cb.wid    <= tx.id;
      axi.master_wr_cb.wdata  <= tx.data_channel[i].data;
      axi.master_wr_cb.wstrb  <= tx.data_channel[i].strb;
      axi.master_wr_cb.wlast  <= (i == tx.addr_channel.len);
      axi.master_wr_cb.wvalid <= 1'b1;
      wait (axi.master_wr_cb.wready == 1'b1);
    end
    axi.master_wr_cb.wvalid <= 1'b0;
  endtask

  virtual task write_resp (tx_t tx);
    foreach (tx.data_channel [i]) begin
      while (axi.master_wr_cb.bvalid != 1'b1) begin
        @(axi.master_wr_cb);
        //axi.master_wr_cb.bid;
        //axi.master_wr_cb.bresp;
        //axi.master_wr_cb.bvalid;
        axi.master_wr_cb.bready <= 1'b1;
      end
    end

    @(axi.master_wr_cb);
    axi.master_wr_cb.bready <= 1'b0;
  endtask

  virtual task read_addr (tx_t tx);
    @(axi.master_rd_cb);
    axi.master_rd_cb.arid    <= tx.id;
    axi.master_rd_cb.araddr  <= tx.addr_channel.addr;
    axi.master_rd_cb.arlen   <= tx.addr_channel.len;
    axi.master_rd_cb.arsize  <= tx.addr_channel.size;
    axi.master_rd_cb.arburst <= tx.addr_channel.burst;
    axi.master_rd_cb.arlock  <= tx.addr_channel.lock;
    axi.master_rd_cb.arcache <= tx.addr_channel.cache;
    axi.master_rd_cb.arprot  <= tx.addr_channel.prot;
    axi.master_rd_cb.arvalid <= 1'b1;
    wait (axi.master_rd_cb.arready == 1'b1);

    @(axi.master_rd_cb);
    axi.master_rd_cb.arvalid <= 1'b0;
  endtask

  virtual task read_data (tx_t tx);
    while (axi.master_rd_cb.rvalid != 1'b1) begin
      @(axi.master_rd_cb);
      //axi.master_rd_cb.rid;
      //axi.master_rd_cb.rdata;
      //axi.master_rd_cb.rresp;
      //axi.master_rd_cb.rlast;
      //axi.master_rd_cb.rvalid;
      axi.master_rd_cb.rready <= 1'b1;
    end

    @(axi.master_rd_cb);
    axi.master_rd_cb.rready <= 1'b0;
  endtask

endclass
