
#!/bin/bash
# 此脚本用于Mac App自动化打包

# -------------------------------------  相关资源路径 ------------------------------------

# Chromium 源代码及 depot_tools 根路径
chromiumRoot=/Users/danxiao/Documents/chromium/

# Chromium 源代码路径
chromiumSrcPath=${chromiumRoot}chromium/src/

# 编译文件夹路径
buildName=out/Lovense

# Chromium.app 文件夹路径
chromiumPath=${chromiumSrcPath}${buildName}"/Chromium.app"

# Chromium 编译工具路径
depotToolsPath=${chromiumRoot}depot_tools


# ---------------------------------  step 1. 修改版本号 ---------------------------------

#echo "请输入版本号:"
#read version # 获取标准输入流
#echo $version > ./version # 写入到当前目录
#echo "你输入的版本号为 $version"

version=$(cat ./Version)


chromiumPlistPath=$chromiumSrcPath$buildName/Chromium.app/Contents/Info.plist
#lovenseBrowserPlistPath=/Users/danxiao/Desktop/LovenseBrowser/LovenseBrowser/Info.plist

function changeVersion() {
# PlistBuddy程序的绝对路径
PlistBuddyPath=/usr/libexec/PlistBuddy
    ## 工程中的plist 文件路径
    appInfoPlistPath=$1
    ## 读取bundleShortVersion 版本号
    #bundleShortVersion=$($PlistBuddyPath -c "print CFBundleShortVersionString" ${appInfoPlistPath})
    ## 读取bundleVersion 版本号
    #bundleVersion=$($PlistBuddyPath  -c "print CFBundleVersion" ${appInfoPlistPath})

    # 重新设置 plist文件中的bundleVersion版本号
    bundleShortVersion=$($PlistBuddyPath  -c "Set :CFBundleShortVersionString $version" ${appInfoPlistPath})
    bundleVersion=$($PlistBuddyPath  -c "Set :CFBundleVersion $version" ${appInfoPlistPath})
    # 再次读取bundleVersion 版本号
    #bundleVersion=$($PlistBuddyPath  -c "print CFBundleVersion" ${appInfoPlistPath})
    #bundleShortVersion=$($PlistBuddyPath -c "print CFBundleShortVersionString" ${appInfoPlistPath})
    # 打印版本号
    #echo "版本号修改成功。"
    #echo "Version：$bundleShortVersion"
    #echo "Build：$bundleVersion"
}
#changeVersion $lovenseBrowserPlistPath

## ---------------------------------  step 2. 编译Chrome ---------------------------------

echo "正在编译 Chrome..."


rm -fr $chromiumPath

cd $chromiumSrcPath

export PATH=$depotToolsPath:"$PATH"

ninja -C $buildName chrome

echo "** Chrome 编译成功 **"

changeVersion $chromiumPlistPath

## ---------------------------------  step 3. 打包启动器 ---------------------------------

echo "正在打包启动器..."

rm -fr /Users/danxiao/Desktop/LovenseBrowser/autoBuild

# 打包App
xcodebuild clean -workspace /Users/danxiao/Desktop/LovenseBrowser/LovenseBrowser.xcodeproj/project.xcworkspace -scheme LovenseBrowser -configuration Release clean build -derivedDataPath /Users/danxiao/Desktop/LovenseBrowser/autoBuild

echo "将编译好的Chrome嵌入到启动器内..."

cp -a $chromiumPath /Users/danxiao/Desktop/LovenseBrowser/autoBuild/Build/Products/Release/LovenseBrowser.app/
echo "** 启动器打包成功! **"

# ---------------------------------  step 4. 打包DMG、Zip ---------------------------------

echo "正在制作DMG、Zip..."

# 复制App、并修改App名字
rm -fr /Users/danxiao/Desktop/LovenseBrowser/Lovense_Browser/Lovense\ Browser.app
mv /Users/danxiao/Desktop/LovenseBrowser/autoBuild/Build/Products/Release/LovenseBrowser.app  /Users/danxiao/Desktop/LovenseBrowser/Lovense_Browser/Lovense\ Browser.app

# 制作DMG 、Zip
dropdmg --config-name "Browser" --base-name "Lovense_Browser" --destination "/Users/danxiao/Desktop/LovenseBrowser/Resources/dmg/" /Users/danxiao/Desktop/LovenseBrowser/Lovense_Browser
dropdmg --config-name "Zip" --base-name "Lovense_Browser_Mac_Update" --destination "/Users/danxiao/Desktop/LovenseBrowser/Resources/dmg/" /Users/danxiao/Desktop/LovenseBrowser/Lovense_Browser/Lovense\ Browser.app/

echo "** DMG、Zip制作成功! **"
open /Users/danxiao/Desktop/LovenseBrowser/Resources/package
