# FAST-LIVO2 三维重建设备教程：硬件同步器与驱动安装（MID360 版）

本文档基于 `scan2.world` 的 FAST-LIVO2 手持三维重建设备教程 2 重新整理，只保留 Livox MID360 相关内容。

本版不包含 AVIA、Livox-SDK、livox_ros_driver 的安装流程。MID360 应使用：

- Livox-SDK2
- livox_ros_driver2
- ROS1 Noetic
- Hikrobot MVS / mvs_ros_driver

本文档优先使用 `LIV_handhold` 中的 `livox_ros_driver2` 和 `mvs_ros_driver`，因为该仓库的驱动包含面向 FAST-LIVO2 手持三维重建设备的硬件同步适配。官方 `Livox-SDK/livox_ros_driver2` 可用于 MID360 基础点云测试，但不能替代相机驱动和整套同步方案。

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

注意：使用 ROS 驱动打开相机前，请关闭 MVS 客户端，避免相机被 MVS 占用导致 ROS 驱动无法打开设备。

## 四、安装 Livox-SDK2

MID360 使用 Livox-SDK2，不使用 Livox-SDK。

先确认基础编译工具已安装：

```bash
sudo apt update
sudo apt install -y git cmake build-essential
```

执行：

```bash
cd ~
git clone https://github.com/Livox-SDK/Livox-SDK2.git
cd Livox-SDK2
mkdir -p build
cd build
cmake ..
make -j$(nproc)
sudo make install
sudo ldconfig
```

如果电脑内存较小，可以将 `make -j$(nproc)` 改为：

```bash
make -j2
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

本文档统一使用已有的 `~/catkin_ws` 作为 ROS1 工作空间。进入工作空间 `src` 目录：

```bash
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
```

下载三维重建手持设备驱动仓库：

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

注意：官方 `livox_ros_driver2` 只能补充雷达 ROS 驱动，不能提供 `mvs_ros_driver`。相机 ROS 驱动仍需要从 `LIV_handhold` 或后续官方同步器配套仓库中获取。

目录建议保持为：

```text
catkin_ws
└── src
    ├── livox_ros_driver2
    └── mvs_ros_driver
```

## 六、编译 MID360 和相机 ROS 驱动

MID360 的 `livox_ros_driver2` 同时支持 ROS1 和 ROS2。ROS Noetic 下要明确使用 ROS1。

优先使用 `livox_ros_driver2` 的构建脚本。该脚本会回到工作空间根目录执行 `catkin_make`，因此同一工作空间中的 `mvs_ros_driver` 也会一起编译：

```bash
cd ~/catkin_ws/src/livox_ros_driver2
source /opt/ros/noetic/setup.bash
./build.sh ROS1
```

如果你使用的驱动包要求在工作空间根目录编译，建议只编译驱动相关包，避免同一工作空间中的其他包影响本步骤：

```bash
cd ~/catkin_ws
catkin_make -DROS_EDITION=ROS1 -DCATKIN_WHITELIST_PACKAGES="livox_ros_driver2;mvs_ros_driver"
```

编译完成后，如果后续需要恢复整个工作空间编译，可以清空白名单：

```bash
catkin_make -DCATKIN_WHITELIST_PACKAGES=""
```

如果后续要运行 FAST-LIVO2，还需要把 FAST-LIVO2 及其依赖包一起编译。由于当前工作空间中的 `livox_camera_calib` 可能会因为 PCL / libusb 链接问题影响整体编译，可以继续使用白名单方式，跳过 `livox_camera_calib`：

```bash
cd ~/catkin_ws
catkin_make -DROS_EDITION=ROS1 -DCATKIN_WHITELIST_PACKAGES="livox_ros_driver2;mvs_ros_driver;vikit_common;vikit_ros;vikit_py;fast_livo"
```

编译完成后加载环境：

```bash
source ~/catkin_ws/devel/setup.bash
```

检查两个 ROS 包是否都能被找到：

```bash
rospack find livox_ros_driver2
rospack find mvs_ros_driver
```

建议写入 `~/.bashrc`：

```bash
echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc
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
~/catkin_ws/src/livox_ros_driver2/config/MID360_config.json
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
    "lidar_net_info": {
      "cmd_data_port": 56100,
      "push_msg_port": 56200,
      "point_data_port": 56300,
      "imu_data_port": 56400,
      "log_data_port": 56500
    },
    "host_net_info": {
      "cmd_data_ip": "192.168.1.5",
      "cmd_data_port": 56101,
      "push_msg_ip": "192.168.1.5",
      "push_msg_port": 56201,
      "point_data_ip": "192.168.1.5",
      "point_data_port": 56301,
      "imu_data_ip": "192.168.1.5",
      "imu_data_port": 56401,
      "log_data_ip": "",
      "log_data_port": 56501
    }
  },
  "lidar_configs": [
    {
      "ip": "192.168.1.102",
      "pcl_data_type": 1,
      "pattern_mode": 0,
      "extrinsic_parameter": {
        "roll": 0.0,
        "pitch": 0.0,
        "yaw": 0.0,
        "x": 0,
        "y": 0,
        "z": 0
      }
    }
  ]
}
```

注意：

- 不要把 AVIA 的 `broadcast_code` 配置方式用于 MID360。
- MID360 主要改 IP，不是改序列号。
- 多个 MID360 时，需要在 `lidar_configs` 中添加多个设备配置。

下面以我的电脑为例，说明实际需要检查哪些文件。

我的 `livox_ros_driver2` 放在下面这个工作空间：

```bash
~/catkin_ws/src/livox_ros_driver2
```

如果只使用一台 MID360，主要会用到下面几个 launch 文件：

```text
~/catkin_ws/src/livox_ros_driver2/launch_ROS1/msg_MID360.launch
~/catkin_ws/src/livox_ros_driver2/launch_ROS1/rviz_MID360.launch
~/catkin_ws/src/livox_ros_driver2/launch_ROS1/mid360.launch
```

打开这几个 launch 文件，可以看到它们都引用同一个配置文件：

```text
$(find livox_ros_driver2)/config/MID360_config.json
```

所以单 MID360 方案真正需要重点检查的是：

```bash
~/catkin_ws/src/livox_ros_driver2/config/MID360_config.json
```

以我的电脑为例，`MID360_config.json` 中的主机 IP 已经改成 `192.168.1.4`：

```json
"host_net_info": {
  "cmd_data_ip": "192.168.1.4",
  "push_msg_ip": "192.168.1.4",
  "point_data_ip": "192.168.1.4",
  "imu_data_ip": "192.168.1.4"
}
```

这里的 `192.168.1.4` 是我的电脑连接 MID360 所在网段的 IP。你实际配置时，需要改成你自己电脑连接 MID360 的网卡 IP。

同一个文件中，MID360 雷达 IP 已经改成 `192.168.1.165`：

```json
"lidar_configs": [
  {
    "ip": "192.168.1.165"
  }
]
```

再检查 launch 文件中的序列号。以我的 MID360 为例，序列号是 `47MCNCP0036165`：

```xml
<arg name="bd_list" default="47MCNCP0036165"/>
```

这个序列号需要在下面几个单 MID360 launch 文件中保持一致：

```text
msg_MID360.launch
rviz_MID360.launch
mid360.launch
```

另外，`mixed_HAP_MID360_config.json` 不是单 MID360 方案的主配置文件。它只在运行混合设备 launch 时使用：

```text
msg_mixed.launch
rviz_mixed.launch
```

所以如果只接一台 MID360，不需要修改 `mixed_HAP_MID360_config.json`。

## 九、修改相机配置文件

相机配置文件通常位于：

```bash
~/catkin_ws/src/mvs_ros_driver/config/left_camera_trigger.yaml
```

检查触发模式和像素格式。

建议重点检查：

```yaml
TopicName: "left_camera/image"
TriggerEnable: 1
```

其中 `TriggerEnable: 1` 表示使用外部触发。如果只是临时测试相机、没有接同步器触发信号，可以改为 `0` 做无触发出图测试，正式录制时再改回 `1`。

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
source ~/catkin_ws/devel/setup.bash
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

继续检查话题类型和频率：

```bash
rostopic type /livox/lidar
rostopic type /livox/imu
rostopic hz /livox/lidar
rostopic hz /livox/imu
```

使用 `msg_MID360.launch` 时，`/livox/lidar` 通常应为 `livox_ros_driver2/CustomMsg`。

## 十一、启动海康相机驱动

新开一个终端：

```bash
source ~/catkin_ws/devel/setup.bash
roslaunch mvs_ros_driver mvs_camera_trigger.launch
```

检查相机话题：

```bash
rostopic list | grep camera
```

常见图像话题：

```text
/left_camera/image
```

继续检查图像频率：

```bash
rostopic hz /left_camera/image
```

## 十二、录制 MID360 + 相机数据包

确认 MID360 和相机驱动都启动后，录制 rosbag：

```bash
rosbag record /livox/lidar /livox/imu /left_camera/image
```

也可以指定输出文件名：

```bash
rosbag record -O mid360_livo_data.bag /livox/lidar /livox/imu /left_camera/image
```

录制完成后查看数据包信息：

```bash
rosbag info mid360_livo_data.bag
```

确认其中包含：

```text
/livox/lidar
/livox/imu
/left_camera/image
```

## 十三、验证硬件同步是否生效

录制或播放 rosbag 时，可以先检查各话题时间戳是否正常更新：

```bash
rostopic echo -n 5 /livox/lidar/header/stamp
rostopic echo -n 5 /livox/imu/header/stamp
rostopic echo -n 5 /left_camera/image/header/stamp
```

再检查相机触发频率是否稳定：

```bash
rostopic hz /left_camera/image
```

如果同步器输出的是 10 Hz 触发信号，相机图像频率应接近 10 Hz。不同同步器固件或配置的触发频率可能不同，请以实际同步器说明为准。

同步异常时常见现象：

- `/left_camera/image` 没有频率，说明相机没有收到触发信号或触发配置不正确。
- 图像频率明显不稳定，可能是触发线、曝光时间、USB 带宽或相机配置问题。
- 雷达、IMU、图像时间戳存在明显跳变，可能是同步器固件、主机时间或驱动配置问题。

## 十四、运行 FAST-LIVO2

本节中的 FAST-LIVO2 启动仅用于测试环境、驱动、话题和程序是否能跑通。当前还没有完成相机内参标定，也没有完成相机与雷达之间的外参标定，因此这里运行得到的结果只能作为联调参考，不能作为正式三维重建结果。

当前 FAST-LIVO2 工程中还没有 `mapping_mid360.launch`，已有的 launch 文件是官方示例配置。可以先使用 `mapping_avia.launch` 启动，验证 FAST-LIVO2 主程序、雷达话题和相机话题能否跑通。

如果前面只编译了 `livox_ros_driver2` 和 `mvs_ros_driver`，这里需要先确认 FAST-LIVO2 也已经编译：

```bash
cd ~/catkin_ws
catkin_make -DROS_EDITION=ROS1 -DCATKIN_WHITELIST_PACKAGES="livox_ros_driver2;mvs_ros_driver;vikit_common;vikit_ros;vikit_py;fast_livo"
source ~/catkin_ws/devel/setup.bash
```

确认 FAST-LIVO2 包能被 ROS 找到：

```bash
rospack find fast_livo
```

进入 FAST-LIVO2 工作空间环境：

```bash
source ~/catkin_ws/devel/setup.bash
```

查看当前已有 launch 文件：

```bash
ls ~/catkin_ws/src/FAST-LIVO2/launch
```

如果没有 `mapping_mid360.launch`，不要执行：

```bash
roslaunch fast_livo mapping_mid360.launch
```

否则会出现：

```text
RLException: [mapping_mid360.launch] is neither a launch file in package [fast_livo]
```

当前先使用已有的 AVIA 示例 launch 启动：

```bash
roslaunch fast_livo mapping_avia.launch
```

注意：`mapping_avia.launch` 只是当前阶段的启动验证方式，不代表已经完成 MID360 最终适配。它会加载：

```text
~/catkin_ws/src/FAST-LIVO2/config/avia.yaml
~/catkin_ws/src/FAST-LIVO2/config/camera_pinhole.yaml
```

其中 `avia.yaml` 虽然已经使用下面这些话题：

```yaml
img_topic: "/left_camera/image"
lid_topic: "/livox/lidar"
imu_topic: "/livox/imu"
```

但它仍然是 AVIA 示例配置。后续正式使用 MID360 时，需要复制并整理出 MID360 专用配置，例如：

```text
mapping_mid360.launch
mid360.yaml
camera_mid360.yaml
```

并重点确认以下内容已经改成 MID360 对应参数：

- 雷达话题：`/livox/lidar`
- IMU 话题：`/livox/imu`
- 相机话题：`/left_camera/image`
- 雷达到相机外参
- 时间同步参数
- MID360 点云格式
- 相机内参和畸变参数

播放录制好的数据包：

```bash
source ~/catkin_ws/devel/setup.bash
rosbag play mid360_livo_data.bag
```

完成所有配置和标定后，也可以使用项目中的一键启动脚本：

```bash
cd ~/Three-dimensional-scanner-hardware
./scripts/start_fast_livo_mid360.sh
```

如果后续已经创建了正式的 MID360 launch 文件，可以指定：

```bash
FAST_LIVO_LAUNCH=mapping_mid360.launch ./scripts/start_fast_livo_mid360.sh
```

## 十五、常见问题

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

### 3. catkin_make 编译时报 livox_camera_calib 链接错误

如果执行：

```bash
catkin_make -DROS_EDITION=ROS1
```

出现类似错误：

```text
libpcl_io.so: undefined reference to `libusb_set_option'
livox_camera_calib/CMakeFiles/lidar_camera_calib.dir/all
```

说明当前失败的是 `livox_camera_calib`，不是 `livox_ros_driver2`、`mvs_ros_driver` 或 FAST-LIVO2。可以用白名单跳过 `livox_camera_calib`。

如果只测试驱动，可以只编译驱动相关包：

```bash
cd ~/catkin_ws
catkin_make -DROS_EDITION=ROS1 -DCATKIN_WHITELIST_PACKAGES="livox_ros_driver2;mvs_ros_driver"
source ~/catkin_ws/devel/setup.bash
```

如果还要运行 FAST-LIVO2，需要把 FAST-LIVO2 及其依赖一起加入白名单：

```bash
cd ~/catkin_ws
catkin_make -DROS_EDITION=ROS1 -DCATKIN_WHITELIST_PACKAGES="livox_ros_driver2;mvs_ros_driver;vikit_common;vikit_ros;vikit_py;fast_livo"
source ~/catkin_ws/devel/setup.bash
```

确认驱动包能被找到：

```bash
rospack find livox_ros_driver2
rospack find mvs_ros_driver
rospack find fast_livo
```

`livox_camera_calib` 属于后续雷达-相机外参标定相关内容，可以在需要标定时再单独处理。

### 4. FAST-LIVO2 编译时报 libusb_set_option 链接错误

如果编译 FAST-LIVO2 时出现类似错误：

```text
/usr/bin/ld: .../libpcl_io.so: undefined reference to `libusb_set_option'
collect2: error: ld returned 1 exit status
FAST-LIVO2/CMakeFiles/fastlivo_mapping.dir/all
```

说明 `fastlivo_mapping` 在链接 `libpcl_io.so` 时，没有把 `libusb-1.0` 一起链接进去。`libpcl_io` 内部依赖 libusb，部分 Ubuntu / PCL 组合下这个依赖不会自动传递到最终可执行文件。

先确认 libusb 开发包已经安装：

```bash
sudo apt install -y libusb-1.0-0-dev
pkg-config --libs libusb-1.0
```

正常应输出：

```text
-lusb-1.0
```

然后修改 FAST-LIVO2 的 CMake 配置：

```bash
vim ~/catkin_ws/src/FAST-LIVO2/CMakeLists.txt
```

在 `target_link_libraries(fastlivo_mapping ... )` 中加入：

```cmake
usb-1.0
```

修改后类似：

```cmake
target_link_libraries(fastlivo_mapping
  laser_mapping
  vio
  lio
  pre
  imu_proc
  ${catkin_LIBRARIES}
  ${PCL_LIBRARIES}
  ${OpenCV_LIBRARIES}
  ${Sophus_LIBRARIES}
  ${Boost_LIBRARIES}
  usb-1.0
)
```

重新编译：

```bash
cd ~/catkin_ws
catkin_make -DROS_EDITION=ROS1 -DCATKIN_WHITELIST_PACKAGES="livox_ros_driver2;mvs_ros_driver;vikit_common;vikit_ros;vikit_py;fast_livo"
source ~/catkin_ws/devel/setup.bash
```

### 5. FAST-LIVO2 运行时报 libpcl_io.so undefined symbol

如果执行：

```bash
roslaunch fast_livo mapping_avia.launch
```

启动后 `laserMapping` 立刻退出，并出现类似错误：

```text
/home/zhuzhe/catkin_ws/devel/lib/fast_livo/fastlivo_mapping: symbol lookup error:
/usr/lib/x86_64-linux-gnu/libpcl_io.so.1.10: undefined symbol: libusb_set_option
```

说明运行时加载到了不合适的 `libusb-1.0.so.0`。以我的电脑为例，`LD_LIBRARY_PATH` 中 `/opt/MVS/lib/64` 排在系统库前面，导致 PCL 加载了海康 MVS 自带的 `libusb`，而不是系统自带的 `libusb`。

可以用下面命令检查：

```bash
ldd ~/catkin_ws/devel/lib/fast_livo/fastlivo_mapping | grep libusb
ldd /usr/lib/x86_64-linux-gnu/libpcl_io.so.1.10 | grep libusb
```

如果看到：

```text
libusb-1.0.so.0 => /opt/MVS/lib/64/libusb-1.0.so.0
```

就说明动态库搜索顺序有问题。

临时解决方法是在启动 FAST-LIVO2 的终端中，把系统库路径放到 MVS 路径前面：

```bash
export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH
source ~/catkin_ws/devel/setup.bash
roslaunch fast_livo mapping_avia.launch
```

长期建议：

- 不要在 `~/.bashrc` 中把 `/opt/MVS/lib/64` 放在 `LD_LIBRARY_PATH` 最前面。
- 如果需要配置 MVS 库路径，优先放在系统库路径后面。
- 启动 MVS 客户端和启动 FAST-LIVO2 可以使用不同终端，避免 MVS 的库路径污染 FAST-LIVO2 的运行环境。

### 6. FAST-LIVO2 提示 image has not the same size as the camera model

如果启动 FAST-LIVO2 后出现类似错误：

```text
terminate called after throwing an instance of 'std::runtime_error'
what():  Frame: provided image has not the same size as the camera model
```

说明 FAST-LIVO2 收到的图像尺寸，和相机模型配置文件中的尺寸不一致。

以我的电脑为例，FAST-LIVO2 当前加载的是：

```bash
~/catkin_ws/src/FAST-LIVO2/config/camera_pinhole.yaml
```

其中相机模型尺寸为：

```yaml
cam_width: 1280
cam_height: 1024
scale: 1
```

而相机驱动配置文件：

```bash
~/catkin_ws/src/mvs_ros_driver/config/left_camera_trigger.yaml
```

中设置了：

```yaml
image_scale: 0.5
```

这会导致相机驱动发布缩放后的图像，实际图像尺寸可能变成 `640 x 512`，与 FAST-LIVO2 中的 `1280 x 1024` 相机模型不匹配。

临时验证时，建议先让相机驱动发布原始尺寸图像：

```yaml
image_scale: 1
```

修改后重新启动相机驱动和 FAST-LIVO2：

```bash
source ~/catkin_ws/devel/setup.bash
roslaunch mvs_ros_driver mvs_camera_trigger.launch
```

另开终端：

```bash
export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH
source ~/catkin_ws/devel/setup.bash
roslaunch fast_livo mapping_avia.launch
```

也可以保留 `image_scale: 0.5`，但需要同步修改 FAST-LIVO2 的相机模型尺寸和内参，例如将宽高、`cam_fx`、`cam_fy`、`cam_cx`、`cam_cy` 按相同缩放比例调整。正式使用时建议重新标定相机内参，并保持相机驱动输出尺寸与 FAST-LIVO2 相机配置一致。

### 7. 相机打不开或没有图像

检查：

- MVS 软件是否能识别相机。
- USB 权限是否正常。
- `left_camera_trigger.yaml` 中 `PixelFormat` 是否匹配相机。
- 外部触发线是否接好。
- 同步器是否在输出触发信号。

### 8. 相机驱动提示 Shared trigger timestamp is unavailable

如果启动相机驱动时出现类似提示：

```text
[WARN] Shared trigger timestamp is unavailable, stale, or not increasing; using ros::Time::now() for image stamps.
```

含义是：相机驱动没有拿到可用的共享触发时间戳，所以临时使用 `ros::Time::now()` 作为图像时间戳。此时相机可能仍然可以出图，但图像时间戳不是硬件同步器提供的触发时间。

在当前 `mvs_ros_driver` 中，相机驱动会读取下面这个共享时间戳文件：

```bash
~/timeshare
```

可以检查文件是否存在：

```bash
ls -l ~/timeshare
stat ~/timeshare
```

如果文件不存在、没有持续更新，或者其中的时间戳和当前系统时间相差太大，驱动就会打印这个 warning。

以我的电脑为例，`~/timeshare` 文件存在，但其中的时间戳没有持续更新，且和当前系统时间相差超过驱动允许范围，因此相机驱动会退回到 `ros::Time::now()`。

排查顺序：

- 确认硬件同步器已经上电并输出触发信号。
- 确认相机配置中 `TriggerEnable: 1`，并且 `TriggerLine`、`TriggerActivation` 与实际接线一致。
- 确认负责写入 `~/timeshare` 的同步程序或驱动已经启动。
- 使用 `stat ~/timeshare` 观察文件修改时间是否随触发持续变化。
- 如果只是临时测试相机出图，可以先接受该 warning；如果要录制 FAST-LIVO2 数据，需要解决共享触发时间戳问题。

### 9. rosbag 里没有图像或 IMU

分别检查话题：

```bash
rostopic hz /livox/imu
rostopic hz /livox/lidar
rostopic hz /left_camera/image
```

如果某个话题没有频率，说明对应驱动或硬件连接还没有正常工作。

## 十六、参考链接

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
