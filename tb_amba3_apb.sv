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

    fork
      master.start();
      slave.start();
    join_none
    repeat (100) @(posedge pclk);

    if (count > 0)
      unit_test(count);
    else
      example();

    repeat (100) @(posedge pclk);
    $finish;
  end

  task example ();
    logic [DATA_SIZE - 1:0] data;

    if ($test$plusargs("verbose")) begin
      $display("apb example test start");
    end

    master.write(32'h00000000, 32'h00000004);
    master.delay(random_delay());
    master.write(32'h00000004, 32'h00000008);
    master.delay(random_delay());
    master.write(32'h00000010, 32'h00000014);
    master.delay(random_delay());
    master.write(32'h00000018, 32'h0000001C);
    master.delay(random_delay());

    master.read(32'h00000000, data); assert(data == 32'h00000004);
    master.delay(random_delay());
    master.read(32'h00000004, data); assert(data == 32'h00000008);
    master.delay(random_delay());
    master.read(32'h00000010, data); assert(data == 32'h00000014);
    master.delay(random_delay());
    master.read(32'h00000018, data); assert(data == 32'h0000001C);
    master.delay(random_delay());

    master.write(32'h00000040, 32'h12345678);
    master.write(32'h00000080, 32'h40506070);
    master.write(32'h00000088, 32'h22446688);
    master.read(32'h00000088, data); assert(data == 32'h22446688);
    master.read(32'h00000040, data); assert(data == 32'h12345678);
    master.read(32'h00000080, data); assert(data == 32'h40506070);

    if ($test$plusargs("verbose")) begin
      $display("apb example test done");
    end
  endtask

  task unit_test (int count);
    logic [DATA_SIZE - 1:0] mems [logic [ADDR_SIZE - 1:2]];
    logic [ADDR_SIZE - 1:2] midx;
    logic [ADDR_SIZE - 1:0] addr;
    logic [DATA_SIZE - 1:0] data;

    if ($test$plusargs("verbose")) begin
      $display("apb unittest start");
    end

    fork
      master.start();
      slave.start();
    join_none
    repeat (100) @(posedge pclk);

    repeat (count) begin
      midx = $urandom_range(0, 32'h3FFFFFFF);
      addr = {midx, 2'b0};
      data = $urandom_range(0, 32'hFFFFFFFF);

      master.write(addr, data);
      //master.delay(random_delay());
      mems[midx] = data;
    end

    foreach (mems [midx]) begin
      addr = {midx, 2'b0};

      master.read(addr, data);
      //master.delay(random_delay());
      assert(mems[midx] == data);
    end

    if ($test$plusargs("verbose")) begin
      $display("apb unittest %0d done", count);
    end
  endtask

  function automatic int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, 10);
  endfunction

endmodule
