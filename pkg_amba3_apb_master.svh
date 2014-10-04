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
    Descriptions : package for amba 3 apb 1.0 master

==============================================================================*/

class amba3_apb_master_t #(
  parameter integer ADDR_SIZE = 32,
                    DATA_SIZE = 32,
                    MAX_DELAY = 10
);

  typedef virtual amba3_apb_if #(ADDR_SIZE, DATA_SIZE).master apb_t;
  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

  protected apb_t apb;

  function new (input apb_t apb);
    this.apb = apb;
  endfunction

  virtual task start ();
    apb.master_start();
  endtask

  virtual task clear ();
    apb.master_clear();
  endtask

  virtual task ticks (input int tick);
    apb.master_ticks(tick);
  endtask

  virtual task write (input addr_t addr, input data_t data);
    ticks(random_delay());
    apb.master_write(addr, data);
  endtask

  virtual task read (input addr_t addr, output data_t data);
    ticks(random_delay());
    apb.master_read(addr, data);
  endtask

  virtual protected function int random_delay ();
    int zero_delay = MAX_DELAY == 0 || $urandom_range(0, 1);
    return zero_delay ? 0 : $urandom_range(1, MAX_DELAY);
  endfunction

endclass
