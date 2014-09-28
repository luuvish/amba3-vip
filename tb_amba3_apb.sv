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
  
    File         : tb_amba3_apb.sv
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : testbench for amba 3 apb
  
==============================================================================*/

`timescale 1ns/10ps

module tb_amba3_apb;

  import pkg_amba3::*;

  localparam integer PCLK_PERIOD = 10; // 100Mhz -> 10ns
  localparam integer ADDR_SIZE = 32, DATA_SIZE = 32;

  typedef virtual amba3_apb_if #(ADDR_SIZE, DATA_SIZE) apb_if;
  typedef amba3_apb_master_t #(ADDR_SIZE, DATA_SIZE) apb_master_t;
  typedef amba3_apb_slave_t #(ADDR_SIZE, DATA_SIZE) apb_slave_t;

  logic pclk;
  logic preset_n;

  amba3_apb_if #(ADDR_SIZE, DATA_SIZE) apb (pclk, preset_n);

  initial begin
    pclk = 1'b0;
    forever pclk = #(PCLK_PERIOD/2) ~pclk;
  end

  initial begin
    preset_n = 1'b1;
    repeat (10) @(posedge pclk);
    preset_n = 1'b0;
    repeat (50) @(posedge pclk);
    preset_n = 1'b1;
  end

  initial begin
    if ($test$plusargs("waveform")) begin
      $shm_open("waveform");
      $shm_probe("ars");
    end

    run (apb);
    repeat (1000) @(posedge pclk);
    $finish;
  end

  task run (apb_if apb);
    static apb_master_t master = new (apb);
    static apb_slave_t slave = new (apb);
  endtask

endmodule
