# FAST-LIVO2 输出数据导入 COLMAP 三维重建教程

文档顺序：5

本文档说明在完成 FAST-LIVO2 联调、相机内参标定、雷达-相机外参标定后，如何将 FAST-LIVO2 输出的数据整理为 COLMAP 工程，并继续进行三维重建处理。

注意：COLMAP 后处理依赖可靠的相机内参、雷达-相机外参和稳定轨迹。如果前面的标定还没有完成，COLMAP 中的图像位姿和点云结果只能用于流程测试，不能作为最终三维重建结果。

## 一、FAST-LIVO2 的 COLMAP 输出

FAST-LIVO2 本地源码中已经包含 COLMAP 输出逻辑。相关配置在：

```bash
~/catkin_ws/src/FAST-LIVO2/config/avia.yaml
```

关键配置为：

```yaml
pcd_save:
  pcd_save_en: true
  colmap_output_en: true
  interval: -1
```

其中：

- `pcd_save_en: true`：保存点云。
- `colmap_output_en: true`：输出 COLMAP 所需的文本文件和图像。
- `interval: -1`：将所有点云保存到一个文件中；数据量大时可能占用较多内存。

FAST-LIVO2 会将 COLMAP 相关文件输出到：

```text
~/catkin_ws/src/FAST-LIVO2/Log/Colmap
```

典型目录结构为：

```text
Log/Colmap
├── images
│   ├── 00001.png
│   ├── 00002.png
│   └── ...
└── sparse
    └── 0
        ├── cameras.txt
        ├── images.txt
        └── points3D.txt
```

同时点云会输出到：

```text
~/catkin_ws/src/FAST-LIVO2/Log/pcd
```

常见文件包括：

```text
all_raw_points.pcd
all_downsampled_points.pcd
lidar_poses.txt
```

## 二、运行 FAST-LIVO2 并生成 COLMAP 数据

启动前确认：

- 雷达驱动正常发布 `/livox/lidar`。
- 相机驱动正常发布 `/left_camera/image`。
- FAST-LIVO2 可以正常运行。
- `camera_pinhole.yaml` 中的图像尺寸和相机实际输出一致。
- `avia.yaml` 或后续 `mid360.yaml` 中的外参已经完成标定。

启动 FAST-LIVO2：

```bash
export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH
source ~/catkin_ws/devel/setup.bash
roslaunch fast_livo mapping_avia.launch
```

如果已经创建了正式 MID360 配置，则改为：

```bash
roslaunch fast_livo mapping_mid360.launch
```

也可以使用一键启动脚本：

```bash
cd ~/Three-dimensional-scanner-hardware
./scripts/start_fast_livo_mid360.sh
```

运行一段时间后，正常退出 FAST-LIVO2。退出时会保存点云和 COLMAP 输出。

## 三、检查输出文件

检查 COLMAP 输出目录：

```bash
ls ~/catkin_ws/src/FAST-LIVO2/Log/Colmap
ls ~/catkin_ws/src/FAST-LIVO2/Log/Colmap/images
ls ~/catkin_ws/src/FAST-LIVO2/Log/Colmap/sparse/0
```

应能看到：

```text
cameras.txt
images.txt
points3D.txt
```

检查图像数量：

```bash
find ~/catkin_ws/src/FAST-LIVO2/Log/Colmap/images -type f -name '*.png' | wc -l
```

检查点云文件：

```bash
ls ~/catkin_ws/src/FAST-LIVO2/Log/pcd
```

如果 `images` 目录为空，通常说明 FAST-LIVO2 没有进入有效 VIO 图像处理流程，需要回头检查相机话题、图像尺寸、相机内参和外参。

## 四、安装 COLMAP

Ubuntu 20.04 可以直接安装：

```bash
sudo apt update
sudo apt install -y colmap
```

检查安装：

```bash
colmap -h
```

如果使用带 CUDA 的 COLMAP，可以根据显卡和系统环境单独编译安装。

## 五、创建 COLMAP 工程目录

建议将 FAST-LIVO2 输出复制到单独的 COLMAP 工程目录，避免覆盖原始输出：

```bash
mkdir -p ~/colmap_projects/fast_livo_mid360
cp -r ~/catkin_ws/src/FAST-LIVO2/Log/Colmap/images ~/colmap_projects/fast_livo_mid360/
cp -r ~/catkin_ws/src/FAST-LIVO2/Log/Colmap/sparse ~/colmap_projects/fast_livo_mid360/
```

目录结构应为：

```text
fast_livo_mid360
├── images
└── sparse
    └── 0
        ├── cameras.txt
        ├── images.txt
        └── points3D.txt
```

COLMAP 可以直接读取这种文本 sparse 模型。

## 六、将数据移动到有显卡的电脑

实际使用中，采集数据的 NUC 或工控机通常没有 NVIDIA GPU，不能运行 COLMAP 的 `patch_match_stereo` 稠密重建。推荐流程是：

```text
采集机：运行 FAST-LIVO2，生成 Log/Colmap 和 Log/pcd
显卡电脑：安装 CUDA 版 COLMAP，执行稠密重建
```

也就是说，采集机只需要完成前面的 FAST-LIVO2 数据录制和本节的数据打包；从下一节开始，COLMAP GUI 查看、模型转换和稠密重建建议都放到有 NVIDIA 显卡的电脑上完成。

在采集机上打包 COLMAP 工程：

```bash
cd ~/colmap_projects
tar -czf fast_livo_mid360_colmap.tar.gz fast_livo_mid360
```

如果还想一起带上 FAST-LIVO2 输出的点云结果，可以额外复制并打包：

```bash
mkdir -p ~/colmap_projects/fast_livo_mid360/pcd
cp ~/catkin_ws/src/FAST-LIVO2/Log/pcd/*.pcd ~/colmap_projects/fast_livo_mid360/pcd/
cd ~/colmap_projects
tar -czf fast_livo_mid360_colmap.tar.gz fast_livo_mid360
```

将压缩包复制到有 NVIDIA 显卡和 CUDA 环境的电脑，例如：

```bash
scp ~/colmap_projects/fast_livo_mid360_colmap.tar.gz USER@GPU_HOST:~/colmap_projects/
```

其中 `USER` 和 `GPU_HOST` 替换为显卡电脑的用户名和地址。

如果两台电脑不在同一个网络中，也可以使用 U 盘或移动硬盘复制这个压缩包：

```text
fast_livo_mid360_colmap.tar.gz
```

在显卡电脑上解压：

```bash
mkdir -p ~/colmap_projects
cd ~/colmap_projects
tar -xzf fast_livo_mid360_colmap.tar.gz
```

检查解压后的文件是否完整：

```bash
ls ~/colmap_projects/fast_livo_mid360/images
ls ~/colmap_projects/fast_livo_mid360/sparse/0
find ~/colmap_projects/fast_livo_mid360/images -type f | wc -l
```

解压后应得到：

```text
~/colmap_projects/fast_livo_mid360
├── images
├── sparse
│   └── 0
│       ├── cameras.txt
│       ├── images.txt
│       └── points3D.txt
└── pcd
    └── ...
```

后续 COLMAP GUI 查看、模型转换和稠密重建都在显卡电脑上进行。采集机如果没有 CUDA，不需要继续执行 `patch_match_stereo`，否则会出现 `Dense stereo reconstruction requires CUDA` 这类错误。

## 七、在 COLMAP GUI 中查看

启动 COLMAP：

```bash
colmap gui
```

在 GUI 中选择：

```text
File -> Import model
```

选择：

```text
~/colmap_projects/fast_livo_mid360/sparse/0
```

注意：COLMAP 可能会提示：

```text
Directory does not contain a project.ini.
To resume the reconstruction, you need to specify a valid database and image path.
Do you want to select the paths now (or press No to only visualize the reconstruction)?
```

这是正常提示。因为这里导入的是 FAST-LIVO2 生成的 sparse 模型目录，不是 COLMAP 自己保存的完整 project，所以目录中没有 `project.ini`。

如果只是查看 FAST-LIVO2 导出的相机轨迹和稀疏点云，选择：

```text
No
```

如果后续要在 COLMAP 中继续做特征提取、匹配或完整重建流程，则选择 `Yes`，然后指定：

```text
database: ~/colmap_projects/fast_livo_mid360/database.db
images:   ~/colmap_projects/fast_livo_mid360/images
```

如果导入成功，应能看到：

- 相机轨迹。
- 稀疏点云。
- 图像列表。

如果导入失败，重点检查：

- `images.txt` 中的图像名是否能在 `images/` 目录中找到。
- `cameras.txt` 中图像宽高和实际图像尺寸是否一致。
- `points3D.txt` 是否为空或格式异常。

## 八、转换 COLMAP 模型格式

COLMAP 文本模型可以转换为二进制模型：

```bash
mkdir -p ~/colmap_projects/fast_livo_mid360/sparse_bin
colmap model_converter \
  --input_path ~/colmap_projects/fast_livo_mid360/sparse/0 \
  --output_path ~/colmap_projects/fast_livo_mid360/sparse_bin \
  --output_type BIN
```

也可以转换为 PLY 方便查看：

```bash
colmap model_converter \
  --input_path ~/colmap_projects/fast_livo_mid360/sparse/0 \
  --output_path ~/colmap_projects/fast_livo_mid360/model.ply \
  --output_type PLY
```

生成的 `model.ply` 可以用 MeshLab、CloudCompare 等工具打开。

## 九、进行稠密重建

COLMAP 的 `patch_match_stereo` 通常需要 CUDA。先检查当前 COLMAP 是否带 CUDA：

```bash
colmap -h | head
```

如果看到类似：

```text
COLMAP 3.6 ... without CUDA
```

说明当前安装的 COLMAP 不能运行 PatchMatch 稠密重建。此时仍然可以导入、查看和转换 FAST-LIVO2 输出的 sparse 模型，但不能继续执行 `patch_match_stereo`。

如果你的机器有 CUDA 显卡，并且安装的是支持 CUDA 的 COLMAP，可以继续准备 COLMAP workspace：

```bash
mkdir -p ~/colmap_projects/fast_livo_mid360/dense
```

对图像进行去畸变：

```bash
colmap image_undistorter \
  --image_path ~/colmap_projects/fast_livo_mid360/images \
  --input_path ~/colmap_projects/fast_livo_mid360/sparse/0 \
  --output_path ~/colmap_projects/fast_livo_mid360/dense \
  --output_type COLMAP
```

运行 PatchMatch Stereo：

```bash
colmap patch_match_stereo \
  --workspace_path ~/colmap_projects/fast_livo_mid360/dense \
  --workspace_format COLMAP
```

融合稠密点云：

```bash
colmap stereo_fusion \
  --workspace_path ~/colmap_projects/fast_livo_mid360/dense \
  --workspace_format COLMAP \
  --input_type geometric \
  --output_path ~/colmap_projects/fast_livo_mid360/dense/fused.ply
```

查看结果：

```bash
meshlab ~/colmap_projects/fast_livo_mid360/dense/fused.ply
```

如果没有安装 MeshLab：

```bash
sudo apt install -y meshlab
```

## 十、常见问题

### 1. COLMAP 导入后没有图像

检查：

```bash
head ~/colmap_projects/fast_livo_mid360/sparse/0/images.txt
ls ~/colmap_projects/fast_livo_mid360/images
```

`images.txt` 中的图像名必须和 `images/` 目录中的文件名一致，例如：

```text
00001.png
00002.png
```

### 2. COLMAP 提示相机模型或图像尺寸不一致

检查：

```bash
head ~/colmap_projects/fast_livo_mid360/sparse/0/cameras.txt
identify ~/colmap_projects/fast_livo_mid360/images/00001.png
```

如果没有 `identify`：

```bash
sudo apt install -y imagemagick
```

`cameras.txt` 中的宽高必须和图像实际尺寸一致。若相机驱动使用了 `image_scale: 0.5`，但 FAST-LIVO2 相机配置仍是 `1280 x 1024`，就会出现尺寸不一致。

### 3. patch_match_stereo 提示 CUDA 不可用

如果出现：

```text
ERROR: Dense stereo reconstruction requires CUDA, which is not available on your system.
```

说明当前安装的 COLMAP 是不带 CUDA 的版本，无法运行 PatchMatch 稠密重建。`--PatchMatchStereo.use_gpu 0` 对这个版本无效，因为该命令在启动时就要求 CUDA。

可以选择：

- 只使用 COLMAP 查看 FAST-LIVO2 导出的 sparse 模型。
- 使用 FAST-LIVO2 输出的 `all_downsampled_points.pcd` 作为点云结果。
- 换到有 NVIDIA 显卡和 CUDA 的机器上运行 COLMAP 稠密重建。
- 自行编译支持 CUDA 的 COLMAP。

### 4. 稠密重建效果很差

常见原因：

- 相机内参不准确。
- 雷达-相机外参不准确。
- 图像模糊、过曝或纹理太少。
- FAST-LIVO2 轨迹漂移。
- 图像数量不足或视角变化不合适。
- 使用 `mapping_avia.launch` 示例配置测试，而不是正式 MID360 标定配置。

### 5. 点云坐标尺度或方向看起来异常

FAST-LIVO2 输出的 COLMAP 模型使用 FAST-LIVO2 估计的位姿和地图坐标。若坐标方向、尺度或外参填写不正确，导入 COLMAP 后可能出现相机朝向异常、点云偏移或投影错位。应优先回到 FAST-LIVO2 中检查外参、相机内参和轨迹质量。

## 十一、推荐流程

建议按下面顺序处理：

```text
1. 完成相机内参标定
2. 完成雷达-相机外参标定
3. 使用正式 MID360 配置运行 FAST-LIVO2
4. 确认 FAST-LIVO2 输出 Log/Colmap
5. 复制 images 和 sparse 到 COLMAP 工程目录
6. 在采集机上打包 fast_livo_mid360 工程
7. 将压缩包移动到有 NVIDIA 显卡和 CUDA 的电脑
8. 在显卡电脑上导入 sparse/0 检查模型
9. 在显卡电脑上执行 image_undistorter、patch_match_stereo、stereo_fusion
10. 使用 MeshLab 或 CloudCompare 查看 fused.ply
```
