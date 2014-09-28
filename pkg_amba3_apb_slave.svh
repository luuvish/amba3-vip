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
  
    File         : pkg_amba3_apb_slave.svh
    Author(s)    : luuvish (github.com/luuvish)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 apb slave
  
==============================================================================*/

class amba3_apb_slave_t
#(
  parameter integer ADDR_SIZE = 32,
                    DATA_SIZE = 32
);

  localparam integer DELAY = 1;

  typedef virtual amba3_apb_if #(ADDR_SIZE, DATA_SIZE).slave apb_t;
  apb_t apb;

  function new (input apb_t apb);
    this.apb = apb;
  endfunction

  virtual task reset ();
    apb.slave_reset();
  endtask

  virtual task ready ();
    logic [ADDR_SIZE - 1:0] addr;
    logic [DATA_SIZE - 1:0] data;

    apb.slave_cb.pready <= 1'b0;
    wait (apb.slave_cb.psel == 1'b1 && apb.slave_cb.penable == 1'b0);

    repeat (DELAY) @(apb.slave_cb);
    apb.slave_cb.pready <= 1'b1;
    if (apb.slave_cb.pwrite == 1'b1) begin
      addr = apb.slave_cb.paddr;
      data = apb.slave_cb.pwdata;
      write(addr, data);
    end
    if (apb.slave_cb.pwrite == 1'b0) begin
      read(addr, data);
      apb.slave_cb.prdata <= data;
    end
    wait (apb.slave_cb.psel == 1'b1 && apb.slave_cb.penable == 1'b1);
  endtask

  virtual task write (
    input  logic [ADDR_SIZE - 1:0] addr,
    input  logic [DATA_SIZE - 1:0] data
  );
    apb.slave_write(addr, data);
  endtask

  virtual task read (
    input  logic [ADDR_SIZE - 1:0] addr,
    output logic [DATA_SIZE - 1:0] data
  );
    apb.slave_read(addr, data);
  endtask

endclass
