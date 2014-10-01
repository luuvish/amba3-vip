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
  localparam integer TXID_SIZE = 4, ADDR_SIZE = 32, DATA_SIZE = 128;

  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  logic aclk;
  logic areset_n;

  amba3_axi_if #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) axi (aclk, areset_n);
  amba3_axi_master_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) master = new (axi);
  amba3_axi_slave_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) slave = new (axi);

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
    static int count = 0;
    void'($value$plusargs("unittest=%d", count));

    if ($test$plusargs("waveform")) begin
      $shm_open("waveform");
      $shm_probe("ars");
    end

    master.start();
    slave.start();
    repeat (100) @(posedge aclk);

    if (count > 0)
      unit_test(count);
    else
      example();

    repeat (100) @(posedge aclk);
    $finish;
  end

  task example ();
    amba3_axi_tx_fixed_t #(TXID_SIZE, ADDR_SIZE, DATA_SIZE) tx;

    data_t data [4];

    if ($test$plusargs("verbose")) begin
      $display("axi example test start");
    end

    tx = new ('h0010, '{'h11, 'h12, 'h13, 'h14});
    master.write(tx);
    master.ticks(random_delay());
    tx = new ('h0020, '{'h21, 'h22, 'h23, 'h24});
    master.write(tx);
    tx = new ('h0030, '{'h31, 'h32, 'h33, 'h34});
    master.write(tx);
    tx = new ('h0040, '{'h41, 'h42, 'h43, 'h44});
    master.write(tx);
    master.ticks(random_delay());

    tx = new ('h0010, , 4);
    master.read(tx);
    master.ticks(random_delay());
    tx = new ('h0020, , 4);
    master.read(tx);
    tx = new ('h0030, , 4);
    master.read(tx);
    tx = new ('h0040, , 4);
    master.read(tx);
    master.ticks(random_delay());

    repeat (3000) @(posedge aclk);

    if ($test$plusargs("verbose")) begin
      $display("axi example test done");
    end
  endtask

  task unit_test (int count);

    if ($test$plusargs("verbose")) begin
      $display("axi unittest start");
    end

    repeat (count) begin
    end

    if ($test$plusargs("verbose")) begin
      $display("axi unittest %0d done", count);
    end
  endtask

  function automatic int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, 10);
  endfunction

endmodule
