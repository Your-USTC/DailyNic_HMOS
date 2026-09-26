#!/usr/bin/env bash
# 构建 YourUSTC_HarmonyOSNEXT 的 entry 模块（debug HAP）
# 用法: ./build.sh [额外的 hvigor 任务或参数]
# 示例: ./build.sh              # 常规构建
#       ./build.sh clean        # 先 clean 再构建
#
# 说明:
# - DEVECO_SDK_HOME / JAVA_HOME 在当前 shell 环境中未设置，此处统一指向 DevEco Studio 自带目录
# - 打包签名阶段需要 java，使用 DevEco Studio 自带的 jbr
# - hvigor daemon 若带着旧环境启动，会报 Invalid DEVECO_SDK_HOME 或 spawn java ENOENT，
#   脚本在构建失败时会自动 stop-daemon 并重试一次

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR" || exit 1

# DevEco Studio 安装路径（如有变动只需改这里）
DEVECO_HOME="C:/Program Files/Huawei/DevEco Studio"
HVIGORW="$DEVECO_HOME/tools/hvigor/bin/hvigorw.bat"

if [ ! -f "$HVIGORW" ]; then
  echo "错误: 未找到 hvigorw: $HVIGORW" >&2
  echo "请编辑本脚本中的 DEVECO_HOME 指向 DevEco Studio 安装目录" >&2
  exit 1
fi

export DEVECO_SDK_HOME="$DEVECO_HOME/sdk"
export JAVA_HOME="$DEVECO_HOME/jbr"
export PATH="$DEVECO_HOME/jbr/bin:$PATH"

run_build() {
  "$HVIGORW" "$@" --mode module -p module=entry@default -p product=default -p debuggable=true assembleHap
}

echo "== 开始构建 entry 模块 =="
run_build "$@"
status=$?

# 构建失败时重启 daemon（清掉旧环境）后重试一次
if [ $status -ne 0 ]; then
  echo "== 构建失败，重启 hvigor daemon 后重试 ==" >&2
  "$HVIGORW" --stop-daemon >/dev/null 2>&1
  run_build "$@"
  status=$?
fi

if [ $status -eq 0 ]; then
  echo "== 构建成功 =="
  HAP_PATH="$PROJECT_DIR/entry/build/default/outputs/default/entry-default-signed.hap"
  [ -f "$HAP_PATH" ] && echo "产物: $HAP_PATH"
else
  echo "== 构建失败（退出码 $status）==" >&2
fi
exit $status
