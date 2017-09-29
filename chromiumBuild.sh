#!/bin/bash

# Author by: Joe


LogFile="chromiumBuild.log"

echo "*************** 准备开始编译 ***************"
echo ""
echo $(date) | tee -a $LogFile
echo ""
echo "***************  检查 macOS 版本  ***************"
echo ""
OSVersion=$(sw_vers -productVersion)
echo "OS X Version "$OSVersion" detected" | tee -a $LogFile

#######################
######  检查 Git  ######
#######################

echo "***************   检查 Git.   ***************"
echo ""
if command -V git >/dev/null 2>&1; then

	for cmd in git; do
		[[ $("$cmd" --version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		var1=$(echo "$version" | cut -d. -f1)
		var2=$(echo "$version" | cut -d. -f2)
		var3=$(echo "$version" | cut -d. -f3)
		
		if [[ $var1 -lt 2 ]]; then
			echo 'Error: '$cmd' version 2.2.1 or higher required' | tee -a $LogFile
			exit 1;
		fi
		if [[ $var1 -gt 2 && $var2 -lt 2 ]]; then
			echo 'Error: '$cmd' version 2.2.1 or higher required' | tee -a $LogFile
			exit 1;
		fi
		if [[ $var1 -gt 2 && $var2 -gt 2 && $var3 -lt 1 ]]; then
			echo 'Error: '$cmd' version 2.2.1 or higher required' | tee -a $LogFile
			exit 1;
		fi
	done
else 
	echo "ERROR: Git 没有安装，请安装 Xcode 和 Xcode-cli 来获取 Git，或使用 'brew install git' 命令安装 Git. " | tee -a $LogFile
	exit 1;
fi

#######################
#####  检查 Xcode  #####
#######################

echo "***************   检查 Xcode.   ***************"
echo ""
XcodeCheck="$(command xcodebuild -version 2>&1)"
if [[ "$XcodeCheck" =~ "requires" ]]; then
	echo "Xcode not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LogFile
	exit 1;

elif [[ "$XcodeCheck" =~ "note" ]]; then
	echo "Xcode and xcode-cli not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LogFile
	exit 1;

else
	echo "检测到 Xcode, 正在检查版本" | tee -a $LogFile
	for cmd in xcodebuild; do
		[[ $("$cmd" -version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		if ! awk -v ver="$version" 'BEGIN { if (ver < 5.0) exit 1; }'; then
			echo 'Error: '$cmd' version 5.0 or higher required' | tee -a $LogFile
			echo 'Xcode version detected was: '$version | tee -a $LogFile
			exit 1;
		fi
		echo 'Xcode 当前版本是: '$version | tee -a $LogFile
	done
fi


#######################
### 安装 depot_tools ###
#######################

echo "***************   安装 depot_tools.   ***************"
echo ""
if [ -d ./depot_tools/ ]
	then
	echo "./depot_tools/ already exists" | tee -a $LogFile
else
	echo "开始下载..." | tee -a $LogFile
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
	if [[ $? -eq 0 ]]; then
		echo "depot_tools 下载成功" | tee -a $LogFile
	else
		echo "depot_tools 下载失败，结束" | tee -a $LogFile
		exit 1;
	fi
fi

export PATH=`pwd`/depot_tools:"$PATH"
if [[ $? -eq 0 ]]; then
	echo "环境变量设置成功: $PATH" | tee -a $LogFile
	echo "这个 环境变量 更新并非永久的，只针对当前 Shell 回话" | tee -a $LogFile
else
	echo "Error：添加 depot_tools 环境变量, 结束" | tee -a $LogFile
	exit 1;
fi

#######################
##### 准备下载源码 ######
#######################

echo "#### 查询当前稳定版（Stable）版本号 ####" | tee -a $LogFile

# 获取当前的Chromium版本的CSV，并保存文件
curl https://omahaproxy.appspot.com/all -o releasestargets

# 返回当前 Mac 平台的 Chromium 稳定版本的版本号，使用逗号上切割字符串
# sample: 61.0.3163.100
TARGET=$(grep mac,stable, releasestargets | cut -d, -f3)
echo " Chromium 当前稳定版(Stable)号是: $TARGET" | tee -a $LogFile
rm releasestargets



#######################
##### 开始下载源码 ######
#######################

echo "开始下载 Chromium 源码，源码大小大概 8G 左右，下载时间因网速而议，请耐心等待" | tee -a $LogFile

# --no-history： 不需要历史记录
fetch --no-history chromium | tee -a $LogFile

cd src
SrcPath=`pwd`
echo "Chromium 源码下载完成"
echo "Chromium src path : $SrcPath"

# 切换到主分支
git checkout master
# 获取原创tag
git fetch --tags origin | tee -a $LogFile

# 同步源码
gclient sync --verbose --verbose --verbose --jobs 16 | tee -a $LogFile

# 获取当前稳定版的 tag
git fetch origin tag $TARGET | tee -a $LogFile
git checkout -b LovenseBrowser_$TARGET tags/$TARGET | tee -a $LogFile
gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16 | tee -a $LogFile

# build args.gn
touch "args.gn"
echo -e 'symbol_level=0\is_debug=false\nffmpeg_branding="Chrome"\enable_nacl=true\remove_webcore_debug_symbols=true\proprietary_codecs=true\enable_iterator_debugging=false\exclude_unwind_tables=true' > ./args.gn

gclient sync --verbose --verbose --verbose --with_branch_heads --jobs 16 | tee -a $LogFile

cd "$SrcPath" | tee -a $LogFile
echo "当前位置是: $SrcPath" | tee -a $LogFile
pwd | tee -a $LogFile

gn gen out/Release | tee -a $LogFile

ninja -C out/Release chrome | tee -a $LogFile

echo "编译成功" | tee -a $LogFile
echo "out/Release/Chromium.app/Contents/MacOS/Chromium" | tee -a $LogFile
