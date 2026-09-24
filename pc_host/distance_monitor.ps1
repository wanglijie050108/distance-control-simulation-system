Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$StudentId = '23009200496'
$StudentName = '王李杰'
$BaudRate = 9600
$Threshold = 36
$script:SerialPort = $null
$script:ReceiveBuffer = ''

[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = "距离测控仿真系统 - $StudentId - $StudentName"
$form.Size = New-Object System.Drawing.Size(850, 640)
$form.MinimumSize = New-Object System.Drawing.Size(780, 580)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = '距离测控仿真系统'
$title.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 18, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(20, 18)
$title.AutoSize = $true
$form.Controls.Add($title)

$info = New-Object System.Windows.Forms.Label
$info.Text = "学号：$StudentId    姓名：$StudentName    距离阈值：$Threshold cm"
$info.Location = New-Object System.Drawing.Point(22, 58)
$info.AutoSize = $true
$form.Controls.Add($info)

$serialGroup = New-Object System.Windows.Forms.GroupBox
$serialGroup.Text = '串口控制'
$serialGroup.Location = New-Object System.Drawing.Point(20, 88)
$serialGroup.Size = New-Object System.Drawing.Size(790, 78)
$form.Controls.Add($serialGroup)

$portLabel = New-Object System.Windows.Forms.Label
$portLabel.Text = '串口：'
$portLabel.Location = New-Object System.Drawing.Point(16, 33)
$portLabel.AutoSize = $true
$serialGroup.Controls.Add($portLabel)

$portCombo = New-Object System.Windows.Forms.ComboBox
$portCombo.Location = New-Object System.Drawing.Point(75, 29)
$portCombo.Size = New-Object System.Drawing.Size(150, 28)
$portCombo.DropDownStyle = 'DropDownList'
$serialGroup.Controls.Add($portCombo)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = '刷新'
$refreshButton.Location = New-Object System.Drawing.Point(238, 27)
$refreshButton.Size = New-Object System.Drawing.Size(78, 32)
$serialGroup.Controls.Add($refreshButton)

$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = '打开串口'
$openButton.Location = New-Object System.Drawing.Point(326, 27)
$openButton.Size = New-Object System.Drawing.Size(98, 32)
$serialGroup.Controls.Add($openButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = '串口未打开'
$statusLabel.Location = New-Object System.Drawing.Point(445, 33)
$statusLabel.Size = New-Object System.Drawing.Size(315, 24)
$serialGroup.Controls.Add($statusLabel)

$distanceGroup = New-Object System.Windows.Forms.GroupBox
$distanceGroup.Text = '当前距离'
$distanceGroup.Location = New-Object System.Drawing.Point(20, 178)
$distanceGroup.Size = New-Object System.Drawing.Size(385, 108)
$form.Controls.Add($distanceGroup)

$distanceLabel = New-Object System.Windows.Forms.Label
$distanceLabel.Text = '--.- cm'
$distanceLabel.Font = New-Object System.Drawing.Font('Consolas', 26, [System.Drawing.FontStyle]::Bold)
$distanceLabel.ForeColor = [System.Drawing.Color]::FromArgb(23, 105, 170)
$distanceLabel.Location = New-Object System.Drawing.Point(100, 38)
$distanceLabel.AutoSize = $true
$distanceGroup.Controls.Add($distanceLabel)

$motorGroup = New-Object System.Windows.Forms.GroupBox
$motorGroup.Text = '电机状态'
$motorGroup.Location = New-Object System.Drawing.Point(425, 178)
$motorGroup.Size = New-Object System.Drawing.Size(385, 108)
$form.Controls.Add($motorGroup)

$motorLabel = New-Object System.Windows.Forms.Label
$motorLabel.Text = '未知'
$motorLabel.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 18, [System.Drawing.FontStyle]::Bold)
$motorLabel.Location = New-Object System.Drawing.Point(125, 42)
$motorLabel.AutoSize = $true
$motorGroup.Controls.Add($motorLabel)

$sendGroup = New-Object System.Windows.Forms.GroupBox
$sendGroup.Text = '发送窗口'
$sendGroup.Location = New-Object System.Drawing.Point(20, 298)
$sendGroup.Size = New-Object System.Drawing.Size(790, 78)
$form.Controls.Add($sendGroup)

$sendLabel = New-Object System.Windows.Forms.Label
$sendLabel.Text = '学号：'
$sendLabel.Location = New-Object System.Drawing.Point(16, 34)
$sendLabel.AutoSize = $true
$sendGroup.Controls.Add($sendLabel)

$idTextBox = New-Object System.Windows.Forms.TextBox
$idTextBox.Text = $StudentId
$idTextBox.Location = New-Object System.Drawing.Point(75, 29)
$idTextBox.Size = New-Object System.Drawing.Size(210, 28)
$sendGroup.Controls.Add($idTextBox)

$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = '发送学号'
$sendButton.Location = New-Object System.Drawing.Point(300, 27)
$sendButton.Size = New-Object System.Drawing.Size(100, 32)
$sendGroup.Controls.Add($sendButton)

$receiveGroup = New-Object System.Windows.Forms.GroupBox
$receiveGroup.Text = '接收窗口'
$receiveGroup.Location = New-Object System.Drawing.Point(20, 388)
$receiveGroup.Size = New-Object System.Drawing.Size(790, 170)
$receiveGroup.Anchor = 'Top, Bottom, Left, Right'
$form.Controls.Add($receiveGroup)

$receiveTextBox = New-Object System.Windows.Forms.TextBox
$receiveTextBox.Location = New-Object System.Drawing.Point(12, 27)
$receiveTextBox.Size = New-Object System.Drawing.Size(765, 130)
$receiveTextBox.Multiline = $true
$receiveTextBox.ReadOnly = $true
$receiveTextBox.ScrollBars = 'Vertical'
$receiveTextBox.Font = New-Object System.Drawing.Font('Consolas', 10)
$receiveTextBox.Anchor = 'Top, Bottom, Left, Right'
$receiveGroup.Controls.Add($receiveTextBox)

function Add-Log([string]$Message) {
    $stamp = Get-Date -Format 'HH:mm:ss'
    $receiveTextBox.AppendText("[$stamp] $Message`r`n")
}

function Refresh-Ports {
    $selected = $portCombo.SelectedItem
    $portCombo.Items.Clear()
    [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object | ForEach-Object { [void]$portCombo.Items.Add($_) }
    if ($selected -and $portCombo.Items.Contains($selected)) {
        $portCombo.SelectedItem = $selected
    } elseif ($portCombo.Items.Count -gt 0) {
        $portCombo.SelectedIndex = 0
    }
}

function Close-Port {
    if ($script:SerialPort) {
        try { if ($script:SerialPort.IsOpen) { $script:SerialPort.Close() } } catch {}
        $script:SerialPort.Dispose()
        $script:SerialPort = $null
    }
    $openButton.Text = '打开串口'
    $statusLabel.Text = '串口未打开'
}

$refreshButton.Add_Click({ Refresh-Ports })

$openButton.Add_Click({
    if ($script:SerialPort -and $script:SerialPort.IsOpen) {
        Close-Port
        Add-Log '串口已关闭'
        return
    }
    if (-not $portCombo.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show('未发现串口，请先用 VSPD 创建虚拟串口对，然后点击刷新。', '提示', 'OK', 'Warning') | Out-Null
        return
    }
    try {
        $script:SerialPort = New-Object System.IO.Ports.SerialPort($portCombo.SelectedItem.ToString(), $BaudRate, 'None', 8, 'One')
        $script:SerialPort.NewLine = "`n"
        $script:SerialPort.ReadTimeout = 50
        $script:SerialPort.Open()
        $openButton.Text = '关闭串口'
        $statusLabel.Text = "已打开 $($portCombo.SelectedItem) / $BaudRate baud"
        Add-Log "已打开串口 $($portCombo.SelectedItem)"
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, '串口打开失败', 'OK', 'Error') | Out-Null
        Close-Port
    }
})

$sendButton.Add_Click({
    if ($idTextBox.Text.Trim() -ne $StudentId) {
        [System.Windows.Forms.MessageBox]::Show("必须发送完整学号：$StudentId", '学号不正确', 'OK', 'Warning') | Out-Null
        $idTextBox.Text = $StudentId
        return
    }
    if (-not $script:SerialPort -or -not $script:SerialPort.IsOpen) {
        [System.Windows.Forms.MessageBox]::Show('请先打开串口。', '提示', 'OK', 'Warning') | Out-Null
        return
    }
    try {
        $script:SerialPort.WriteLine("ID:$StudentId")
        Add-Log "发送 -> $StudentId"
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, '发送失败', 'OK', 'Error') | Out-Null
        Close-Port
    }
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    if (-not $script:SerialPort -or -not $script:SerialPort.IsOpen) { return }
    try {
        if ($script:SerialPort.BytesToRead -gt 0) {
            $script:ReceiveBuffer += $script:SerialPort.ReadExisting()
            while ($script:ReceiveBuffer.Contains("`n")) {
                $parts = $script:ReceiveBuffer -split "`n", 2
                $line = $parts[0].Trim()
                $script:ReceiveBuffer = $parts[1]
                if ($line.Length -eq 0) { continue }
                Add-Log "接收 <- $line"
                if ($line -match '^DIST:([0-9]+(?:\.[0-9]+)?),MOTOR:(ON|OFF)$') {
                    $distanceLabel.Text = ('{0:F1} cm' -f [double]$Matches[1])
                    if ($Matches[2] -eq 'ON') {
                        $motorLabel.Text = '转动（ON）'
                        $motorLabel.ForeColor = [System.Drawing.Color]::FromArgb(22, 131, 59)
                    } else {
                        $motorLabel.Text = '停止（OFF）'
                        $motorLabel.ForeColor = [System.Drawing.Color]::FromArgb(179, 38, 30)
                    }
                }
            }
        }
    } catch {
        Add-Log "串口错误：$($_.Exception.Message)"
        Close-Port
    }
})

$form.Add_FormClosing({
    $timer.Stop()
    Close-Port
})

Refresh-Ports
$timer.Start()
[void]$form.ShowDialog()
