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
  
    File         : pkg_amba3_apb_master.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 apb master
  
==============================================================================*/

class amba3_apb_master_t
#(
  parameter integer ADDR_SIZE = 32,
                    DATA_SIZE = 32,
                    MAX_DELAY = 10
);

  typedef virtual amba3_apb_if #(ADDR_SIZE, DATA_SIZE).master apb_t;
  apb_t apb;

  function new (apb_t apb);
    this.apb = apb;
  endfunction

  virtual task start ();
    apb.master_start();
  endtask

  virtual task reset ();
    apb.master_reset();
  endtask

  virtual task delay (int t);
    apb.master_delay(t);
  endtask

  virtual task write (
    input  logic [ADDR_SIZE - 1:0] addr,
    input  logic [DATA_SIZE - 1:0] data
  );

    int t = $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);

    apb.master_cb.paddr   <= addr;
    apb.master_cb.pwrite  <= 1'b1;
    apb.master_cb.psel    <= 1'b1;
    apb.master_cb.penable <= 1'b0;
    apb.master_cb.pwdata  <= data;
    repeat (t + 1) @(apb.master_cb);

    apb.master_cb.penable <= 1'b1;
    if (t > 0) @(apb.master_cb);
    wait (apb.master_cb.pready == 1'b1);

    apb.master_cb.paddr   <= 'b0;
    apb.master_cb.pwrite  <= 1'b0;
    apb.master_cb.psel    <= 1'b0;
    apb.master_cb.penable <= 1'b0;
    apb.master_cb.pwdata  <= 'b0;
  endtask

  virtual task read (
    input  logic [ADDR_SIZE - 1:0] addr,
    output logic [DATA_SIZE - 1:0] data
  );

    int t = $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);

    apb.master_cb.paddr   <= addr;
    apb.master_cb.pwrite  <= 1'b0;
    apb.master_cb.psel    <= 1'b1;
    apb.master_cb.penable <= 1'b0;
    apb.master_cb.pwdata  <= 'b0;
    repeat (t + 1) @(apb.master_cb);

    apb.master_cb.penable <= 1'b1;
    if (t > 0) @(apb.master_cb);
    wait (apb.master_cb.pready == 1'b1);

    data = apb.master_cb.prdata;
    apb.master_cb.paddr   <= 'b0;
    apb.master_cb.pwrite  <= 1'b0;
    apb.master_cb.psel    <= 1'b0;
    apb.master_cb.penable <= 1'b0;
    apb.master_cb.pwdata  <= 'b0;
  endtask

endclass
