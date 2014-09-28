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
  
    File         : pkg_amba3_axi_slave.svh
    Author(s)    : luuvish (github.com/luuvish)
    Modifier     : luuvish (luuvish@gmail.com)
    Descriptions : package for amba 3 axi slave
  
==============================================================================*/

class amba3_axi_slave_t
#(
  parameter integer AXID_SIZE = 4,
                    ADDR_SIZE = 32,
                    DATA_SIZE = 128
);

  typedef virtual amba3_axi_if #(AXID_SIZE, ADDR_SIZE, DATA_SIZE).slave axi_t;

  axi_t axi;

  function new (input axi_t axi);
    this.axi = axi;
  endfunction

  task write_addr (amba3_axi_tx_t tx);
  endtask

  task write_data (amba3_axi_tx_t tx);
  endtask

  task write_resp (amba3_axi_tx_t tx);
  endtask

  task read_addr (amba3_axi_tx_t tx);
  endtask

  task read_data (amba3_axi_tx_t tx);
  endtask

endclass
