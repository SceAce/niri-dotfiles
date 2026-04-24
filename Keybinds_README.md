# Niri Keybinds

这份说明以当前 `binds.kdl` 为准，目标是保留你常用的 Hyprland 肌肉记忆，同时改成适合 `niri` 的列布局模型。

## 启动器与常用应用

- `Mod + A` / `Mod + Z`：应用启动器，使用你的 `rofi type-6` launcher，支持 `drun/run/filebrowser/window`
- `Mod + Enter` / `Mod + T`：终端 `ghostty`
- `Mod + /`：临时浮动终端
- `Mod + E`：文件管理器 `thunar`
- `Mod + B`：浏览器，优先 `Zen`，没有时回退 `xdg-open`
- `Mod + Alt + O`：`opencode`
- `Alt + Tab`：`niri` 原生窗口预览切换器
- `Mod + Shift + /`：快捷键帮助菜单

## 壁纸、概览与会话

- `Mod + G` / `Mod + O`：切换 `overview`
- `Mod + Alt + W`：打开壁纸选择器（rofi），选中后同时更新主壁纸和 overview 背景
- `Mod + F10`：随机切换壁纸，并同步普通桌面与 overview 背景
- `Mod + Shift + F10`：重新同步当前壁纸与 overview 模糊背景
- `Mod + Alt + L`：锁屏
- `Mod + Alt + P`：锁屏并休眠
- `Mod + Shift + Ctrl + Q` / `Ctrl + Alt + Delete`：rofi 电源菜单
- `Mod + Shift + E`：退出 `niri`
- `Mod + F4`：重载 `noctalia-shell`
- `Mod + F9`：切换护眼模式
- `Mod + F1`：切换 `fcitx5`

## 剪贴板、截图、取色

- `Mod + Alt + V`：剪贴板历史，`copyq + rofi`
- `Mod + P`：取色器 `hyprpicker`
- `Print`：区域截图
- `Ctrl + Print`：当前窗口截图
- `Shift + Print`：当前显示器截图
- `Mod + Alt + A`：区域截图
- `Mod + Ctrl + Alt + A`：窗口截图
- `Mod + Ctrl + Alt + Shift + A`：当前显示器截图
- `Mod + Shift + S`：把剪贴板中的截图交给 `satty` 编辑

## 窗口与布局

- `Mod + H/J/K/L` 或方向键：切换焦点
- `Mod + W/S`：向上/向下切换窗口
- `Mod + Ctrl + H/J/K/L` 或方向键：移动列或窗口
- `Mod + Ctrl + A/D`：向左/右移动列
- `Mod + Shift + H/J/K/L` 或方向键：切换显示器焦点
- `Mod + Shift + Ctrl + H/J/K/L` 或方向键：移动列到其他显示器
- `Mod + D`：把窗口向右推出或吸入相邻列
- `Mod + [` / `Mod + ]`：窗口在列之间左/右吞并
- `Mod + ,`：把窗口吸入当前列
- `Mod + .`：把窗口从当前列踢出
- `Mod + X`：切换标签列模式
- `Mod + V`：切换浮动
- `Mod + N`：在浮动层和平铺层之间切换焦点
- `Mod + F`：最大化当前列
- `Mod + Alt + F`：全屏当前窗口
- `Mod + C`：居中当前列
- `Mod + R`：切换预设列宽
- `Mod + Shift + R`：切换预设窗口高度
- `Mod + Ctrl + R`：重置窗口高度
- `Mod + -` / `Mod + =`：缩小/放大列宽
- `Mod + Shift + -` / `Mod + Shift + =`：缩小/放大窗口高度
- `Mod + Q` / `Alt + F4` / `Mod + 鼠标中键`：关闭窗口

## 工作区与多显示器

- `Mod + 1..9`：切换到工作区 1-9
- `Mod + Ctrl + 1..9`：把当前列移动到工作区 1-9
- `Mod + PageUp/PageDown` 或 `Mod + I/U`：切换上下工作区
- `Mod + Ctrl + PageUp/PageDown` 或 `Mod + Ctrl + I/U`：把当前列移动到上下工作区
- `Mod + Shift + Alt + W/A/S/D`：把工作区移动到上下左右显示器
- `Mod + Shift + 鼠标滚轮`：切换工作区
- `Mod + Ctrl + Shift + 鼠标滚轮`：把当前列移动到上下工作区

## 音量与亮度

- `XF86AudioRaiseVolume`：音量增加
- `XF86AudioLowerVolume`：音量降低
- `XF86AudioMute`：静音切换
- `XF86AudioMicMute`：麦克风静音切换
- `XF86MonBrightnessUp`：亮度增加
- `XF86MonBrightnessDown`：亮度降低

## 说明

- `Mod + A` 已经固定为启动器，不再承担旧配置里“向左吞并窗口”的职责。
- 壁纸状态文件在 `~/.cache/niri/current-wallpaper`，当前壁纸软链接在 `~/.cache/.current_wallpaper`。
- `overview` 背景缓存文件在 `~/.cache/niri/overview-wallpaper.png`，签名文件在 `~/.cache/niri/overview-wallpaper.meta`。
- 壁纸 daemon 与登录恢复现在由 `systemd --user` 管理，服务名分别是 `awww-daemon.service` 和 `niri-wallpaper-restore.service`。
- 手动恢复当前壁纸可以执行 `~/.config/niri/scripts/wallpaper-sync.sh restore`。
- `overview` 背景图现在走 `scripts/wallpaper-sync.sh`，优先命中缓存；缓存缺失时会后台生成，不阻塞主桌面壁纸显示。
- 外接显示器自动切换由 `scripts/MonitorAutoSwitch.sh` 负责，逻辑是“有外屏时关闭 `eDP-1`，无外屏时恢复 `eDP-1`”；它不再顺带刷新壁纸或重启 `noctalia-shell`。
