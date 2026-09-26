# 距离测控仿真系统

> 本项目为**西安电子科技大学（西电）软件仿真 2 A 级达标测试（A 测）**作品：基于 Arduino 与 Proteus 的距离测控仿真系统。

## 已完成

- Arduino 程序：读取 GP2D12 距离、LCD 显示、串口双向通信、电机启停控制。
- 个人阈值：`30 + 学号末位`（本项目为 `36 cm`）。
- Windows 上位机：窗口标题包含学号和姓名，支持串口刷新、打开/关闭、发送学号、接收距离和显示电机状态。
- Proteus 工程：已写入编译通过的 Arduino ELF 固件。
- 实验报告：正文、阈值计算、参考文献和两端源代码已填写，保留两处仿真截图位。

## 目录说明

- `proteus/DisDetectSys_<学号>.pdsprj`：已接入固件的 Proteus 工程。
- `arduino/DistanceControl/DistanceControl.ino`：Arduino 源码。
- `arduino/build/DistanceControl.ino.elf`：Proteus 可使用的已编译固件。
- `pc_host/启动上位机.bat`：Windows 上双击启动，无需安装 Python。
- `pc_host/distance_monitor.ps1`：主上位机源码（Windows PowerShell/WinForms）。
- `pc_host/distance_monitor.py`：Python 备用版本。
- `report/<学号>_<姓名>_计算机科学与技术学院_线上A测报告_待补截图.docx`：待插入两张截图的报告。

## 你需要准备的环境

本题依赖 Proteus 和虚拟串口，只能在 Windows 环境完成最终仿真。准备：

1. Windows 10/11 电脑或 Windows 虚拟机。
2. Proteus 8.17 SP2 或更高版本。
3. Virtual Serial Port Driver（VSPD）。

Arduino IDE 和 Python 都不是必需的：固件已经编译，上位机使用 Windows 自带的 PowerShell 运行。

## 最少操作流程

1. 用 VSPD 新建虚拟串口对 `COM1 ↔ COM2`。
2. 打开 `proteus/DisDetectSys_<学号>.pdsprj`。
3. 确认 Proteus 中 COMPIM 的物理串口为 `COM1`，参数为 `9600, 8N1`；工程原始配置已是 COM1/9600。
4. 双击 `pc_host/启动上位机.bat`，选择 `COM2`，点击“打开串口”，再点击“发送学号”。
5. 启动 Proteus 仿真，观察 LCD 第一行 `ID:本人学号`，第二行显示距离；上位机持续收到同一距离。
6. 将传感器调到 `45 cm`：确认电机转动，截一张同时含传感器、LCD、电机和上位机的图。
7. 将传感器调到 `30 cm`：确认电机停止，再截一张同样范围的图。
8. 把两张图分别放进报告的图 1、图 2 占位框；补充封面中的“专业”和“手机”。
9. 将测试结论中的“待完成两组 Proteus 联调截图后填写：”删除，然后导出 PDF，文件名改为：
   `<学号>_<姓名>_计算机科学与技术学院_线上A测报告.pdf`

## 关键引脚与逻辑

- GP2D12 输出：Arduino `A0`。
- 电机/继电器控制：Arduino `D7`。
- LCD：`RS=D12, E=D11, D4=D5, D5=D4, D6=D3, D7=D2`。
- 串口：`9600 baud, 8 data bits, no parity, 1 stop bit`。
- 距离 `> 36 cm`：电机 ON；距离 `<= 36 cm`：电机 OFF。

## 如果 Proteus 没有自动加载固件

双击 ATmega328P，在 Program File 中选择：

`arduino/build/DistanceControl.ino.elf`

随后重新启动仿真即可。
