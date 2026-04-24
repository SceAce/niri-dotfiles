# niri-dotfiles

这份仓库保存我当前在用的 `niri` 配置，并带上截图、壁纸、锁屏、剪贴板、托盘轮切、自动显示器切换等配套脚本。

## 仓库内容

- `config.kdl` 和若干 `*.kdl`：主配置与拆分模块。
- `scripts/`：壁纸、截图、锁屏、快捷菜单、托盘轮切、显示器热插拔等脚本。
- `scripts/niri-user-config.sh`：集中放壁纸目录、内屏参数、Zen 路径、托盘图标路径等用户可调项。
- `rofi/`：当前机器正在使用的 `rofi` 主题、脚本和图片资源。
- `noctalia-config/`：当前机器的 `~/.config/noctalia` 运行配置。
- `outputs/`：`niri` 输出布局 profile。
- `quickshell/noctalia-shell/`：仓库内置的 Noctalia / Quickshell 状态栏与桌面壳配置。
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

安装前可以先看可用的输出布局：

```bash
./install.sh --list-output-profiles
```

如果你想显式指定布局：

```bash
./install.sh --output-profile current-machine
```

如果你想复制文件而不是软链接：

```bash
./install.sh --copy --output-profile current-machine
```

如果目标路径已有旧文件，脚本默认会先备份到 `~/.local/state/niri-dotfiles-backups/`。确认不需要备份时可加 `--force`。

安装脚本会做这些事：

1. 把仓库里的配置安装到 `~/.config/niri/`
2. 根据 `--output-profile` 选择一个布局并生成 `~/.config/niri/output.kdl`
3. 把 `hyprlock.conf` 安装到 `~/.config/hypr/hyprlock.conf`
4. 把当前机器的 `rofi` 样式安装到 `~/.config/rofi/`
5. 把当前机器的 `Noctalia` 运行配置安装到 `~/.config/noctalia/`
6. 把 `systemd/*.service` 安装到 `~/.config/systemd/user/`
7. 自动执行一次 `systemctl --user daemon-reload`

安装完成后建议先改一遍：

- `~/.config/niri/scripts/niri-user-config.sh`
- `~/.config/niri/output.kdl`
- `~/.config/noctalia/settings.json`

其中 `niri-user-config.sh` 负责脚本层的集中参数；`output.kdl` 现在由 `outputs/profiles/*.kdl` 生成，你可以直接改 profile 文件，或者在安装时切换 profile。

## 快速自检

```bash
~/.config/niri/scripts/check-deps.sh
```

这个脚本会检查：

- 核心命令是否存在
- 可选增强组件是否存在
- 壁纸目录、matugen 颜色缓存、rofi 配置目录、Noctalia 配置、托盘图标路径是否存在
- `Noctalia Shell` 的 `shell.qml` 是否已经安装
- `systemd --user` 服务文件是否已安装

## 状态栏 / Quickshell

当前仓库已经内置了 `Noctalia Shell`，路径是：

- `quickshell/noctalia-shell/`

`niri` 现在不再依赖系统里名为 `noctalia-shell` 的外部配置名，而是通过下面这个包装脚本显式启动仓库内配置：

- `~/.config/niri/scripts/noctalia-shell.sh`

常用命令：

```bash
~/.config/niri/scripts/noctalia-shell.sh start
~/.config/niri/scripts/noctalia-shell.sh reload
~/.config/niri/scripts/noctalia-shell.sh toggle
~/.config/niri/scripts/noctalia-shell.sh ipc launcher clipboard
```

这部分额外建议准备的依赖：

- `qs`
- `cliphist`
- `curl`

## Rofi 样式

当前机器实际使用的 `rofi` 配置已经跟仓库一起保存，目录是：

- `rofi/`

安装后会落到：

- `~/.config/rofi/`

这意味着以下内容都会一起跟进：

- launcher 样式
- powermenu 样式
- clipboard 菜单样式
- 图片和颜色主题资源

## 输出布局

`output.kdl` 现在不再只是单文件，而是走 profile 目录：

- `outputs/profiles/current-machine.kdl`
- `outputs/profiles/laptop-only.example.kdl`

安装时通过：

```bash
./install.sh --output-profile current-machine
```

把选中的 profile 生成到：

- `~/.config/niri/output.kdl`

如果你换机器，建议新增一个 profile，而不是长期直接手改安装结果。

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
- `rofi` 主题配置现在会由仓库安装到 `~/.config/rofi/`
- `Mod+F9` 和启动时护眼模式会调用 `scripts/niri-user-config.sh` 里定义的 `NIRI_TOGGLE_WLSUNSET`
- `clipsync` 是我本地启用的 `systemd --user` 服务，不在本仓库里
- `Noctalia Shell` 自己会使用 `~/.config/noctalia/`、`~/.cache/noctalia/` 这类运行时目录保存设置、缓存和插件状态

现在脚本层参数已经集中到 `scripts/niri-user-config.sh`，而样式层则直接跟着仓库里的 `rofi/`、`noctalia-config/` 和 `outputs/` 走。

## 已知问题

- `output.kdl` 现在是由 `outputs/profiles/*.kdl` 安装生成的；换设备时建议新增一个 profile，而不是长期手改安装结果。
- `systemctl --user daemon-reload` 在没有 user bus 的纯脚本环境里会跳过，但正常登录图形会话后通常可用。
- `hyprlock.conf` 依赖 `~/.cache/matugen/hypr/colors.conf`；如果没有这个文件，锁屏主题颜色不会按当前设计工作。
- `Noctalia` 的 `settings.json` 已经按我当前机器样式一并纳入，但其中仍可能包含设备、插件或习惯相关选项。
- `clipsync` 不是仓库内容，只是当前配置里“存在则启动”的额外服务。
- `Noctalia Shell` 是直接 vendor 进仓库的上游配置，体积会明显变大；后续如果你继续深改它，最好在这个 repo 内持续维护，而不是再依赖外部目录。

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
3. `awww query`、`~/.config/niri/scripts/noctalia-shell.sh reload`、`mouse-actions --help` 是否能正常执行
