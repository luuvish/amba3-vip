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

    File         : pkg_amba3_apb_monitor.svh
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 apb 1.0 monitor

==============================================================================*/

class amba3_apb_monitor_t #(
  parameter integer ADDR_BITS = 32,
                    DATA_BITS = 32
);

  typedef virtual amba3_apb_if #(ADDR_BITS, DATA_BITS).monitor apb_t;
  typedef logic [ADDR_BITS - 1:0] addr_t;
  typedef logic [DATA_BITS - 1:0] data_t;

  protected apb_t apb;
  protected integer file;

  function new (input apb_t apb, string filename = "");
    this.apb = apb;
    this.file = -1;
    if (filename != "") begin
      this.file = $fopen(filename, "w");
    end
  endfunction

  virtual task start ();
    clear();
    fork
      forever begin
        listen();
      end
    join_none
  endtask

  virtual task listen ();
    fork : loop
      begin
        apb.monitor_reset();
        disable loop;
      end
      forever begin
        wait (apb.monitor_cb.psel == 1'b1 && apb.monitor_cb.penable == 1'b1 &&
              apb.monitor_cb.pready == 1'b1);
        if (apb.monitor_cb.pwrite == 1'b1) begin
          write(apb.monitor_cb.paddr, apb.monitor_cb.pwdata);
        end
        if (apb.monitor_cb.pwrite == 1'b0) begin
          read(apb.monitor_cb.paddr, apb.monitor_cb.prdata);
        end
        @(apb.monitor_cb);
      end
    join_any
    disable fork;
  endtask

  virtual task clear ();
    apb.monitor_clear();
  endtask

  virtual protected task write (input addr_t addr, input data_t data);
    string log = $sformatf("@%0dns apb write %x %x", $time, addr, data);
    if (file == -1) $display(log); else $fdisplay(file, log);
  endtask

  virtual protected task read (input addr_t addr, input data_t data);
    string log = $sformatf("@%0dns apb read %x %x", $time, addr, data);
    if (file == -1) $display(log); else $fdisplay(file, log);
  endtask

endclass
