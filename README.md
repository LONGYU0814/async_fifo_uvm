# Async FIFO UVM 验证项目

## 1. 项目简介

本项目使用 **SystemVerilog + UVM** 对一个参数化异步 FIFO（Asynchronous FIFO）进行完整验证。

DUT 具有独立的写时钟域和读时钟域，通过 **Gray Code 指针 + 两级同步器（2-FF Synchronizer）** 完成跨时钟域（CDC）指针同步。

项目从普通 SystemVerilog 自检 Testbench 逐步重构为完整 UVM 验证环境，并实现：

- Write / Read UVM Agent
- Sequence / Sequencer / Driver / Monitor
- Scoreboard Reference Model
- Functional Coverage（Covergroup）
- SystemVerilog Assertions（SVA）
- Assertion Coverage
- Code Coverage
- FULL / EMPTY 边界测试
- 非法读写测试
- Pointer Wrap-Around 测试
- Mid-test Reset Recovery 测试
- Makefile 自动化 Regression
- URG Coverage Merge
- Verdi FSDB 波形调试

---

## 2. DUT 主要功能

默认参数：

```text
DATA_WIDTH = 8
DEPTH      = 16
```

主要功能包括：

```text
独立 wr_clk / rd_clk
        ↓
Binary Pointer
        ↓
Gray Code Pointer
        ↓
2FF CDC Synchronizer
        ↓
FULL / EMPTY 判断
```

DUT 支持：

- 参数化数据宽度
- 参数化 FIFO 深度
- Binary Write / Read Pointer
- Gray Code Pointer
- 两级 Pointer Synchronizer
- Write-domain FULL 判断
- Read-domain EMPTY 判断
- Registered Read Data
- FULL 时禁止真正写入
- EMPTY 时禁止真正读取

---

## 3. UVM 验证架构

```text
                 WRITE SIDE

fifo_wr_sequence
       ↓
fifo_wr_sequencer
       ↓
fifo_wr_driver
       ↓
     DUT
       ↓
fifo_wr_monitor
       ↓
       ├────────→ Scoreboard
       │
       └────────→ Functional Coverage


                  READ SIDE

fifo_rd_sequence
       ↓
fifo_rd_sequencer
       ↓
fifo_rd_driver
       ↓
     DUT
       ↓
fifo_rd_monitor
       ↓
       ├────────→ Scoreboard
       │
       └────────→ Functional Coverage
```

Monitor 只报告 DUT **真正接受的 transaction**。

例如：

```text
wr_en = 1 && full = 0
→ successful write
→ Monitor发送transaction

wr_en = 1 && full = 1
→ illegal write attempt
→ DUT拒绝
→ Monitor不发送successful transaction
```

---

## 4. Scoreboard / Reference Model

Scoreboard 使用 SystemVerilog Queue 建立 FIFO Reference Model。

成功写操作：

```systemverilog
expected_q.push_back(data);
```

成功读操作：

```systemverilog
expected = expected_q.pop_front();
```

然后执行：

```text
Expected Data
      ↓
    Compare
      ↑
Actual rd_data
```

使用严格比较：

```systemverilog
!==
```

从而能够检测 `X / Z`。

Scoreboard 同时支持 Mid-test Reset。

当 DUT Reset 被拉低时：

```systemverilog
expected_q.delete();
```

保证 DUT 与 Reference Model 的状态保持一致。

---

## 5. Testcase

### fifo_test

普通 Write / Read 并发测试。

主要验证：

```text
正常写入
正常读取
异步读写
FIFO数据顺序
Scoreboard端到端比较
```

### fifo_full_test

FULL 边界测试。

流程：

```text
连续写 DEPTH 笔
      ↓
FIFO FULL
      ↓
开始读取
      ↓
FULL解除
      ↓
最终EMPTY
```

主要用于覆盖：

```text
full = 1
full : 0 → 1
full : 1 → 0
```

### fifo_illegal_test

非法边界操作测试。

验证：

```text
FULL时仍然assert wr_en
→ DUT不得真正write
→ write pointer必须保持稳定

EMPTY时仍然assert rd_en
→ DUT不得真正read
→ read pointer必须保持稳定
```

非法操作后继续进行正常 Write / Read，确认 FIFO 状态没有被破坏。

### fifo_wrap_test

Pointer Wrap-Around 测试。

连续执行多轮：

```text
Fill FIFO
   ↓
Drain FIFO
   ↓
Fill FIFO
   ↓
Drain FIFO
   ↓
...
```

使 Write / Read Pointer 多次跨越地址边界。

主要验证：

- Binary Pointer Wrap-Around
- Gray Pointer Wrap-Around
- CDC Pointer Synchronization
- 多次 Wrap 后 FIFO 数据顺序仍然正确
- Pointer 高位 Toggle Coverage

### fifo_reset_test

Mid-test Reset Recovery 测试。

流程：

```text
正常写入数据
      ↓
FIFO非空
      ↓
运行中assert reset
      ↓
DUT pointer清零
Scoreboard queue清空
      ↓
full = 0
empty = 1
      ↓
reset释放
      ↓
重新Write / Read
      ↓
Scoreboard PASS
```

验证 FIFO 在运行过程中 Reset 后能够正确恢复。

---

## 6. Functional Coverage

项目使用 Covergroup 实现功能覆盖率。

覆盖内容包括：

```text
Write Data Range
Read Data Range

wr_en
rd_en

full = 0 / 1
empty = 0 / 1

full  0 → 1
full  1 → 0

empty 0 → 1
empty 1 → 0

wr_en × full
rd_en × empty
```

Coverage Closure 过程不是简单增加随机仿真次数，而是根据 Coverage Hole 编写 Targeted Test。

例如：

```text
wr_state = 50%
      ↓
发现FULL没有覆盖
      ↓
fifo_full_test
      ↓
wr_state = 93.75%
      ↓
发现 wr_en && full 没覆盖
      ↓
fifo_illegal_test
      ↓
wr_state = 100%
```

最终 Covergroup Functional Coverage 达到：

```text
100%
```

---

## 7. SystemVerilog Assertions

Assertion 通过 `bind` 挂载到 DUT，不需要修改 DUT RTL。

主要 Assertion 包括：

```text
FULL && wr_en
→ Write Pointer 必须保持稳定

EMPTY && rd_en
→ Read Pointer 必须保持稳定

有效Write
→ Binary Write Pointer +1

有效Read
→ Binary Read Pointer +1

有效Write
→ Write Gray Pointer 只允许变化一个bit

有效Read
→ Read Gray Pointer 只允许变化一个bit
```

同时使用 `cover property` 覆盖：

```text
进入FULL
离开FULL

FULL时尝试Write

进入EMPTY
离开EMPTY

EMPTY时尝试Read
```

最终：

```text
Assert Properties      6 / 6
Cover Properties       6 / 6
Assertion Failures         0
Assertion Coverage      100%
```

Assertion Coverage Scope 只统计项目自身的：

```text
fifo_assertions
```

避免 UVM Library 内部 assertion 污染项目 coverage 数据。

---

## 8. Code Coverage

使用 VCS + URG 收集：

```text
Line Coverage
Condition Coverage
Branch Coverage
Toggle Coverage
Assertion Coverage
```

Coverage Closure 过程中：

```text
初始 Toggle Coverage
88.96%
    ↓
定位 Pointer 高位缺少 1→0
    ↓
fifo_wrap_test
    ↓
97.40%
    ↓
增加 Mid-test Reset Recovery
    ↓
进一步提高 Toggle Coverage
```

最终以 DUT `async_fifo` 为统计目标：

```text
LINE       100%
COND       100%
BRANCH     100%
TOGGLE     100%
```

---

## 9. Regression

当前 Regression Test Set：

```text
fifo_test
fifo_full_test
fifo_illegal_test
fifo_wrap_test
fifo_reset_test
```

所有 Test 均要求：

```text
UVM_ERROR : 0
UVM_FATAL : 0
```

每个 Test 独立生成 Coverage Database，最终通过 URG Merge 得到 Regression Coverage。

---

## 10. Makefile 自动化

进入：

```bash
cd sim
```

查看命令：

```bash
make help
```

编译：

```bash
make compile
```

运行单个 Test：

```bash
make test TEST=fifo_test
```

例如：

```bash
make test TEST=fifo_illegal_test
```

重新编译并运行单测：

```bash
make run TEST=fifo_wrap_test
```

运行完整 Regression：

```bash
make regression
```

运行 Regression 并 Merge Coverage：

```bash
make coverage
```

查看 Coverage Summary：

```bash
make summary
```

打开 Verdi：

```bash
make verdi
```

清理生成文件：

```bash
make clean
```

---

## 11. 仿真工具

本项目使用：

```text
SystemVerilog
UVM 1.2
Synopsys VCS O-2018.09-SP2
Synopsys Verdi
URG
GNU Make
```

由于当前 VCS 环境中 bundled UVM DPI 存在兼容问题，本项目采用：

```text
UVM_NO_DPI
+
手动编译 uvm_pkg.sv
```

当前验证环境未使用：

```text
uvm_hdl_read()
uvm_hdl_force()
RAL Backdoor
```

因此不会影响本项目验证功能。

---

## 12. 项目目录

```text
async_fifo_uvm/
├── rtl/
│   └── async_fifo.sv
│
├── tb/
│   ├── interface/
│   │   └── fifo_if.sv
│   │
│   ├── sequence/
│   │   ├── fifo_item.sv
│   │   ├── fifo_wr_sequence.sv
│   │   └── fifo_rd_sequence.sv
│   │
│   ├── agent/
│   │   ├── fifo_wr_sequencer.sv
│   │   ├── fifo_wr_driver.sv
│   │   ├── fifo_wr_monitor.sv
│   │   ├── fifo_wr_agent.sv
│   │   ├── fifo_rd_sequencer.sv
│   │   ├── fifo_rd_driver.sv
│   │   ├── fifo_rd_monitor.sv
│   │   └── fifo_rd_agent.sv
│   │
│   ├── env/
│   │   ├── fifo_scoreboard.sv
│   │   ├── fifo_coverage.sv
│   │   └── fifo_env.sv
│   │
│   ├── assertion/
│   │   └── fifo_assertions.sv
│   │
│   ├── test/
│   │   ├── fifo_test.sv
│   │   ├── fifo_full_test.sv
│   │   ├── fifo_illegal_test.sv
│   │   ├── fifo_wrap_test.sv
│   │   └── fifo_reset_test.sv
│   │
│   └── fifo_pkg.sv
│
├── top/
│   ├── tb_top.sv
│   └── async_fifo_tb.sv
│
├── sim/
│   ├── Makefile
│   ├── filelist.f
│   └── assert_hier.cfg
│
├── waves/
└── README.md
```

---

## 13. 项目验证结果

```text
Regression
--------------------------------
fifo_test           PASS
fifo_full_test      PASS
fifo_illegal_test   PASS
fifo_wrap_test      PASS
fifo_reset_test     PASS


Functional Coverage
--------------------------------
Covergroup           100%
SVA Cover Property   100%


DUT Code Coverage
--------------------------------
Line                 100%
Condition            100%
Branch               100%
Toggle               100%


Assertions
--------------------------------
Coverage             100%
Failures                0
```

---

## 14. 项目涉及的主要 DV 知识

本项目覆盖了以下数字 IC 验证知识：

```text
Async FIFO
CDC
Gray Code
2FF Synchronizer

SystemVerilog Interface
Clocking Block
OOP
Randomization
Queue
Semaphore

UVM Transaction
Sequence
Sequencer
Driver
Monitor
Agent
Environment
Test
Config DB
Analysis Port
Scoreboard

Functional Coverage
Covergroup
Coverpoint
Bins
Cross

SVA
assert property
cover property
bind

Code Coverage
Coverage Closure
Regression
Makefile
VCS
Verdi
URG
```
