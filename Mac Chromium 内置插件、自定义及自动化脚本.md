## Mac Chromium 内置插件、自定义及自动化脚本


#### 参考链接：
* [内置插件及简单的自定义](http://www.cnblogs.com/honker/p/6397591.html)


> 以下大部分操作参考链接中已有，里面有说到这里不再赘述。

> 具体讲插件潜入和里面没有说到的点.

> 本文所有操作以 公司的 **Cam** 插件为例

### 一、嵌入插件
1. 添加插件

	将公司插件源码文件夹，复制到 **src\chrome\browser\resources\** 文件夹目录下

2. 修改组件加载源码

	打开 **src\chrome\browser\extensions\component_loader.cc** 文件，
在 **AddDefaultComponentExtensions()** 函数中添加:

```
 Add(IDR_LOVENSE_MANIFEST,
     base::FilePath(FILE_PATH_LITERAL("lovense_cam")));
```

![](http://ojpb4w81b.bkt.clouddn.com/17-9-29/98106686.jpg)

> IDR_LOVENSE_MANIFEST 为插件资源目录的Key, 所有关联插件资源的Key都使用这个

> lovense_cam 对应插件源码的文件夹名 

3. 关联插件的 mainfest.json 文件

	打开 **src\chrome\browser\browser_resources.grd** 文件并添加以下代码：

```
<include name="IDR_LOVENSE_MANIFEST" file="resources\lovense_cam\manifest.json" type="BINDATA" />
```

![](http://ojpb4w81b.bkt.clouddn.com/17-9-29/89964911.jpg)

4. 添加白名单

	打开 **src\chrome\browser\extensions\component_extensions_whitelist\whitelist.cc** 文件，在 **bool IsComponentExtensionWhitelisted(int manifest_resource_id)** 函数中的 **switch** 语句中添加以下代码：
	
	```
	case IDR_LOVENSE_MANIFEST:
	```
	
	![](http://ojpb4w81b.bkt.clouddn.com/17-9-29/13887680.jpg)


5. 添加插件文件路径映射关系

打开 **src\chrome\browser\resources\component_extension_resources.grd** ，把除了mainfest.json文件之外的其他独立文件都加进来。

格式如下：

```
<include name="IDR_LOVENSE_128_PNG"  file="lovense_cam\128.png" type ="BINDATA" />
```

附 Swift 脚本代码：

```
/// 转换XML之后的结果字符串
var xmlString = ""

/// 将插件文件夹内所有内容转换为XML 路径->文件名 键值对
///
/// - Parameter rootDir: 文件夹路径
func convert2XML(rootDir: String) {
    do {
        let folder = try FileManager.default.contentsOfDirectory(atPath: rootDir)
        for itemPath in folder {
            let fullpath = rootDir.appending("/" + itemPath)
            let relPath = fullpath.replacingOccurrences(of: rootPath, with: parentDir)
            
            var isDir: ObjCBool = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: fullpath, isDirectory: &isDir) else { return }
            
            if isDir.boolValue {
                convert2XML(rootDir: fullpath)
            } else {
                if [".DS_Store", "manifest.json"].contains(itemPath) { continue }
                
                let keyName = relPath
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: ".", with: "_")
                    .replacingOccurrences(of: "-", with: "_")
                    .uppercased()
                let xmlItem = "<include name=\"IDR_" + keyName + "\" file=\"\(relPath)\" type=\"BINDATA\" />"
                xmlString.append(xmlItem + "\n")
            }
        }
    } catch {
        print(error)
        exit(1)
    }
}

```

> Tip：必须保证 key 不能有重复的
> Lovense Browser 每次打包时， 如果插件资源文件有添加或删除需要重新生成。


### 二、其他修改
1. 修改 Chromium 关于页面的名字
修改 **src/chrome/app/settings_chromium_strings.grdp** 文件中的 **IDS_SETTINGS_ABOUT_PROGRAM** 对应的值

2. 修改 Chromium 关于页面的版本号
修改 **src/out/Lovense/gen/components/version_info/version_info_values.h** 文件中的 **PRODUCT_VERSION** 对应的值

3. 注释掉从 DMG磁盘镜像中打开 Chromium 提示已到应用程序文件夹中的提示（引发此操作是 Chromium 内核，如果移到应用程序中， 只有 Chromium 内核会移过去，而启动器不会， 所以直接注释掉）
	
	打开 **src/chrome/browser/chrome_browser_main_mac.mm** 文件，注释掉** void ChromeBrowserMainPartsMac::PreMainMessageLoopStart()** 函数中 **IsFirstRunSuppressed** 判断
	
	![](http://ojpb4w81b.bkt.clouddn.com/17-9-29/274156.jpg)
	
	
### 三、编译

参考 [编译教程](http://192.168.0.5/zentao/doc-view-135.html)

	
> 添加资源文件后，编译可能会提示Key越界, 需将 **src/tools/gritsettings/resource_ids** 文件中中includes的值调大

![](http://ojpb4w81b.bkt.clouddn.com/17-9-29/56964818.jpg)

### 四、打包

1. 打开 **LovenseBrowser.xcodeproj** 项目，导出 **iPa** 安装包
2. src/out/Release/Lovense Browser 拷贝到 LovenseBrowser.app/ 目录中
3. 修改启动器名字 Lovense Browser
4. 使用 DropDMG 打包
5. 将Lovense Browser.dmg和Lovense_Browser_Mac_Update.zip上传到服务器并更新后台版本号即可


### 五、脚本

以上所有操作均已使用脚本自动化

脚本地址：[Github](https://github.com/Joe0708/ChromiumBuild/tree/master)

**chromiumBuild.sh** : 主要用于 depot_tools 下载、 Chromium 源码自动下载编译，源码安装好后不需要再使用

**buildStarter.swift** ： 主要用于每次打包时自动将插件文件夹复制到指定位置，自动生成文件映射关系并替换，并修改软件版本号

**build.sh** : 主要用于编译 Chromium，打包 ipa 包，制作 DMG、Zip 文件

### 六、自动化脚本使用

1. 下载脚本源码

2. 打开终端

> 1. 运行 buildStarter.swift 脚本，根据提示输入插件路径和版本号
 
```
$ ./buildStarter.swift
```

> 2. 运行 build.sh 脚本， 编译 Chromium、打包、制作 DMG、Zip 文件

```
$ ./build.sh
```

> Tip: 如果终端提示没有权限，需在终端执行以下命令
> 
>  chmod +x buildStarter.swift

>  chmod +x build.sh
