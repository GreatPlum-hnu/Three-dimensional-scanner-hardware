# FAST-LIVO2 输出数据导入 Postshot 高斯泼溅重建教程

文档顺序：5

本文档说明在完成 FAST-LIVO2 联调、相机内参标定、雷达-相机外参标定后，如何将 FAST-LIVO2 输出的数据整理为 COLMAP 格式，并导入 Postshot 进行 3D Gaussian Splatting 高斯泼溅三维重建。

注意：Postshot 使用的是图像、相机内参和相机位姿。FAST-LIVO2 导出的 COLMAP 格式数据能让 Postshot 跳过传统 COLMAP SfM 求位姿步骤，直接使用 FAST-LIVO2 的轨迹结果进行训练。如果前面的相机内参、雷达-相机外参或轨迹质量不好，高斯泼溅结果会出现模糊、重影、漂浮物或尺度异常。

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

## 四、在 Windows 上安装 Postshot

Windows 电脑建议使用带 NVIDIA 显卡的机器运行 Postshot。采集机仍然可以是 Ubuntu/ROS 环境，负责运行 FAST-LIVO2 并导出 `Log/Colmap`；Windows 电脑只负责导入数据、训练和查看高斯泼溅结果。

安装步骤：

1. 打开 Postshot 官网，下载 Windows 安装包。
2. 按安装向导完成安装。
3. 启动 Postshot，确认软件可以正常打开。

如果使用笔记本电脑，建议插电并在 NVIDIA 控制面板或 Windows 图形设置中让 Postshot 使用独立显卡。

## 五、在 Windows 上准备 Postshot 工程目录

建议在 Windows 上建立单独的工程目录，避免直接修改 FAST-LIVO2 原始输出。本文统一以 `D:\colmap_projects\fast_livo_mid360` 为示例路径。

如果你的实际工程在 E 盘，例如：

```text
E:\colmap_projects\fast_livo_mid360
```

后续命令中的 `D:` 直接替换为 `E:` 即可，其他目录结构保持不变。

在 PowerShell 中创建目录：

```powershell
New-Item -ItemType Directory -Force "D:\colmap_projects\fast_livo_mid360" | Out-Null
```

将采集机上的 FAST-LIVO2 输出复制到该目录，最终结构应为：

```text
D:\colmap_projects\fast_livo_mid360
├── images
│   ├── 00001.png
│   ├── 00002.png
│   └── ...
├── sparse
│   └── 0
│       ├── cameras.txt
│       ├── images.txt
│       └── points3D.txt
└── pcd
    └── ...
```

其中 `pcd` 目录不是 Postshot 导入 COLMAP 格式数据的必需目录，只是为了保留 FAST-LIVO2 输出的点云结果。

## 六、将 FAST-LIVO2 数据复制到 Windows

如果采集机和 Windows 电脑在同一局域网，可以在采集机上打包：

```bash
mkdir -p ~/colmap_projects/fast_livo_mid360
cp -r ~/catkin_ws/src/FAST-LIVO2/Log/Colmap/images ~/colmap_projects/fast_livo_mid360/
cp -r ~/catkin_ws/src/FAST-LIVO2/Log/Colmap/sparse ~/colmap_projects/fast_livo_mid360/
mkdir -p ~/colmap_projects/fast_livo_mid360/pcd
cp ~/catkin_ws/src/FAST-LIVO2/Log/pcd/*.pcd ~/colmap_projects/fast_livo_mid360/pcd/
cd ~/colmap_projects
tar -czf fast_livo_mid360_colmap.tar.gz fast_livo_mid360
```

将 `fast_livo_mid360_colmap.tar.gz` 复制到 Windows，例如放到：

```text
D:\colmap_projects\fast_livo_mid360_colmap.tar.gz
```

在 Windows PowerShell 中解压：

```powershell
New-Item -ItemType Directory -Force "D:\colmap_projects" | Out-Null
tar -xzf "D:\colmap_projects\fast_livo_mid360_colmap.tar.gz" -C "D:\colmap_projects"
```

如果不想打包，也可以用 U 盘、移动硬盘或局域网共享，直接把 `Log/Colmap/images` 和 `Log/Colmap/sparse` 复制到 Windows 工程目录中。

检查文件是否完整：

```powershell
Get-ChildItem "D:\colmap_projects\fast_livo_mid360\images" -File | Measure-Object
Get-ChildItem "D:\colmap_projects\fast_livo_mid360\sparse\0"
```

`sparse\0` 中至少应包含：

```text
cameras.txt
images.txt
points3D.txt
```

## 七、导入 Postshot 进行高斯泼溅重建

启动 Postshot 后，新建工程或选择导入数据。导入时选择工程根目录：

```text
D:\colmap_projects\fast_livo_mid360
```

Postshot 需要识别下面两个核心目录：

```text
D:\colmap_projects\fast_livo_mid360\images
D:\colmap_projects\fast_livo_mid360\sparse\0
```

其中：

- `images` 保存 FAST-LIVO2 输出的图像。
- `sparse\0\cameras.txt` 保存相机模型和内参。
- `sparse\0\images.txt` 保存每张图像对应的相机位姿。
- `sparse\0\points3D.txt` 保存稀疏点云，可以作为初始空间参考。

导入后，优先检查 Postshot 中是否能正确读取相机数量和图像数量。如果图像数量为 0，或相机轨迹明显异常，不要直接开始正式训练，应先回到文件检查步骤。

训练时建议先使用较低质量或快速预览设置跑一轮，确认相机轨迹、图像曝光和整体场景方向正常，再提高训练质量。第一次测试的目标不是追求最高画质，而是确认数据链路正确。

## 八、查看和判断重建效果

训练完成后，在 Postshot 内查看高斯泼溅结果。重点观察：

- 场景主体是否稳定，不应大面积重影。
- 转动视角时，物体边缘不应严重撕裂。
- 地面、墙面、桌面等平面不应出现大面积漂浮物。
- 颜色应与原始图像接近，不应整体偏暗、偏色或闪烁。
- 相机轨迹附近的局部区域通常效果最好，离轨迹太远或纹理太少的区域可能较差。

如果需要导出结果，按照 Postshot 的导出功能保存高斯模型或渲染结果。具体导出格式以后续使用软件为准。

## 九、Windows 常见问题

### 1. Postshot 导入后没有图像

检查：

```powershell
Get-Content "D:\colmap_projects\fast_livo_mid360\sparse\0\images.txt" -TotalCount 20
Get-ChildItem "D:\colmap_projects\fast_livo_mid360\images" -File | Select-Object -First 10
```

`images.txt` 中的图像名必须和 `images\` 目录中的文件名一致，例如：

```text
00001.png
00002.png
```

### 2. 图像尺寸或相机内参不一致

检查 `cameras.txt` 中记录的图像宽高：

```powershell
Get-Content "D:\colmap_projects\fast_livo_mid360\sparse\0\cameras.txt" -TotalCount 20
```

再查看实际图像尺寸。可以右键图片查看属性，也可以用 Python 检查：

```powershell
python -c "from PIL import Image; im=Image.open(r'D:\colmap_projects\fast_livo_mid360\images\00001.png'); print(im.size)"
```

如果没有 Pillow：

```powershell
pip install pillow
```

`cameras.txt` 中的宽高必须和图像实际尺寸一致。若相机驱动使用了 `image_scale: 0.5`，但 FAST-LIVO2 相机配置仍是 `1280 x 1024`，就会出现尺寸不一致。

### 3. 路径中有中文或空格导致导入失败

Windows 下建议把 COLMAP 工程放在纯英文路径中，例如：

```text
D:\colmap_projects\fast_livo_mid360
```

如果必须使用带空格的路径，PowerShell 命令中的路径一定要加双引号。

### 4. 高斯泼溅重建效果很差

常见原因：

- 相机内参不准确。
- 雷达-相机外参不准确。
- 图像模糊、过曝或纹理太少。
- FAST-LIVO2 轨迹漂移。
- 图像数量不足、视角变化不合适或运动速度太快。
- 使用 `mapping_avia.launch` 示例配置测试，而不是正式 MID360 标定配置。
- 画面中存在大量动态物体。
- 场景纹理太少，例如白墙、玻璃、反光金属表面。

### 5. 坐标尺度或方向看起来异常

FAST-LIVO2 输出的 COLMAP 格式模型使用 FAST-LIVO2 估计的位姿和地图坐标。若坐标方向、尺度或外参填写不正确，导入 Postshot 后可能出现相机朝向异常、场景漂移、重影或投影错位。应优先回到 FAST-LIVO2 中检查外参、相机内参和轨迹质量。

## 十、推荐流程

建议按下面顺序处理：

```text
1. 在 Ubuntu 采集机上完成相机内参标定
2. 在 Ubuntu 采集机上完成雷达-相机外参标定
3. 使用正式 MID360 配置运行 FAST-LIVO2
4. 确认 FAST-LIVO2 输出 Log/Colmap
5. 将 images、sparse 和可选 pcd 打包或复制到 Windows 电脑
6. 在 Windows 上解压到 D:\colmap_projects\fast_livo_mid360
7. 在 Postshot 中导入 D:\colmap_projects\fast_livo_mid360
8. 确认图像数量、相机数量和轨迹方向正常
9. 先用快速预览设置训练一轮
10. 确认效果后再提高训练质量并导出结果
```







