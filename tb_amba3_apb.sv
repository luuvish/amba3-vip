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
    Descriptions : testbench for amba 3 apb 1.0

==============================================================================*/

`timescale 1ns/10ps

module tb_amba3_apb;

  import pkg_amba3::*;

  localparam integer PCLK_PERIOD = 10; // 100Mhz -> 10ns
  localparam integer ADDR_SIZE = 32, DATA_SIZE = 32;
  localparam integer DATA_BASE = $clog2(DATA_SIZE / 8);

  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  logic pclk;
  logic preset_n;

  amba3_apb_if #(ADDR_SIZE, DATA_SIZE) apb (pclk, preset_n);
  amba3_apb_master_t #(ADDR_SIZE, DATA_SIZE) master = new (apb);
  amba3_apb_slave_t #(ADDR_SIZE, DATA_SIZE) slave = new (apb);

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
    static int count = 0;
    void'($value$plusargs("unittest=%d", count));

    if ($test$plusargs("waveform")) begin
      $shm_open("waveform");
      $shm_probe("ars");
    end

    master.start();
    slave.start();
    master.ticks(100);

    if (count > 0)
      unit_test(count);
    else
      example();

    master.ticks(100);
    $finish;
  end

  task example ();
    data_t data;

    if ($test$plusargs("verbose")) begin
      $display("apb example test start");
    end

    master.write('h0800, 'h00040000);
    master.ticks(random_delay());
    master.write('h0040, 'h80003333);
    master.ticks(random_delay());
    master.write('h0084, 'h04400011);
    master.ticks(random_delay());
    master.write('h0140, 'h0000001C);
    master.ticks(random_delay());

    master.read('h0040, data); assert(data == 'h80003333);
    master.ticks(random_delay());
    master.read('h0140, data); assert(data == 'h0000001C);
    master.ticks(random_delay());
    master.read('h0800, data); assert(data == 'h00040000);
    master.ticks(random_delay());
    master.read('h0084, data); assert(data == 'h04400011);
    master.ticks(random_delay());

    master.write('h0040, 'h12345678);
    master.write('h0084, 'h40506070);
    master.write('h0018, 'h22446688);
    master.read('h0018, data); assert(data == 'h22446688);
    master.read('h0040, data); assert(data == 'h12345678);
    master.read('h0084, data); assert(data == 'h40506070);

    if ($test$plusargs("verbose")) begin
      $display("apb example test done");
    end
  endtask

  task unit_test (int count);
    data_t mems [addr_t[ADDR_SIZE - 1:DATA_BASE]];
    addr_t waddr_q [$];

    addr_t addr;
    data_t data;

    if ($test$plusargs("verbose")) begin
      $display("apb unittest start");
    end

    repeat (count) begin
      addr = $urandom_range(0, 'hFFFFFFFF) * (DATA_SIZE / 8);
      data = $urandom_range(0, 'hFFFFFFFF);
      waddr_q.push_back(addr);

      master.write(addr, data);
      master.ticks(random_delay());

      mems[addr[ADDR_SIZE - 1:DATA_BASE]] = data;
    end

    waddr_q.shuffle();

    foreach (waddr_q [i]) begin
      addr = waddr_q[i];

      master.read(addr, data);
      master.ticks(random_delay());

      assert(mems[addr[ADDR_SIZE - 1:DATA_BASE]] == data);
    end

    if ($test$plusargs("verbose")) begin
      $display("apb unittest %0d done", count);
    end
  endtask

  function automatic int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, 10);
  endfunction

endmodule
