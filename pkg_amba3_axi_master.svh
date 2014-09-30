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
                    DATA_SIZE = 32,
                    MAX_DELAY = 10
);

  typedef virtual amba3_axi_if #(AXID_SIZE, ADDR_SIZE, DATA_SIZE).master axi_t;
  typedef amba3_axi_tx_t #(AXID_SIZE, ADDR_SIZE, DATA_SIZE) tx_t;
  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  axi_t axi;

  mailbox #(tx_t) waddr_q, wdata_q, wresp_q, raddr_q, rdata_q;

  function new (input axi_t axi);
    this.axi = axi;
    this.waddr_q = new;
    this.wdata_q = new;
    this.wresp_q = new;
    this.raddr_q = new;
    this.rdata_q = new;
  endfunction

  virtual task start ();
    fork
      axi.master_start();
      ready();
    join_none
  endtask

  virtual task ticks (input int tick);
    axi.master_ticks(tick);
  endtask

  virtual task reset ();
    axi.master_reset();
  endtask

  virtual task ready ();
    fork
      ready_waddr();
      ready_wdata();
      ready_wresp();
      ready_raddr();
      ready_rdata();
    join_none
  endtask

  virtual task write (input tx_t tx);
    waddr_q.put(tx);
    wdata_q.put(tx);
  endtask

  virtual task read (input tx_t tx);
    raddr_q.put(tx);
  endtask

  virtual task ready_waddr ();
    forever begin
      tx_t tx;
      waddr_q.get(tx);

      axi.master_cb.awid    <= tx.axid;
      axi.master_cb.awaddr  <= tx.addr.addr;
      axi.master_cb.awlen   <= tx.addr.len;
      axi.master_cb.awsize  <= tx.addr.size;
      axi.master_cb.awburst <= tx.addr.burst;
      axi.master_cb.awlock  <= tx.addr.lock;
      axi.master_cb.awcache <= tx.addr.cache;
      axi.master_cb.awprot  <= tx.addr.prot;
      axi.master_cb.awvalid <= 1'b1;
      @(axi.master_cb);

      wait (axi.master_cb.awready == 1'b1);

      axi.master_cb.awvalid <= 1'b0;
    end
  endtask

  virtual task ready_wdata ();
    forever begin
      tx_t tx;
      wdata_q.get(tx);

      foreach (tx.data [i]) begin
        axi.master_cb.wid    <= tx.axid;
        axi.master_cb.wdata  <= tx.data[i].data;
        axi.master_cb.wstrb  <= tx.data[i].strb;
        axi.master_cb.wlast  <= (i == tx.addr.len);
        axi.master_cb.wvalid <= 1'b1;
        @(axi.master_cb);

        wait (axi.master_cb.wready == 1'b1);
      end

      axi.master_cb.wvalid <= 1'b0;
      wresp_q.put(tx);
    end
  endtask

  virtual task ready_wresp ();
    forever begin
      tx_t tx;
      wresp_q.get(tx);

      foreach (tx.data [i]) begin
        while (axi.master_cb.bvalid != 1'b1) begin
          @(axi.master_cb);
          //axi.master_cb.bid;
          //axi.master_cb.bresp;
          //axi.master_cb.bvalid;
          axi.master_cb.bready <= 1'b1;
        end
      end

      @(axi.master_cb);
      axi.master_cb.bready <= 1'b0;
    end
  endtask

  virtual task ready_raddr ();
    forever begin
      tx_t tx;
      raddr_q.get(tx);
  
      axi.master_cb.arid    <= tx.axid;
      axi.master_cb.araddr  <= tx.addr.addr;
      axi.master_cb.arlen   <= tx.addr.len;
      axi.master_cb.arsize  <= tx.addr.size;
      axi.master_cb.arburst <= tx.addr.burst;
      axi.master_cb.arlock  <= tx.addr.lock;
      axi.master_cb.arcache <= tx.addr.cache;
      axi.master_cb.arprot  <= tx.addr.prot;
      axi.master_cb.arvalid <= 1'b1;
      @(axi.master_cb);

      wait (axi.master_cb.arready == 1'b1);

      axi.master_cb.arvalid <= 1'b0;
      rdata_q.put(tx);
    end
  endtask

  virtual task ready_rdata ();
    forever begin
      tx_t tx;
      rdata_q.get(tx);

      foreach (tx.data [i]) begin
        axi.master_cb.rready <= 1'b1;
        @(axi.master_cb);

        wait (axi.master_cb.rvalid == 1'b1);

        //axi.master_cb.rid;
        //axi.master_cb.rdata;
        //axi.master_cb.rresp;
        //axi.master_cb.rlast;
        //axi.master_cb.rvalid;
      end

      axi.master_cb.rready <= 1'b0;
    end
  endtask

  virtual function int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
