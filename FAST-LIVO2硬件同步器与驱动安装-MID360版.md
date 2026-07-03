# FAST-LIVO2 手持设备教程：硬件同步器与驱动安装（MID360 版）

本文档基于 `scan2.world` 的 FAST-LIVO2 手持设备教程 2 重新整理，只保留 Livox MID360 相关内容。

本版不包含 AVIA、Livox-SDK、livox_ros_driver 的安装流程。MID360 应使用：

- Livox-SDK2
- livox_ros_driver2
- ROS1 Noetic
- Hikrobot MVS / mvs_ros_driver

## 一、准备内容

建议先完成上一篇环境安装：

- Ubuntu 20.04
- ROS Noetic
- FAST-LIVO2 工作空间
- Catkin 编译环境

硬件侧准备：

- Livox MID360
- 海康工业相机
- 硬件同步器
- MID360 网线 / 一分三线缆
- 相机 USB 线
- 稳定供电模块

## 二、硬件同步器制作说明

原教程的硬件同步器制作过程主要通过图片展示。整理为 MID360 版本时，重点保留以下连接关系：

- MID360：通过网口连接主机，通过供电线接入电源。
- 海康相机：通过 USB 连接主机，通过触发线接入同步器。
- 同步器：负责给相机提供外部触发信号，并与系统供电共地。
- 主机：同时接收 MID360 的点云 / IMU 数据和相机图像数据。

制作和接线时请重点确认：

- 电源电压和电流满足 MID360、相机和同步器要求。
- GND 必须共地。
- 相机触发线极性正确。
- MID360 使用网口通信，不使用 AVIA 的串口配置方式。
- 所有线序以设备手册、同步器原理图和实际接口定义为准。

## 三、安装海康 MVS 驱动

到海康机器人官网下载对应 Linux 版本的 MVS 客户端和 SDK：

```text
https://www.hikrobotics.com/cn/machinevision/service/download/?module=0
```

安装完成后，可以进入 MVS 目录测试软件是否能打开：

```bash
cd /opt/MVS/bin
export LD_LIBRARY_PATH=/opt/MVS/bin/:$LD_LIBRARY_PATH
./MVS
```

如果 `./MVS` 无法启动，也可以尝试：

```bash
./MVS.sh
```

确认 MVS 能识别相机后，再继续配置 ROS 驱动。

## 四、安装 Livox-SDK2

MID360 使用 Livox-SDK2，不使用 Livox-SDK。

执行：

```bash
cd ~
git clone https://github.com/Livox-SDK/Livox-SDK2.git
cd Livox-SDK2
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install
```

如果后续启动驱动时提示找不到 Livox SDK2 的动态库，可以临时执行：

```bash
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
```

也可以写入 `~/.bashrc`：

```bash
echo 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib' >> ~/.bashrc
source ~/.bashrc
```

## 五、下载 MID360 和相机 ROS 驱动

建议单独建立一个驱动工作空间：

```bash
mkdir -p ~/liv_handhold_mid360_ws/src
cd ~/liv_handhold_mid360_ws/src
```

下载手持设备驱动仓库：

```bash
git clone https://github.com/xuankuzcr/LIV_handhold.git
```

如果仓库中已经包含 `livox_ros_driver2` 和 `mvs_ros_driver`，将它们移动到当前工作空间的 `src` 下：

```bash
mv LIV_handhold/livox_ros_driver2 ./
mv LIV_handhold/mvs_ros_driver ./
```

如果该仓库内容发生变化，也可以直接下载官方 MID360 驱动：

```bash
git clone https://github.com/Livox-SDK/livox_ros_driver2.git
```

目录建议保持为：

```text
liv_handhold_mid360_ws
└── src
    ├── livox_ros_driver2
    └── mvs_ros_driver
```

## 六、编译 livox_ros_driver2（ROS1）

MID360 的 `livox_ros_driver2` 同时支持 ROS1 和 ROS2。ROS Noetic 下要明确使用 ROS1。

优先使用官方推荐的构建脚本：

```bash
cd ~/liv_handhold_mid360_ws/src/livox_ros_driver2
source /opt/ros/noetic/setup.bash
./build.sh ROS1
```

如果你使用的驱动包要求在工作空间根目录编译，可以使用：

```bash
cd ~/liv_handhold_mid360_ws
catkin_make -DROS_EDITION=ROS1
```

编译完成后加载环境：

```bash
source ~/liv_handhold_mid360_ws/devel/setup.bash
```

建议写入 `~/.bashrc`：

```bash
echo "source ~/liv_handhold_mid360_ws/devel/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

## 七、配置 MID360 网络

MID360 使用静态 IP。常见规则是：

```text
MID360 IP: 192.168.1.1XX
```

其中 `XX` 通常对应 MID360 序列号最后两位。比如序列号最后两位是 `02`，设备 IP 可能是：

```text
192.168.1.102
```

主机有线网卡需要设置到同一网段，例如：

```text
IP 地址:   192.168.1.5
子网掩码: 255.255.255.0
网关:     192.168.1.1
```

设置完成后，测试是否能 ping 通 MID360：

```bash
ping 192.168.1.102
```

请把 `192.168.1.102` 替换为你的 MID360 实际 IP。

## 八、修改 MID360 配置文件

配置文件通常位于：

```bash
~/liv_handhold_mid360_ws/src/livox_ros_driver2/config/MID360_config.json
```

需要重点修改两类 IP：

- `host_net_info`：主机有线网卡 IP，例如 `192.168.1.5`
- `lidar_configs`：MID360 的实际 IP，例如 `192.168.1.102`

典型配置片段如下：

```json
{
  "lidar_summary_info": {
    "lidar_type": 8
  },
  "MID360": {
    "host_net_info": {
      "cmd_data_ip": "192.168.1.5",
      "push_msg_ip": "192.168.1.5",
      "point_data_ip": "192.168.1.5",
      "imu_data_ip": "192.168.1.5"
    }
  },
  "lidar_configs": [
    {
      "ip": "192.168.1.102",
      "pcl_data_type": 1,
      "pattern_mode": 0
    }
  ]
}
```

注意：

- 不要把 AVIA 的 `broadcast_code` 配置方式用于 MID360。
- MID360 主要改 IP，不是改序列号。
- 多个 MID360 时，需要在 `lidar_configs` 中添加多个设备配置。

## 九、修改相机配置文件

相机配置文件通常位于：

```bash
~/liv_handhold_mid360_ws/src/mvs_ros_driver/config/left_camera_trigger.yaml
```

检查触发模式和像素格式。

原教程中提到，如果使用海康 `MV-CU013-A0UC`，需要将 `PixelFormat` 改为 `4`：

```yaml
PixelFormat: 4
```

常见含义：

```text
0: RGB8
1: BayerRG8
2: BayerRG12Packed
3: BayerGB12Packed
4: BayerGB8
```

如果你的相机型号不同，请以 MVS 中能正常出图的像素格式为准。

## 十、启动 MID360 驱动

加载工作空间：

```bash
source ~/liv_handhold_mid360_ws/devel/setup.bash
```

启动 MID360 自定义消息格式驱动：

```bash
roslaunch livox_ros_driver2 msg_MID360.launch
```

如果只是想用 RViz 检查点云显示，可以使用：

```bash
roslaunch livox_ros_driver2 rviz_MID360.launch
```

检查话题：

```bash
rostopic list
```

应能看到类似话题：

```text
/livox/lidar
/livox/imu
```

## 十一、启动海康相机驱动

新开一个终端：

```bash
source ~/liv_handhold_mid360_ws/devel/setup.bash
roslaunch mvs_ros_driver mvs_camera_trigger.launch
```

检查相机话题：

```bash
rostopic list | grep camera
```

常见图像话题：

```text
left_camera/image
```

## 十二、录制 MID360 + 相机数据包

确认 MID360 和相机驱动都启动后，录制 rosbag：

```bash
rosbag record /livox/lidar /livox/imu left_camera/image
```

也可以指定输出文件名：

```bash
rosbag record -O mid360_livo_data.bag /livox/lidar /livox/imu left_camera/image
```

录制完成后查看数据包信息：

```bash
rosbag info mid360_livo_data.bag
```

确认其中包含：

```text
/livox/lidar
/livox/imu
left_camera/image
```

## 十三、运行 FAST-LIVO2

如果你已经配置好了 FAST-LIVO2 的 MID360 参数和外参，可以启动对应 launch 文件。

进入 FAST-LIVO2 工作空间：

```bash
source ~/catkin_ws/devel/setup.bash
```

如果你的工程中已有 MID360 配置，优先使用 MID360 对应 launch，例如：

```bash
roslaunch fast_livo mapping_mid360.launch
```

如果当前工程只有 AVIA 示例配置，则不要直接把 `mapping_avia.launch` 当作 MID360 最终配置使用。需要先确认以下内容已经改成 MID360 对应参数：

- 雷达话题：`/livox/lidar`
- IMU 话题：`/livox/imu`
- 相机话题：`left_camera/image`
- 雷达到相机外参
- 时间同步参数
- MID360 点云格式

播放录制好的数据包：

```bash
rosbag play mid360_livo_data.bag
```

## 十四、常见问题

### 1. 能 ping 通 MID360，但没有点云话题

检查：

- `MID360_config.json` 中主机 IP 是否等于有线网卡 IP。
- `lidar_configs` 中 MID360 IP 是否正确。
- 是否启动了 `msg_MID360.launch`。
- 防火墙是否拦截 UDP 数据。

### 2. 启动驱动时提示找不到 Livox SDK2 动态库

执行：

```bash
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
```

然后重新启动驱动。

### 3. 相机打不开或没有图像

检查：

- MVS 软件是否能识别相机。
- USB 权限是否正常。
- `left_camera_trigger.yaml` 中 `PixelFormat` 是否匹配相机。
- 外部触发线是否接好。
- 同步器是否在输出触发信号。

### 4. rosbag 里没有图像或 IMU

分别检查话题：

```bash
rostopic hz /livox/imu
rostopic hz /livox/lidar
rostopic hz left_camera/image
```

如果某个话题没有频率，说明对应驱动或硬件连接还没有正常工作。

## 十五、参考链接

- 原教程：FAST-LIVO2（手持设备）教程2：硬件同步器的制作与驱动安装  
  https://www.scan2.world/blog/3
- Livox ROS Driver 2  
  https://github.com/Livox-SDK/livox_ros_driver2
- Livox-SDK2  
  https://github.com/Livox-SDK/Livox-SDK2
- LIV_handhold  
  https://github.com/xuankuzcr/LIV_handhold
- 海康机器人 MVS 下载  
  https://www.hikrobotics.com/cn/machinevision/service/download/?module=0
