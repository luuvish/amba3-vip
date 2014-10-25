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
      forever report_write();
      forever report_read();
      forever check_hold();
    join_any
    disable fork;
  endtask

  virtual task clear ();
    apb.monitor_clear();
  endtask

  virtual protected task report_write ();
    wait (apb.monitor_cb.psel == 1'b1 && apb.monitor_cb.penable == 1'b1 &&
          apb.monitor_cb.pwrite == 1'b1 && apb.monitor_cb.pready == 1'b1);

    report($sformatf("apb write %x %x",
      apb.monitor_cb.paddr,
      apb.monitor_cb.pwdata
    ));
    @(apb.monitor_cb);
  endtask

  virtual protected task report_read ();
    wait (apb.monitor_cb.psel == 1'b1 && apb.monitor_cb.penable == 1'b1 &&
          apb.monitor_cb.pwrite == 1'b0 && apb.monitor_cb.pready == 1'b1);

    report($sformatf("apb read %x %x",
      apb.monitor_cb.paddr,
      apb.monitor_cb.prdata
    ));
    @(apb.monitor_cb);
  endtask

  virtual protected task check_hold ();
    typedef struct {
      logic                   psel;
      logic                   penable;
      logic                   pwrite;
      logic [ADDR_BITS - 1:0] paddr;
      logic [DATA_BITS - 1:0] pwdata;
      logic [DATA_BITS - 1:0] prdata;
      logic                   pready;
    } hold_t;

    static hold_t hold = '{default: '0};

    hold_t now = '{
      psel   : apb.monitor_cb.psel,
      penable: apb.monitor_cb.penable,
      pwrite : apb.monitor_cb.pwrite,
      paddr  : apb.monitor_cb.paddr,
      pwdata : apb.monitor_cb.pwdata,
      prdata : apb.monitor_cb.prdata,
      pready : apb.monitor_cb.pready
    };

    if (hold.psel == 1'b1 && now.psel == 1'b0) begin
      report($sformatf("apb check psel %x is changed before pready",
        now.psel
      ));
    end

    if (hold.psel == 1'b0) begin
      if (now.penable == 1'b1)
        report($sformatf("apb check penable %x is set first stage",
          now.penable
        ));
    end
    else begin
      if (hold.penable == 1'b1 && now.penable == 1'b0)
        report($sformatf("apb check penable %x is changed before pready",
          now.penable
        ));
    end

    if (hold.psel == 1'b1) begin
      if (hold.paddr != now.paddr)
        report($sformatf("apb check paddr %x is changed before pready",
          now.paddr
        ));
      if (hold.pwrite != now.pwrite)
        report($sformatf("apb check pwrite %0d is changed before pready",
          now.pwrite
        ));
      if (now.pwrite == 1'b1 && hold.pwdata != now.pwdata)
        report($sformatf("apb check pwdata %x is changed before pready",
          now.pwdata
        ));
    end

    if (now.psel == 1'b1 && now.penable == 1'b1 && now.pready == 1'b1)
      hold <= '{default: '0};
    else
      hold <= now;

    @(apb.monitor_cb);
  endtask

  virtual task report (input string text);
    string log = $sformatf("@%0dns %s", $time, text);

    if (file == -1)
      $display(log);
    else
      $fdisplay(file, log);
  endtask

endclass
