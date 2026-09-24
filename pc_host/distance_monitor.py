import queue
import re
import threading
import tkinter as tk
from datetime import datetime
from tkinter import messagebox, ttk

import serial
from serial.tools import list_ports

STUDENT_ID = "23009200496"
STUDENT_NAME = "王李杰"
BAUD_RATE = 9600
THRESHOLD_CM = 36.0


class DistanceMonitorApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title(f"距离测控仿真系统 - {STUDENT_ID} - {STUDENT_NAME}")
        self.root.geometry("820x590")
        self.root.minsize(760, 540)

        self.serial_port = None
        self.reader_thread = None
        self.stop_event = threading.Event()
        self.rx_queue: queue.Queue[str] = queue.Queue()

        self.port_var = tk.StringVar()
        self.status_var = tk.StringVar(value="串口未打开")
        self.id_var = tk.StringVar(value=STUDENT_ID)
        self.distance_var = tk.StringVar(value="--.- cm")
        self.motor_var = tk.StringVar(value="未知")

        self._build_ui()
        self.refresh_ports()
        self.root.after(100, self._drain_rx_queue)
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def _build_ui(self) -> None:
        style = ttk.Style()
        style.configure("Title.TLabel", font=("Microsoft YaHei UI", 17, "bold"))
        style.configure("Value.TLabel", font=("Consolas", 25, "bold"), foreground="#1769aa")
        style.configure("Motor.TLabel", font=("Microsoft YaHei UI", 16, "bold"))

        main = ttk.Frame(self.root, padding=16)
        main.pack(fill=tk.BOTH, expand=True)

        ttk.Label(main, text="距离测控仿真系统", style="Title.TLabel").pack(anchor=tk.W)
        ttk.Label(main, text=f"学号：{STUDENT_ID}    姓名：{STUDENT_NAME}    距离阈值：{THRESHOLD_CM:.0f} cm").pack(anchor=tk.W, pady=(4, 14))

        serial_box = ttk.LabelFrame(main, text="串口控制", padding=10)
        serial_box.pack(fill=tk.X)
        ttk.Label(serial_box, text="串口：").grid(row=0, column=0, padx=(0, 6))
        self.port_combo = ttk.Combobox(serial_box, textvariable=self.port_var, width=18, state="readonly")
        self.port_combo.grid(row=0, column=1, padx=(0, 6))
        ttk.Button(serial_box, text="刷新", command=self.refresh_ports).grid(row=0, column=2, padx=4)
        self.open_button = ttk.Button(serial_box, text="打开串口", command=self.toggle_port)
        self.open_button.grid(row=0, column=3, padx=4)
        ttk.Label(serial_box, textvariable=self.status_var).grid(row=0, column=4, padx=(16, 0))

        data_frame = ttk.Frame(main)
        data_frame.pack(fill=tk.X, pady=12)
        distance_box = ttk.LabelFrame(data_frame, text="当前距离", padding=18)
        distance_box.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 6))
        ttk.Label(distance_box, textvariable=self.distance_var, style="Value.TLabel").pack()
        motor_box = ttk.LabelFrame(data_frame, text="电机状态", padding=18)
        motor_box.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(6, 0))
        self.motor_label = ttk.Label(motor_box, textvariable=self.motor_var, style="Motor.TLabel")
        self.motor_label.pack()

        send_box = ttk.LabelFrame(main, text="发送窗口", padding=10)
        send_box.pack(fill=tk.X)
        ttk.Label(send_box, text="学号：").pack(side=tk.LEFT)
        ttk.Entry(send_box, textvariable=self.id_var, width=24).pack(side=tk.LEFT, padx=8)
        ttk.Button(send_box, text="发送学号", command=self.send_student_id).pack(side=tk.LEFT)

        receive_box = ttk.LabelFrame(main, text="接收窗口", padding=10)
        receive_box.pack(fill=tk.BOTH, expand=True, pady=(12, 0))
        self.receive_text = tk.Text(receive_box, height=12, wrap=tk.WORD, state=tk.DISABLED, font=("Consolas", 11))
        scroll = ttk.Scrollbar(receive_box, orient=tk.VERTICAL, command=self.receive_text.yview)
        self.receive_text.configure(yscrollcommand=scroll.set)
        self.receive_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scroll.pack(side=tk.RIGHT, fill=tk.Y)

    def refresh_ports(self) -> None:
        ports = [item.device for item in list_ports.comports()]
        self.port_combo["values"] = ports
        if self.port_var.get() not in ports:
            self.port_var.set(ports[0] if ports else "")

    def toggle_port(self) -> None:
        if self.serial_port and self.serial_port.is_open:
            self.close_port()
        else:
            self.open_port()

    def open_port(self) -> None:
        port = self.port_var.get().strip()
        if not port:
            messagebox.showwarning("提示", "未发现串口，请先配置 VSPD 虚拟串口并点击刷新。")
            return
        try:
            self.serial_port = serial.Serial(port, BAUD_RATE, timeout=0.2)
            self.stop_event.clear()
            self.reader_thread = threading.Thread(target=self._read_serial, daemon=True)
            self.reader_thread.start()
            self.status_var.set(f"已打开 {port} / {BAUD_RATE} baud")
            self.open_button.configure(text="关闭串口")
            self._append_log(f"已打开串口 {port}")
        except serial.SerialException as exc:
            messagebox.showerror("串口打开失败", str(exc))

    def close_port(self) -> None:
        self.stop_event.set()
        if self.serial_port:
            try:
                self.serial_port.close()
            except serial.SerialException:
                pass
        self.serial_port = None
        self.status_var.set("串口未打开")
        self.open_button.configure(text="打开串口")
        self._append_log("串口已关闭")

    def send_student_id(self) -> None:
        student_id = self.id_var.get().strip()
        if student_id != STUDENT_ID:
            messagebox.showwarning("学号不正确", f"本项目必须发送完整学号：{STUDENT_ID}")
            self.id_var.set(STUDENT_ID)
            return
        if not self.serial_port or not self.serial_port.is_open:
            messagebox.showwarning("提示", "请先打开串口。")
            return
        try:
            payload = f"ID:{student_id}\n".encode("ascii")
            self.serial_port.write(payload)
            self._append_log(f"发送 -> {student_id}")
        except serial.SerialException as exc:
            messagebox.showerror("发送失败", str(exc))
            self.close_port()

    def _read_serial(self) -> None:
        while not self.stop_event.is_set() and self.serial_port and self.serial_port.is_open:
            try:
                raw = self.serial_port.readline()
                if raw:
                    self.rx_queue.put(raw.decode("utf-8", errors="replace").strip())
            except serial.SerialException as exc:
                self.rx_queue.put(f"SERIAL_ERROR:{exc}")
                break

    def _drain_rx_queue(self) -> None:
        try:
            while True:
                line = self.rx_queue.get_nowait()
                if line.startswith("SERIAL_ERROR:"):
                    self._append_log(line)
                    self.close_port()
                    break
                self._append_log(f"接收 <- {line}")
                match = re.fullmatch(r"DIST:([0-9]+(?:\.[0-9]+)?),MOTOR:(ON|OFF)", line)
                if match:
                    distance = float(match.group(1))
                    motor_on = match.group(2) == "ON"
                    self.distance_var.set(f"{distance:.1f} cm")
                    self.motor_var.set("转动（ON）" if motor_on else "停止（OFF）")
                    self.motor_label.configure(foreground="#16833b" if motor_on else "#b3261e")
        except queue.Empty:
            pass
        self.root.after(100, self._drain_rx_queue)

    def _append_log(self, text: str) -> None:
        stamp = datetime.now().strftime("%H:%M:%S")
        self.receive_text.configure(state=tk.NORMAL)
        self.receive_text.insert(tk.END, f"[{stamp}] {text}\n")
        self.receive_text.see(tk.END)
        self.receive_text.configure(state=tk.DISABLED)

    def on_close(self) -> None:
        self.close_port()
        self.root.destroy()


def main() -> None:
    root = tk.Tk()
    DistanceMonitorApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
