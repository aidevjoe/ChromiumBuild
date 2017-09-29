## Chromium 编译教程

#### 准备工作：
* Mac (requied 10.11+)
* Xcode IDE（required 7.3+）
* Git（required 2.2.1+）
* 科学上网

#### 参考链接：
* [官方编译教程](https://chromium.googlesource.com/chromium/src/+/lkcr/docs/mac_build_instructions.md)

* [官方 Release 分支编译教程](https://www.chromium.org/developers/how-tos/get-the-code/working-with-release-branches)

* [内置插件及简单的自定义](http://www.cnblogs.com/honker/p/6397591.html)


#### 步骤概括：
1. 安装 depot_tools 项目构建工具
2. 使用 depot_tools 下载源码
3. 编译 Chromium 源码

### 一、安装 depot_tools 项目构建工具

1. 克隆 depot_tools git仓库

```
$ git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

```

2. 添加环境变量

```
$ export PATH="$PATH:/path/to/depot_tools"

```
> Tip: **/path/to/depot_tools**， 为你 depot_tools 本地的路径



### 二、使用 depot_tools 下载源码

1. 创建一个用于存在 chromium 的目录 (您可以任意命令，并存放在任何您喜欢的位置，只要是路径路径并且没有空格即可）

```
$ mkdir chromium && cd chromium

```


2. 使用 depot_tools 的 fetch 命令，来检查代码及其依赖关系。

```
$ fetch --no-history chromium

```

> Tip: --no-history： 代表不需要历史记录， 完整仓库大约40G
> 		源码大小大概 8G 左右，下载时间因网速而议，请耐心等待



### 三、编译 Chromium 源码

1. 进入源码目录

```
$ cd src
```

2. 生成编译配置文件

```
$ gn args out/Release

```

3. 设置编译配置选项

执行以上命令之后，此时会进入 Vim 编辑模式
按字母键 `o` 进入编辑模式，粘贴一下配置项
按 `:wq` 退出

```

target_cpu = "x64"
is_debug = false
symbol_level = 0
enable_nacl = true
remove_webcore_debug_symbols = true
ffmpeg_branding = "Chrome"
proprietary_codecs = true
enable_iterator_debugging = false
exclude_unwind_tables = true

```

> 具体配置信息见：[链接](https://chromium.googlesource.com/chromium/src/+/lkcr/tools/gn/docs/quick_start.md)

4. 编译代码

```
$ ninja -C out/Release chrome

```

5. 运行

```
$ out/Release/Chromium.app/Contents/MacOS/Chromium

```
> 编译文件大约 3W 左右， 需要 4-8 个小时


#### 脚本

脚本链接： [Github](https://github.com/Joe0708/ChromiumBuild/blob/master/chromiumBuild.sh)
