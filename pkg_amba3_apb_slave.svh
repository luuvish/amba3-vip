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
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 apb slave
  
==============================================================================*/

class amba3_apb_slave_t
#(
  parameter integer ADDR_SIZE = 32,
                    DATA_SIZE = 32,
                    MAX_DELAY = 10
);

  typedef virtual amba3_apb_if #(ADDR_SIZE, DATA_SIZE).slave apb_t;
  apb_t apb;

  logic [DATA_SIZE - 1:0] mems [logic [ADDR_SIZE - 1:2]];

  function new (apb_t apb);
    this.apb = apb;
  endfunction

  virtual task start ();
    fork
      apb.slave_start();
      ready();
    join_none
  endtask

  virtual task ticks (int t);
    apb.slave_ticks(t);
  endtask

  virtual task reset ();
    apb.slave_reset();
  endtask

  virtual task ready ();
    forever begin
      wait (apb.slave_cb.psel == 1'b1 && apb.slave_cb.penable == 1'b0);

      ticks(random_delay());

      if (apb.slave_cb.pwrite == 1'b1) begin
        write(apb.slave_cb.paddr, apb.slave_cb.pwdata);
        apb.slave_cb.pready <= 1'b1;
      end
      if (apb.slave_cb.pwrite == 1'b0) begin
        logic [DATA_SIZE - 1:0] data;
        read(apb.slave_cb.paddr, data);
        apb.slave_cb.pready <= 1'b1;
        apb.slave_cb.prdata <= data;
      end
      @(apb.slave_cb);

      wait (apb.slave_cb.psel == 1'b1 && apb.slave_cb.penable == 1'b1);

      apb.slave_cb.pready <= 1'b0;
      apb.slave_cb.prdata <= 'b0;
    end
  endtask

  virtual task write (
    input  logic [ADDR_SIZE - 1:0] addr,
    input  logic [DATA_SIZE - 1:0] data
  );
    mems[addr[ADDR_SIZE - 1:2]] = data;
  endtask

  virtual task read (
    input  logic [ADDR_SIZE - 1:0] addr,
    output logic [DATA_SIZE - 1:0] data
  );
    data = mems[addr[ADDR_SIZE - 1:2]];
  endtask

  virtual function int random_delay ();
    return $urandom_range(0, 1) ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
