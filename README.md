# niri-dotfiles

这份仓库保存我当前在用的 `niri` 配置，并带上截图、壁纸、锁屏、剪贴板、托盘轮切、自动显示器切换等配套脚本。

## 仓库内容

- `config.kdl` 和若干 `*.kdl`：主配置与拆分模块。
- `scripts/`：壁纸、截图、锁屏、快捷菜单、托盘轮切、显示器热插拔等脚本。
- `scripts/niri-user-config.sh`：集中放壁纸目录、内屏参数、Zen 路径、托盘图标路径等用户可调项。
- `systemd/`：用户级 `systemd` 服务，负责 `awww` 壁纸 daemon 和壁纸状态恢复。
- `hyprlock.conf`：锁屏界面配置。
- `install.sh`：一键安装/链接脚本。

## 一键安装

默认以软链接方式安装，适合直接把仓库当 dotfiles 源。

```bash
git clone git@github.com:SceAce/niri-dotfiles.git
cd niri-dotfiles
./install.sh
```

如果你想复制文件而不是软链接：

```bash
./install.sh --copy
```

如果目标路径已有旧文件，脚本默认会先备份到 `~/.local/state/niri-dotfiles-backups/`。确认不需要备份时可加 `--force`。

安装脚本会做这些事：

1. 把仓库里的配置安装到 `~/.config/niri/`
2. 把 `hyprlock.conf` 安装到 `~/.config/hypr/hyprlock.conf`
3. 把 `systemd/*.service` 安装到 `~/.config/systemd/user/`
4. 自动执行一次 `systemctl --user daemon-reload`

安装完成后建议先改一遍：

- `~/.config/niri/scripts/niri-user-config.sh`
- `output.kdl`

其中 `niri-user-config.sh` 负责脚本层的集中参数；`output.kdl` 仍然是 niri 原生输出配置，需要按你自己的显示器名字、模式和缩放单独调整。

## 快速自检

```bash
~/.config/niri/scripts/check-deps.sh
```

这个脚本会检查：

- 核心命令是否存在
- 可选增强组件是否存在
- 壁纸目录、matugen 颜色缓存、rofi 配置目录、托盘图标路径是否存在
- `systemd --user` 服务文件是否已安装

## Arch 依赖

下面按“核心必需”和“增强可选”分开列。

### 核心必需

```bash
sudo pacman -S --needed \
  copyq brightnessctl fcitx5 fcitx5-gtk fcitx5-qt ghostty grim \
  hyprlock imagemagick jq libnotify mako python python-gobject \
  rofi satty slurp swayidle thunar wl-clipboard xdg-desktop-portal-gnome \
  xorg-xhost
```

`niri`、`awww`、`quickshell`、`mouse-actions` 这几个组件在很多环境里不是官方仓库现成组合，通常需要你自己从 AUR、overlay 或源码安装。这个仓库的脚本依赖以下命令存在：

- `niri`
- `awww` / `awww-daemon`
- `qs`（Quickshell）
- `mouse-actions`

### 可选增强

```bash
sudo pacman -S --needed \
  hyprpicker playerctl
```

下面这些是我当前配置里可选接入的外部组件，不装也不会让主配置完全失效，但对应功能会缺失：

- `swayosd`
- `polkit-gnome`
- `fcitx5-configtool`
- Chrome 或 Chromium 类浏览器
- `zen-browser` / `zen-browser-bin`

## Gentoo 依赖

Gentoo 这边我不把所有包名写死，因为 overlay、profile 和关键字状态差异比 Arch 大得多。更稳妥的方式是按命令名准备这些组件，然后用 `emerge -s <name>` 对照你本机仓库解析：

- `niri`
- `copyq`
- `ghostty`
- `grim`
- `hyprlock`
- `mako`
- `rofi`
- `satty`
- `slurp`
- `swayidle`
- `wl-clipboard`
- `imagemagick`
- `brightnessctl`
- `xdg-desktop-portal-gnome`
- `xhost`
- `libnotify`
- `python`
- `pygobject`
- `jq`
- `thunar`
- `fcitx5`

根据 Gentoo Packages 现状，下面这些已经能在官方包站查到：

- `x11-terms/ghostty`
- `gui-apps/grim`
- `gui-apps/hyprlock`
- `gui-apps/mako`
- `x11-misc/rofi`
- `gui-apps/slurp`
- `gui-apps/swayidle`
- `xfce-base/thunar`
- `x11-libs/libnotify`

下面这些则更可能需要 overlay、live ebuild、源码编译或你自己维护：

- `niri`
- `awww`
- `quickshell`
- `mouse-actions`
- `satty`

可选增强同样建议准备：

- `gui-apps/hyprpicker`
- `media-sound/playerctl`
- `gui-apps/swayosd`
- `polkit` 对应的认证 agent

## 额外前置条件

这套配置还有几个运行时假设，需要你自己准备：

- 壁纸目录、Zen 路径、托盘图标路径、内屏参数等脚本级配置集中在 `scripts/niri-user-config.sh`
- `hyprlock.conf` 依赖 `~/.cache/matugen/hypr/colors.conf`
- `rofi` 主题配置默认引用 `~/.config/rofi/`
- `Mod+F9` 和启动时护眼模式会调用 `scripts/niri-user-config.sh` 里定义的 `NIRI_TOGGLE_WLSUNSET`
- `clipsync` 是我本地启用的 `systemd --user` 服务，不在本仓库里

现在这些值已经集中到 `scripts/niri-user-config.sh` 里，不需要再改多个脚本。

## 已知问题

- `output.kdl` 里的输出名、刷新率和缩放还是机器相关配置，换设备后需要手动改。
- `systemctl --user daemon-reload` 在没有 user bus 的纯脚本环境里会跳过，但正常登录图形会话后通常可用。
- `hyprlock.conf` 依赖 `~/.cache/matugen/hypr/colors.conf`；如果没有这个文件，锁屏主题颜色不会按当前设计工作。
- `rofi` 主题文件不在本仓库里，如果你没有自己的 `~/.config/rofi/`，启动器和电源菜单会退回到比较朴素的效果。
- `clipsync` 不是仓库内容，只是当前配置里“存在则启动”的额外服务。

## 截图

截图目录已预留在 [docs/screenshots](/home/source/myGtihub/niri-dotfiles/docs/screenshots/README.md)。

建议补这几张：

- `docs/screenshots/desktop.png`
- `docs/screenshots/overview.png`
- `docs/screenshots/lockscreen.png`
- `docs/screenshots/wallpaper-picker.png`

## 安装后建议

```bash
systemctl --user daemon-reload
niri msg action load-config-file
```

如果是第一次使用，还建议检查：

1. `~/.config/hypr/hyprlock.conf` 是否已安装
2. `~/.config/systemd/user/awww-daemon.service` 和 `niri-wallpaper-restore.service` 是否存在
3. `awww query`、`qs -c noctalia-shell`、`mouse-actions --help` 是否能正常执行
