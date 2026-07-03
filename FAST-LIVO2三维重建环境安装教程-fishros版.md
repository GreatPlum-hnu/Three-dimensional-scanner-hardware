# FAST-LIVO2 三维重建设备环境安装教程（fishros 版）

本文档用于在 Ubuntu 20.04 环境下安装 ROS Noetic，并配置、编译 FAST-LIVO2 的基础算法环境。

本文档只面向 Livox MID360 手持三维重建设备方案。MID360、海康相机、硬件同步器和 ROS 驱动安装见下一篇：

```text
FAST-LIVO2三维重建硬件同步器与驱动安装-MID360版.md
```

与原教程相比，本文档做了两处调整：

- 删除 Zsh / Oh My Zsh 终端环境配置部分。
- 将 ROS Noetic 手动安装流程替换为 fishros 一键安装。

适用环境：

- Ubuntu 20.04
- ROS Noetic
- FAST-LIVO2
- Livox MID360
- 海康工业相机

## 一、安装 ROS Noetic

推荐使用 fishros 一键安装工具安装 ROS Noetic。

打开终端，执行：

```bash
wget http://fishros.com/install -O fishros && . fishros
```

进入菜单后，按提示选择：

```text
1. 一键安装 ROS
1. 更换系统源再继续安装（推荐）
2. 更换系统源并清理第三方源（推荐）
选择 ROS1 Noetic
选择桌面版 / desktop-full 版本
```

不同版本的一键安装脚本菜单编号可能会变化，请以终端实际显示为准。核心目标是安装：

```text
ROS1 Noetic
```

安装完成后，新开一个终端，检查 ROS 是否可用：

```bash
roscore
```

如果可以正常启动，并看到类似 `started roslaunch server` 的输出，说明 ROS Noetic 安装成功。

如需测试图形界面，可以打开三个终端分别运行：

```bash
roscore
```

```bash
rosrun turtlesim turtlesim_node
```

```bash
rosrun turtlesim turtle_teleop_key
```

## 二、安装基础工具和编译依赖

执行：

```bash
sudo apt update
sudo apt install -y \
  git \
  vim \
  cmake \
  build-essential \
  python3-rosinstall \
  python3-rosinstall-generator \
  python3-wstool \
  python3-catkin-tools
```

确认 ROS 环境变量已经加载：

```bash
echo $ROS_DISTRO
```

正常情况下应输出：

```text
noetic
```

如果没有输出，可以手动执行：

```bash
source /opt/ros/noetic/setup.bash
```

并写入 `~/.bashrc`：

```bash
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

## 三、检查 FAST-LIVO2 依赖

FAST-LIVO2 通常需要以下依赖：

- PCL >= 1.8
- Eigen >= 3.3.4
- OpenCV >= 4.2

安装 ROS Noetic 后，通常已经包含满足要求的版本。可以用下面命令检查。

检查 PCL：

```bash
apt-cache show libpcl-dev | grep Version
```

检查 Eigen：

```bash
pkg-config --modversion eigen3
```

检查 OpenCV：

```bash
pkg-config --modversion opencv4
```

Ubuntu 20.04 + ROS Noetic 常见版本为：

```text
PCL:    1.10.x
Eigen:  3.3.7
OpenCV: 4.2.0
```

## 四、编译安装 Sophus

FAST-LIVO2 依赖 Sophus。执行：

```bash
cd ~
git clone https://github.com/strasdat/Sophus.git
cd Sophus
git checkout a621ff
```

如果编译时报 Eigen 相关错误，需要修改 `sophus/so2.cpp`。

打开文件：

```bash
vim sophus/so2.cpp
```

找到类似下面的代码：

```cpp
unit_complex_.real() = 1.;
unit_complex_.imag() = 0.;
```

修改为：

```cpp
unit_complex_.real(1.);
unit_complex_.imag(0.);
```

然后编译安装：

```bash
mkdir -p build
cd build
cmake ..
make -j$(nproc)
sudo make install
```

如果电脑内存较小，可以将 `make -j$(nproc)` 改为：

```bash
make -j2
```

## 五、创建 Catkin 工作空间

执行：

```bash
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
```

下载依赖仓库：

```bash
git clone https://github.com/xuankuzcr/rpg_vikit.git
```

下载 FAST-LIVO2：

```bash
git clone https://github.com/hku-mars/FAST-LIVO2.git
```

## 六、编译 FAST-LIVO2

回到工作空间根目录：

```bash
cd ~/catkin_ws
```

安装工作空间依赖：

```bash
rosdepc install --from-paths src --ignore-src -r -y
```

编译：

```bash
catkin_make
```

如果电脑内存较小，可以限制编译线程：

```bash
catkin_make -j2
```

编译完成后，加载工作空间环境：

```bash
source ~/catkin_ws/devel/setup.bash
```

建议写入 `~/.bashrc`，方便以后自动加载：

```bash
echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

## 七、检查 FAST-LIVO2 环境

编译完成后，可以先检查 ROS 是否能识别 FAST-LIVO2 包：

```bash
source ~/catkin_ws/devel/setup.bash
rospack find fast_livo
```

如果输出 FAST-LIVO2 的本地路径，说明工作空间已经被 ROS 正确识别。

继续检查 launch 文件是否存在：

```bash
roscd fast_livo
ls launch
```

注意：FAST-LIVO2 官方仓库默认提供的是 AVIA 示例配置。本文档面向 MID360，不建议把 `mapping_avia.launch` 直接当作 MID360 最终配置使用。

完成本篇后，继续进行 MID360、海康相机、硬件同步器和 ROS 驱动安装。

## 八、常见问题

### 1. 终端提示找不到 roscore / roslaunch

说明 ROS 环境变量没有加载。执行：

```bash
source /opt/ros/noetic/setup.bash
```

如果已经编译了工作空间，再执行：

```bash
source ~/catkin_ws/devel/setup.bash
```

### 2. catkin_make 找不到 FAST-LIVO2 包

确认 FAST-LIVO2 是否在 `~/catkin_ws/src` 目录下：

```bash
ls ~/catkin_ws/src
```

目录结构应类似：

```text
catkin_ws
└── src
    ├── FAST-LIVO2
    └── rpg_vikit
```

### 3. 编译时内存不足或卡死

使用较少线程重新编译：

```bash
cd ~/catkin_ws
catkin_make -j2
```

### 4. rosdep 相关问题

fishros 一键安装通常会自动处理 rosdep / rosdepc。如果仍然遇到依赖问题，可以尝试：

```bash
sudo apt install -y python3-pip
sudo pip3 install rosdepc
sudo rosdepc init
rosdepc update
```

然后在工作空间中安装依赖：

```bash
cd ~/catkin_ws
rosdepc install --from-paths src --ignore-src -r -y
```

## 九、参考链接

- FAST-LIVO2: https://github.com/hku-mars/FAST-LIVO2
- rpg_vikit: https://github.com/xuankuzcr/rpg_vikit
- Sophus: https://github.com/strasdat/Sophus
- fishros 一键安装工具: https://fishros.github.io/install/
- 原教程页面: https://www.scan2.world/blog/1
