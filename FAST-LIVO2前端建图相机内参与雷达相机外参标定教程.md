# FAST-LIVO2 前端建图相机内参与雷达相机外参标定教程

文档顺序：4

本文档用于说明手持三维重建设备在完成硬件安装、驱动安装和基础联调后，如何进行相机内参标定，以及相机与 MID360 雷达之间的外参标定。

在完成本文档之前，`mapping_avia.launch` 只能用于测试 FAST-LIVO2 主程序、雷达话题和相机话题是否能跑通。没有完成标定时，不应将运行结果作为正式三维重建结果。

## 一、标定目标

三维重建系统至少需要两类标定结果：

- 相机内参：描述相机自身成像模型，包括焦距、主点、畸变参数和图像尺寸。
- 雷达-相机外参：描述雷达坐标系和相机坐标系之间的位置与姿态关系。

FAST-LIVO2 中主要会用到这些配置文件：

```text
~/catkin_ws/src/FAST-LIVO2/config/camera_pinhole.yaml
~/catkin_ws/src/FAST-LIVO2/config/avia.yaml
```

当前仍然使用 `mapping_avia.launch` 做联调测试，后续正式使用 MID360 时，建议复制并整理出专用配置：

```text
mapping_mid360.launch
mid360.yaml
camera_mid360.yaml
```

## 二、标定前准备

标定前先确认：

- MID360 和相机已经刚性固定在支架上。
- 标定完成前后不要移动相机、镜头、雷达和支架。
- 相机镜头焦距、光圈、对焦位置已经固定。
- 相机图像输出尺寸已经确定，例如 `1280 x 1024`。
- 相机驱动中的 `image_scale` 和 FAST-LIVO2 相机配置中的尺寸一致。

如果 `left_camera_trigger.yaml` 中设置：

```yaml
image_scale: 1
```

那么 FAST-LIVO2 相机配置中应保持原始尺寸，例如：

```yaml
cam_width: 1280
cam_height: 1024
scale: 1
```

如果使用 `image_scale: 0.5`，则需要同步调整 FAST-LIVO2 的相机模型尺寸和内参。正式标定时建议先使用原始尺寸。

## 三、相机内参标定

相机内参可以使用 OpenCV、ROS `camera_calibration` 或海康 MVS 采图后离线标定。本文推荐先用 ROS 工具完成标定。

安装标定工具：

```bash
sudo apt install -y ros-noetic-camera-calibration
```

启动相机驱动：

```bash
source ~/catkin_ws/devel/setup.bash
roslaunch mvs_ros_driver mvs_camera_trigger.launch
```

确认图像话题和尺寸：

```bash
rostopic list | grep image
rostopic echo -n 1 /left_camera/image/width
rostopic echo -n 1 /left_camera/image/height
```

如果 `rostopic echo /left_camera/image/width` 无法直接读取，也可以查看完整图像消息：

```bash
rostopic echo -n 1 /left_camera/image
```

使用棋盘格标定板进行标定。下面以 `8 x 6` 内角点、每个格子 `0.15 m` 为例，实际参数需要按你的标定板修改：

```bash
rosrun camera_calibration cameracalibrator.py \
  --size 8x6 \
  --square 0.15 \
  image:=/left_camera/image
```

采集时让标定板出现在画面不同位置和不同角度：

- 靠近画面中心、四角和边缘。
- 有正视、倾斜、远近变化。
- 保证图案清晰，不要过曝或运动模糊。
- 标定过程中不要改变镜头焦距和对焦。

标定完成后记录：

- 图像宽高。
- `fx`、`fy`、`cx`、`cy`。
- 畸变参数 `d0`、`d1`、`d2`、`d3`。

## 四、写入 FAST-LIVO2 相机配置

将相机内参写入：

```bash
~/catkin_ws/src/FAST-LIVO2/config/camera_pinhole.yaml
```

配置示例：

```yaml
cam_model: Pinhole
cam_width: 1280
cam_height: 1024
scale: 1
cam_fx: 1298.6550242665473
cam_fy: 1297.9353131134299
cam_cx: 627.2691200086692
cam_cy: 485.3881646195598
cam_d0: -0.07356933181806001
cam_d1: 0.08039469627671299
cam_d2: -0.000706232243829042
cam_d3: -0.000518274892345108
```

注意：上面的数值是当前工程中的示例值。正式使用时，需要替换成你自己相机和镜头的标定结果。

## 五、雷达-相机外参标定

外参标定参考 `scan2.world` 的 FAST-LIVO2 手持设备外参标定教程：

```text
https://www.scan2.world/blog/5
```

该教程使用 `FAST-Calib` 进行外参标定。它需要准备手持设备、标定板、雷达点云和对应图像。

外参标定时需要注意：

- 平稳放置手持设备，让相机和雷达同时看到完整标定板。
- 开始采集后不要移动手持设备和标定板。
- 如果做多场景联合标定，可以从不同角度采集多组数据，建议至少三个角度。
- 每组数据都要保证雷达点云和相机图像中标定板清晰可见。

## 六、准备外参标定数据

启动雷达驱动：

```bash
source ~/catkin_ws/devel/setup.bash
roslaunch livox_ros_driver2 msg_MID360.launch
```

启动相机驱动：

```bash
source ~/catkin_ws/devel/setup.bash
roslaunch mvs_ros_driver mvs_camera_trigger.launch
```

查看相机画面：

```bash
rqt_image_view
```

录制雷达和相机数据，建议每组大约 10 秒：

```bash
rosbag record -O calib_mid360_camera.bag /livox/lidar /left_camera/image
```

如果你的外参标定流程需要 IMU，也可以一起录制：

```bash
rosbag record -O calib_mid360_camera.bag /livox/lidar /livox/imu /left_camera/image
```

从 rosbag 中解出一张清晰图像，用于 FAST-Calib 配置。可以播放数据包并使用 `rqt_image_view` 保存图像：

```bash
roscore
```

新开终端：

```bash
rqt_image_view
```

再新开终端：

```bash
rosbag play calib_mid360_camera.bag
```

保存图像后，记录图像路径和 rosbag 路径，后续写入 FAST-Calib 配置文件。

## 七、安装并编译 FAST-Calib

建议单独建立一个标定工作空间：

```bash
mkdir -p ~/calib_ws/src
cd ~/calib_ws/src
git clone https://github.com/hku-mars/FAST-Calib.git
```

检查依赖：

```bash
dpkg -l | grep libpcl
opencv_version
```

编译：

```bash
cd ~/calib_ws
catkin_make
source ~/calib_ws/devel/setup.bash
```

如果编译时出现 PCL / libusb 相关问题，例如：

```text
libpcl_io.so: undefined reference to `libusb_set_option'
```

通常是 PCL 链接到了海康 MVS 自带的旧版 `libusb`。可以先检查：

```bash
ldd /usr/lib/x86_64-linux-gnu/libpcl_io.so 2>/dev/null | grep -i usb
```

如果输出指向：

```text
/opt/MVS/lib/64/libusb-1.0.so.0
```

可以临时移除 MVS 库路径：

```bash
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed 's|/opt/MVS/lib/64:||g; s|/opt/MVS/lib/32:||g')
```

也可以显式指定系统 libusb：

```bash
export LD_PRELOAD=/lib/x86_64-linux-gnu/libusb-1.0.so.0
```

然后重新编译：

```bash
cd ~/calib_ws
catkin_make
```

## 八、配置 FAST-Calib

FAST-Calib 中需要重点检查：

- launch 文件：`calib.launch` 用于单场景标定。
- launch 文件：`multi_calib.launch` 用于多场景联合标定。
- 配置文件：`qr_params.yaml`。

`qr_params.yaml` 中通常需要配置：

- 相机内参：`fx`、`fy`、`cx`、`cy`、`k1`、`k2`、`p1`、`p2`。
- 标定板参数。
- rosbag 路径。
- 从 rosbag 中解出的图像路径。
- 输出路径。
- 点云距离滤波参数。

标定板参数需要按实际标定板填写，例如：

- `marker_size`：ArUco 二维码边长。
- `delta_width_qr_center`：两个二维码水平中心距的一半。
- `delta_height_qr_center`：两个二维码垂直中心距的一半。
- `delta_width_circles`：两个圆心水平距离。
- `delta_height_circles`：两个圆心垂直距离。
- `circle_radius`：圆形靶标半径。

如果过滤后的点云没有准确落在标定板附近，需要调整距离滤波参数。可以在 RViz 中订阅：

```text
/filtered_cloud
```

查看过滤后的点云是否只保留了标定板附近的点。

参考教程中也提到可以使用：

```bash
python src/FAST-Calib/scripts/distance_filter_tool.py <YOUR_CALIB_DATA_PATH> <YOUR_OUTPUT_PATH>
```

辅助获取距离滤波阈值。使用前需要确认脚本中的点云话题名称和你的 rosbag 一致，例如：

```python
topic_name="/livox/lidar"
```

## 九、运行 FAST-Calib 外参标定

单场景标定：

```bash
cd ~/calib_ws
source devel/setup.bash
roslaunch fast_calib calib.launch
```

标定完成后，在输出目录中查看结果文件，例如：

```text
output/single_calib_result.txt
```

多场景联合标定：

```bash
roslaunch fast_calib multi_calib.launch
```

多场景联合标定通常需要先运行至少三组单场景标定，使输出目录中生成多组记录，然后再运行 `multi_calib.launch`。

## 十、可选：使用 livox_camera_calib

本地工作空间中也已有 `livox_camera_calib`：

```text
~/catkin_ws/src/livox_camera_calib
```

它也可用于雷达-相机外参标定，通常需要准备同一场景下的图像文件和点云文件，例如：

```text
0.png
0.pcd
```

对应配置文件为：

```bash
~/catkin_ws/src/livox_camera_calib/config/calib.yaml
```

如果后续选择这条路线，需要根据该工具 README 单独配置 `image_file`、`pcd_file`、`camera_matrix`、`dist_coeffs` 和结果输出路径。

## 十一、写入 FAST-LIVO2 外参配置

FAST-LIVO2 中外参主要写在：

```bash
~/catkin_ws/src/FAST-LIVO2/config/avia.yaml
```

当前仍使用 `mapping_avia.launch` 做测试时，它会加载 `avia.yaml`。正式适配 MID360 时，建议复制出：

```bash
cp ~/catkin_ws/src/FAST-LIVO2/config/avia.yaml ~/catkin_ws/src/FAST-LIVO2/config/mid360.yaml
cp ~/catkin_ws/src/FAST-LIVO2/config/camera_pinhole.yaml ~/catkin_ws/src/FAST-LIVO2/config/camera_mid360.yaml
cp ~/catkin_ws/src/FAST-LIVO2/launch/mapping_avia.launch ~/catkin_ws/src/FAST-LIVO2/launch/mapping_mid360.launch
```

然后在 `mapping_mid360.launch` 中加载：

```xml
<rosparam command="load" file="$(find fast_livo)/config/mid360.yaml" />
<rosparam file="$(find fast_livo)/config/camera_mid360.yaml" />
```

外参相关字段示例：

```yaml
extrin_calib:
  extrinsic_T: [0.04165, 0.02326, -0.0284]
  extrinsic_R: [1, 0, 0,
                0, 1, 0,
                0, 0, 1]
  Rcl: [0.001850, -0.999997, -0.001953,
        0.394715,  0.002525, -0.918800,
        0.918802,  0.000929,  0.394718]
  Pcl: [0.012517, -0.146753, -0.012668]
```

注意：这里的示例值来自现有工程配置，不能直接作为最终 MID360 外参。需要根据 FAST-Calib 的输出结果和 FAST-LIVO2 对坐标方向的定义进行对应填写。

## 十二、标定结果检查

标定完成后，至少检查以下内容：

- 图像尺寸和 FAST-LIVO2 相机配置一致。
- 相机内参来自当前相机、当前镜头、当前分辨率。
- 雷达点云投影到图像时，边缘能和图像边缘基本重合。
- 手持轻微移动时，彩色点云没有明显重影。
- 标定后没有移动雷达、相机、镜头和支架。

如果出现以下现象，需要重新检查标定：

- 点云颜色整体偏移。
- 边缘投影左右或上下方向明显错位。
- 近处对齐、远处不对齐，或远处对齐、近处不对齐。
- 图像尺寸报错：`provided image has not the same size as the camera model`。
- FAST-LIVO2 运行时轨迹漂移明显，或者彩色点云重影严重。

## 十三、推荐流程

建议按下面顺序完成：

```text
1. 固定雷达、相机和镜头
2. 确认相机输出尺寸
3. 标定相机内参
4. 将内参写入 camera_pinhole.yaml 或 camera_mid360.yaml
5. 采集雷达-相机外参标定数据
6. 使用 FAST-Calib 求外参
7. 将外参写入 FAST-LIVO2 配置
8. 运行 FAST-LIVO2 验证投影、轨迹和彩色点云
```
