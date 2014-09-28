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
  
    File         : tb_amba3_axi.sv
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : testbench for amba 3 axi
  
==============================================================================*/

`timescale 1ns/10ps

module tb_amba3_axi;

  import pkg_amba3::*;

  localparam integer ACLK_PERIOD = 2; // 500Mhz -> 2ns
  localparam integer AXID_SIZE = 4, ADDR_SIZE = 32, DATA_SIZE = 128;

  typedef virtual amba3_axi_if #(AXID_SIZE, ADDR_SIZE, DATA_SIZE) axi_if;
  typedef amba3_axi_master_t #(AXID_SIZE, ADDR_SIZE, DATA_SIZE) axi_master_t;
  typedef amba3_axi_slave_t #(AXID_SIZE, ADDR_SIZE, DATA_SIZE) axi_slave_t;

  logic aclk;
  logic areset_n;

  amba3_axi_if #(AXID_SIZE, ADDR_SIZE, DATA_SIZE) axi (aclk, areset_n);

  initial begin
    aclk = 1'b0;
    forever aclk = #(ACLK_PERIOD/2) ~aclk;
  end

  initial begin
    areset_n = 1'b1;
    repeat (10) @(posedge aclk);
    areset_n = 1'b0;
    repeat (50) @(posedge aclk);
    areset_n = 1'b1;
  end

  initial begin
    if ($test$plusargs("waveform")) begin
      $shm_open("waveform");
      $shm_probe("ars");
    end

    run (axi);
    repeat (1000) @(posedge aclk);
    $finish;
  end

  task run (axi_if axi);
    static axi_master_t master = new (axi);
    static axi_slave_t slave = new (axi);
  endtask

endmodule
