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
    Descriptions : package for amba 3 apb 1.0 interface

==============================================================================*/

interface amba3_apb_if #(
  parameter integer ADDR_SIZE = 32,
                    DATA_SIZE = 32
) (input logic pclk, input logic preset_n);

  import pkg_amba3::*;

  typedef logic [ADDR_SIZE - 1:0] addr_t;
  typedef logic [DATA_SIZE - 1:0] data_t;

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
    clocking master_cb, input preset_n,
    import master_start, master_reset,
    import master_clear, master_ticks, master_write, master_read
  );
  modport slave (
    clocking slave_cb, input preset_n,
    import slave_start, slave_reset, slave_listen,
    import slave_clear, slave_ticks, slave_write, slave_read
  );

  task master_start ();
    master_clear();
    fork
      forever begin
        master_reset();
      end
    join_none
  endtask

  task master_reset ();
    wait (preset_n == 1'b0);
    master_clear();
    wait (preset_n == 1'b1);
  endtask

  task master_clear ();
    master_cb.paddr   <= '0;
    master_cb.psel    <= '0;
    master_cb.penable <= '0;
    master_cb.pwrite  <= '0;
    master_cb.pwdata  <= '0;
    @(master_cb);
  endtask

  task master_ticks (input int tick);
    repeat (tick) @(master_cb);
  endtask

  task master_write (input addr_t addr, input data_t data);
    master_cb.paddr   <= addr;
    master_cb.pwrite  <= 1'b1;
    master_cb.psel    <= 1'b1;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= data;
    @(master_cb);

    master_cb.penable <= 1'b1;
    @(master_cb);

    wait (master_cb.pready == 1'b1);
    master_cb.paddr   <= '0;
    master_cb.pwrite  <= 1'b0;
    master_cb.psel    <= 1'b0;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= '0;
  endtask

  task master_read (input addr_t addr, output data_t data);
    master_cb.paddr   <= addr;
    master_cb.pwrite  <= 1'b0;
    master_cb.psel    <= 1'b1;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= '0;
    @(master_cb);

    master_cb.penable <= 1'b1;
    @(master_cb);

    wait (master_cb.pready == 1'b1);
    data = master_cb.prdata;
    master_cb.paddr   <= '0;
    master_cb.pwrite  <= 1'b0;
    master_cb.psel    <= 1'b0;
    master_cb.penable <= 1'b0;
    master_cb.pwdata  <= '0;
  endtask

  task slave_start ();
    slave_clear();
    fork
      forever begin
        slave_listen();
      end
    join_none
  endtask

  task slave_reset ();
    wait (preset_n == 1'b0);
    slave_clear();
    wait (preset_n == 1'b1);
  endtask

  task slave_listen ();
    fork : loop
      begin
        slave_reset();
        disable loop;
      end
      forever begin
        wait (slave_cb.psel == 1'b1 && slave_cb.penable == 1'b0);

        if (slave_cb.pwrite == 1'b1) begin
          slave_write(slave_cb.paddr, slave_cb.pwdata);
          slave_cb.pready <= 1'b1;
          slave_cb.prdata <= '0;
        end
        if (slave_cb.pwrite == 1'b0) begin
          data_t data;
          slave_read(slave_cb.paddr, data);
          slave_cb.pready <= 1'b1;
          slave_cb.prdata <= data;
        end
        @(slave_cb);

        wait (slave_cb.psel == 1'b1 && slave_cb.penable == 1'b1);
        slave_cb.pready <= 1'b0;
        slave_cb.prdata <= '0;
      end
    join_any
    disable fork;
  endtask

  task slave_clear ();
    slave_cb.pready <= 1'b0;
    slave_cb.prdata <= '0;
    @(slave_cb);
  endtask

  task slave_ticks (input int tick);
    repeat (tick) @(slave_cb);
  endtask

  task slave_write (input addr_t addr, input data_t data);
    // this task may be exported
  endtask

  task slave_read (input addr_t addr, output data_t data);
    // this task may be exported
  endtask

endinterface
