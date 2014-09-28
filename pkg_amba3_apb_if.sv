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
  
    File         : pkg_amba3_apb_if.sv
    Author(s)    : luuvish (github.com/luuvish/amba3-vip)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 apb interface
  
==============================================================================*/

interface amba3_apb_if (input logic pclk, input logic preset_n);

  import pkg_amba3::*;

  parameter integer ADDR_SIZE = 32,
                    DATA_SIZE = 32;

  logic [ADDR_SIZE - 1:0] paddr;
  logic                   psel;
  logic                   penable;
  logic                   pwrite;
  logic [DATA_SIZE - 1:0] pwdata;
  logic                   pready;
  logic [DATA_SIZE - 1:0] prdata;

  clocking master_cb @(posedge pclk);
    output paddr, psel, penable, pwrite, pwdata;
    input  pready, prdata;
  endclocking

  clocking slave_cb @(posedge pclk);
    input  paddr, psel, penable, pwrite, pwdata;
    output pready, prdata;
  endclocking

  modport master (
    clocking master_cb,
    import master_reset, master_write, master_read
  );
  modport slave (
    clocking slave_cb,
    import slave_reset, slave_write, slave_read
  );

  task master_reset ();
    @(master_cb);
    master_cb.paddr   <= 'b0;
    master_cb.psel    <= 1'b0;
    master_cb.penable <= 1'b0;
    master_cb.pwrite  <= 1'b0;
    master_cb.pwdata  <= 'b0;
  endtask

  task master_write (
    input  logic [ADDR_SIZE - 1:0] addr,
    input  logic [DATA_SIZE - 1:0] data
  );

    master_cb.paddr   <= addr;
    master_cb.pwrite  <= 1'b1;
    master_cb.psel    <= 1'b1;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= data;
    @(master_cb);
    master_cb.penable <= 1'b1;
    wait (master_cb.pready == 1'b1);

    @(master_cb);
    master_cb.paddr   <= 'b0;
    master_cb.pwrite  <= 1'b0;
    master_cb.psel    <= 1'b0;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= 'b0;
  endtask

  task master_read (
    input  logic [ADDR_SIZE - 1:0] addr,
    output logic [DATA_SIZE - 1:0] data
  );

    master_cb.paddr   <= addr;
    master_cb.pwrite  <= 1'b0;
    master_cb.psel    <= 1'b1;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= 'b0;
    @(master_cb);
    master_cb.penable <= 1'b1;
    wait (master_cb.pready == 1'b1);
    data = master_cb.prdata;

    @(master_cb);
    master_cb.paddr   <= 'b0;
    master_cb.pwrite  <= 1'b0;
    master_cb.psel    <= 1'b0;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= 'b0;
  endtask

  task slave_reset ();
    @(slave_cb);
    slave_cb.pready <= 1'b0;
    slave_cb.prdata <= 'b0;
  endtask

  task slave_write (
    input  logic [ADDR_SIZE - 1:0] addr,
    input  logic [DATA_SIZE - 1:0] data
  );
  endtask

  task slave_read (
    input  logic [ADDR_SIZE - 1:0] addr,
    output logic [DATA_SIZE - 1:0] data
  );
  endtask

endinterface
