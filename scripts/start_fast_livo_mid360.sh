#!/usr/bin/env bash
set -euo pipefail

# One-click startup for the MID360 + Hikrobot camera + FAST-LIVO2 stack.
# Run this after ROS, drivers, FAST-LIVO2, camera intrinsics, and lidar-camera
# extrinsics have been configured.

CATKIN_WS="${CATKIN_WS:-$HOME/catkin_ws}"
LOG_DIR="${LOG_DIR:-$HOME/Three-dimensional-scanner-hardware/logs}"
FAST_LIVO_LAUNCH="${FAST_LIVO_LAUNCH:-mapping_avia.launch}"
START_RVIZ="${START_RVIZ:-true}"

mkdir -p "$LOG_DIR"

PIDS=()

cleanup() {
  echo
  echo "[stop] stopping launched processes..."
  for pid in "${PIDS[@]:-}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done
  wait 2>/dev/null || true
}

trap cleanup EXIT INT TERM

source /opt/ros/noetic/setup.bash
source "$CATKIN_WS/devel/setup.bash"

# Put system libusb before Hikrobot MVS libs. Otherwise PCL may load the MVS
# bundled libusb and FAST-LIVO2 can fail with: undefined symbol libusb_set_option.
export LD_LIBRARY_PATH="/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/opt/MVS/lib/64:/opt/MVS/lib/32:${LD_LIBRARY_PATH:-}"

need_pkg() {
  local pkg="$1"
  if ! rospack find "$pkg" >/dev/null 2>&1; then
    echo "[error] ROS package not found: $pkg"
    echo "        Check that $CATKIN_WS has been built and sourced."
    exit 1
  fi
}

need_pkg livox_ros_driver2
need_pkg mvs_ros_driver
need_pkg fast_livo

echo "[info] CATKIN_WS=$CATKIN_WS"
echo "[info] LOG_DIR=$LOG_DIR"
echo "[info] FAST_LIVO_LAUNCH=$FAST_LIVO_LAUNCH"

if ! rostopic list >/dev/null 2>&1; then
  echo "[start] roscore"
  roscore >"$LOG_DIR/roscore.log" 2>&1 &
  PIDS+=("$!")
  sleep 3
fi

echo "[start] MID360 driver"
roslaunch livox_ros_driver2 msg_MID360.launch >"$LOG_DIR/mid360_driver.log" 2>&1 &
PIDS+=("$!")
sleep 4

echo "[start] Hikrobot camera driver"
roslaunch mvs_ros_driver mvs_camera_trigger.launch >"$LOG_DIR/mvs_camera.log" 2>&1 &
PIDS+=("$!")
sleep 4

echo "[check] waiting for sensor topics"
timeout 20 bash -c 'until rostopic list | grep -q "^/livox/lidar$"; do sleep 1; done' || {
  echo "[warn] /livox/lidar not detected within 20 seconds"
}
timeout 20 bash -c 'until rostopic list | grep -q "^/left_camera/image$"; do sleep 1; done' || {
  echo "[warn] /left_camera/image not detected within 20 seconds"
}

echo "[start] FAST-LIVO2"
if [[ "$FAST_LIVO_LAUNCH" == "mapping_avia.launch" ]]; then
  echo "[note] mapping_avia.launch is suitable for startup testing."
  echo "       For final MID360 reconstruction, use calibrated MID360-specific config."
fi

roslaunch fast_livo "$FAST_LIVO_LAUNCH" rviz:="$START_RVIZ" >"$LOG_DIR/fast_livo.log" 2>&1 &
PIDS+=("$!")

echo
echo "[ok] stack started. Logs:"
echo "     $LOG_DIR/roscore.log"
echo "     $LOG_DIR/mid360_driver.log"
echo "     $LOG_DIR/mvs_camera.log"
echo "     $LOG_DIR/fast_livo.log"
echo
echo "Press Ctrl-C to stop all launched processes."

wait
