AMBA3-VIP
=========

AMBA3 APB/AXI SystemVerilog model and verification

## Features
  * AMBA3 APB Protocol v1.0
    1. parameterize ADDR/DATA bits
    2. interface, master, slave and monitor modeling
    3. randomize pready dely
  * AMBA3 AXI Protocol v1.0
    1. parameterize ADDR/DATA/ID bits
    2. interface, master, slave and monitor modeling
    3. randomize ready/valid/response
    4. paremeterize transaction queue
    5. non-blocking/blocking response

## Requirement
  * Python >= 2.7
  * Cadence Incisive Unified Simulator >= 10.2

## Usage

```bash
make      # compile & eleboration design/testbench
./test.py # run unit test or test example
```

```bash
./test.py -h

usage: test.py [-h] [-v] [-m] [-w] [-u UNITTEST]

amba3 test

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         verbose
  -m, --monitor         monitor
  -w, --waveform        waveform
  -u UNITTEST, --unittest UNITTEST
                        unit test count
```

### API example

APB interface instantiation

```system-verilog
const int ADDR_BITS = 32, DATA_BITS = 32;
logic pclk, preset_n; // clock, reset signals
amba3_apb_if #(ADDR_BITS, DATA_BITS) apb (pclk, preset_n);
```

APB master/slave instantiation

```system-verilog
amba3_apb_master_t #(ADDR_BITS, DATA_BITS) master = new (apb);
amba3_apb_slave_t #(ADDR_BITS, DATA_BITS) slave = new (apb);
```

APB master/slave run listen task and reset handler

```system-verilog
initial begin
  ...
  master.start();
  slave.start();
end
```

APB read/write

```system-verilog
initial begin
  ...
  logic [DATA_BITS - 1:0] mems [logic [ADDR_BITS - 1:2]];
  logic [DATA_BITS - 1:0] data;

  master.write('h0800, 'h00040000);
  mems['h0800 / 4] = 'h00040000;

  master.write('h0040, 'h80003333);
  mems['h0040 / 4] = 'h80003333;
  
  master.read('h0800, data);
  assert (mems['h0800 / 4] == data); // this will be 'h0004000

  master.read('h0040, data);
  assert (mems['h0040 / 4] == data); // this will be 'h8000333
end
```

### AXI example

AXI interface instantiation

```system-verilog
const int TXID_BITS = 4, ADDR_BITS = 32, DATA_BITS = 128;
logic aclk, areset_n; // clock, reset signals
amba3_axi_if #(TXID_BITS, ADDR_BITS, DATA_BITS) axi (aclk, areset_n);
```

AXI master/slave instantiation

```system-verilog
amba3_axi_master_t #(TXID_BITS, ADDR_BITS, DATA_BITS) master = new (axi);
amba3_axi_slave_t #(TXID_BITS, ADDR_BITS, DATA_BITS) slave = new (axi);
```

AXI master/slave run listen task and reset handler

```system-verilog
initial begin
  ...
  master.start();
  slave.start();
end
```

Make transactions

```system-verilog
const int BEAT_BITS = 8;
amba3_axi_tx_fixed_t #(TXID_BITS, ADDR_BITS, DATA_BITS, BEAT_BITS) fixed;

fixed = new ('h0106, '{'h07, 'h15, 'h23, 'h31, 'h39});
// addr = 'h0100, strb = 16'h0040, data = 128'h0007_0000_0000_0000
// addr = 'h0100, strb = 16'h0040, data = 128'h0015_0000_0000_0000
// addr = 'h0100, strb = 16'h0040, data = 128'h0023_0000_0000_0000
// addr = 'h0100, strb = 16'h0040, data = 128'h0031_0000_0000_0000
// addr = 'h0100, strb = 16'h0040, data = 128'h0039_0000_0000_0000
```

```system-verilog
const int BEAT_BITS = 32;
amba3_axi_tx_incr_t #(TXID_BITS, ADDR_BITS, DATA_BITS, BEAT_BITS) incr;

incr = new ('h0104, '{'h4739, 'h7163, 'hA395, 'h1507});
// addr = 'h0100, strb = 16'h00F0, data = 128'h0000_0000_0000_0000_0000_4739_0000_0000
// addr = 'h0100, strb = 16'h0F00, data = 128'h0000_0000_0000_7163_0000_0000_0000_0000
// addr = 'h0100, strb = 16'hF000, data = 128'h0000_A395_0000_0000_0000_0000_0000_0000
// addr = 'h0110, strb = 16'h000F, data = 128'h0000_0000_0000_0000_0000_0000_0000_1507
```

```system-verilog
const int BEAT_BITS = 32;
amba3_axi_tx_fixed_t #(TXID_BITS, ADDR_BITS, DATA_BITS, BEAT_BITS) wrap;

wrap = new ('h0704, '{'h2211, 'h7766, 'h5432, 'h7123});
// addr = 'h0700, strb = 16'h00F0, data = 128'h0000_0000_0000_0000_0000_2211_0000_0000
// addr = 'h0700, strb = 16'h0F00, data = 128'h0000_0000_0000_7766_0000_0000_0000_0000
// addr = 'h0700, strb = 16'hF000, data = 128'h0000_5432_0000_0000_0000_0000_0000_0000
// addr = 'h0700, strb = 16'h000F, data = 128'h0000_0000_0000_0000_0000_0000_0000_7123
```

AXI read/write

```system-verilog
initial begin
  ...
  logic [DATA_BITS - 1:0] mems [logic [ADDR_BITS - 1:4]];
  amba_3_axi_tx_incr_t #(TXID_BITS, ADDR_BITS, DATA_BITS, DATA_BITS) tx [2];

  tx[0] = new ('h0010, '{'h11, 'h12, 'h13, 'h14});
  master.write(tx[0]);
  mems['h0010 / 16] = 'h11;
  mems['h0020 / 16] = 'h12;
  mems['h0030 / 16] = 'h13;
  mems['h0040 / 16] = 'h14;

  tx[1] = new ('h0050, '{'h21, 'h22, 'h23, 'h24});
  master.write(tx[1], 1'b1); // to wait write response, set 1'b1
  mems['h0050 / 16] = 'h21;
  mems['h0060 / 16] = 'h22;
  mems['h0070 / 16] = 'h23;
  mems['h0080 / 16] = 'h24;

  tx[0] = new ('h0010, , 4); // make read transaction
  master.read(tx[0]);

  tx[1] = new ('h0050, , 4); // make read transaction
  master.read(tx[1], 1'b1); // to wait read response, set 1'b1

  for (int i = 0; i < 4; i++) begin
    assert (mems['h0010 / 16 + i] == tx[0].data[i].data);
    assert (mems['h0050 / 16 + i] == tx[1].data[i].data);
  end
end
```

## TODO
  * AMBA3 APB Protocol v1.0
    1. assertion and signal validation
    2. arbiter modeling
    3. PSLVERR support
  * AMBA3 AXI Protocol v1.0
    1. assertion and signal validation
    2. arbiter modeling
    3. AxLOCK support
    4. AxCACHE support
    5. AxPROT support
