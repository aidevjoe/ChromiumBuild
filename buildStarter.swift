#!/usr/bin/swift
// Chromium 插件打包参考链接 http://www.cnblogs.com/honker/p/6397591.html

import Foundation

enum Options: String {
    case help = "--help"
}

// MARK - Chromium 源代码路径
// 编译文件夹路径
let buildName = "out/Lovense"
let chromiumSrcPath = "/Users/danxiao/Documents/chromium/chromium/src/"
let chromiumPlistPath = chromiumSrcPath + buildName + "/Chromium.app/Contents/Info.plist"
let chromiumVersionInfoValuesPath = chromiumSrcPath + buildName + "/gen/components/version_info/version_info_values.h"
let lovenseBrowserPlistPath = "/Users/danxiao/Desktop/LovenseBrowser/LovenseBrowser/Info.plist"
let chromiumProductVersion = "61.0.3163.100"

/// 插件资源存放目录
let pluginDestinationPath = chromiumSrcPath + "chrome/browser/resources"

/// 插件资源键值对绑定的文件
let ComponentExtensionResourcesFilePath = chromiumSrcPath + "chrome/browser/resources/component_extension_resources.grd"


class Execution {
    @discardableResult
    class func execute(path: String, arguments: String...) -> (status: Int, output: String) {
        return execute(path: path, arguments: arguments)
    }
    
    @discardableResult
    class func execute(path: String, arguments: [String]? = nil) -> (Int, String) {
        let process = Process()
        process.launchPath = path
        if let `arguments` = arguments {
            process.arguments = arguments
        }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        print(output ?? "")
        return (Int(process.terminationStatus), output ?? "")
    }
}

func getUserInput() -> String? {
    let input = FileHandle.standardInput
    return String(data: input.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// 替换 插件资源键值对绑定的文件
///
/// - Parameter content: XML键值对内容，其他内容模版提供， 如果原内容修改，需要更新模版文件（注意保留Key ： {$content} ）
/// - Returns: 成功 or 失败
@discardableResult
func replaceComponentExtensionResourcesFile(content: String) -> Bool {
    print("----------------")
    let path = Execution.execute(path: "/bin/pwd").1
    
    let templatePath = path.trimmingCharacters(in: .whitespacesAndNewlines).appending("/template.xml")
    guard let templateString = try? String(contentsOfFile: templatePath) else {
        print("[Error]: 无法加载模版文件！")
        exit(1)
    }
    
    let grdString = templateString.replacingOccurrences(of: "{$content}", with: content)
    
    do {
        //        try grdString.write(toFile: "/Users/danxiao/Desktop/FileXML.xml", atomically: true, encoding: .utf8)
        try grdString.write(toFile: ComponentExtensionResourcesFilePath, atomically: true, encoding: .utf8)
        print("[Success]: component_extension_resources.grd 替换成功 \n \(ComponentExtensionResourcesFilePath)")
        return true
    } catch {
        print(error)
        return false
    }
}


/// 默认插件路径
var rootPath = "/Users/danxiao/Desktop/lovense_cam"
let parentDir = (rootPath as NSString).lastPathComponent


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


print("请输入Chrome插件资源文件夹路径[Default：\(rootPath)]:")

let pluginPath = getUserInput()
if pluginPath != nil && !pluginPath!.isEmpty {
    rootPath = pluginPath!
}

print("文件路径：\(rootPath)")
Execution.execute(path: "/bin/rm", arguments: "-rf", (pluginDestinationPath as NSString).appendingPathComponent(parentDir))
Execution.execute(path: "/bin/cp", arguments: "-rf", rootPath, pluginDestinationPath)

convert2XML(rootDir: rootPath)

guard replaceComponentExtensionResourcesFile(content: xmlString) else {
    print("文件替换失败，请手动替换")
    let writeFilePath = "/Users/danxiao/Desktop/FileXML.xml"
    try? xmlString.write(toFile: writeFilePath, atomically: true, encoding: .utf8)
    print("XML转换成功，文件已写入到 ：", writeFilePath)
    exit(1)
}

print("准备打包App...")

print("请输入版本号:")
guard let newVersion = getUserInput() else {
    print("版本号输入有误")
    exit(1)
}

try? newVersion.write(toFile: "./Version", atomically: true, encoding: .utf8)

func changeVersion(path: String) {
    
    guard let dict = NSMutableDictionary(contentsOfFile: path) else {
        print("\(path) 文件读取失败")
        exit(1)
    }
    let oldVersion = dict["CFBundleShortVersionString"] as? String
    print("正在修改版本号 [Current version:\(oldVersion ?? "Unknow")]:")
    
    // 版本号
    dict["CFBundleShortVersionString"] = newVersion
    // 内部版本号
    dict["CFBundleVersion"] = newVersion
    
    if let versionValues = try? String(contentsOfFile: chromiumVersionInfoValuesPath),
        let `oldVersion` = oldVersion,
        oldVersion != newVersion {
        let isContains = versionValues.contains(chromiumProductVersion)
        let result = versionValues.replacingOccurrences(of: isContains ? chromiumProductVersion : oldVersion, with: newVersion)
        try? result.write(toFile: chromiumVersionInfoValuesPath, atomically: true, encoding: .utf8)
        print(result)
    }
    
    if dict.write(toFile: path, atomically: true) {
        print("版本号修改成功 Version: \(newVersion)")
    } else {
        print("版本号修改失败")
        exit(1)
    }
}

changeVersion(path: lovenseBrowserPlistPath)
changeVersion(path: chromiumPlistPath)
//
//// Chromium 源代码路径
//let chromiumSrcPath = "/Users/danxiao/Documents/chromium/chromium/src/"
//
//// 编译文件夹路径
//let buildName = "out/Release"
//
//// Chromium.app 文件夹路径
//let chromiumPath = chromiumSrcPath + buildName + "/Chromium.app"
//
//// Chromium 编译工具路径
//let depotToolsPath = "/Users/danxiao/Documents/chromium/depot_tools"
//
//let autoBuildPath = "/Users/danxiao/Desktop/LovenseBrowser/autoBuild"
//
//Execution.execute(path: "/bin/rm", arguments: "-fr", chromiumPath)
//Execution.execute(path: "/usr/bin/cd", arguments: chromiumSrcPath)
//Execution.execute(path: "/bin/pwd")
//
//guard Execution.execute(path: depotToolsPath + "/ninja", arguments: "-C", chromiumSrcPath + buildName, "chrome").status == 0 else {
//    print("编译失败")
//    exit(1)
//}
//
//print("** Chrome 编译成功 **")
//
//print("正在打包启动器...")
//Execution.execute(path: "/bin/rm", arguments: "-fr", autoBuildPath)
//
////let xcodebuildResult =
//    Execution.execute(path: "/usr/bin/xcodebuild",
//                  arguments: "-workspace",
//                  "/Users/danxiao/Desktop/LovenseBrowser/LovenseBrowser.xcodeproj/project.xcworkspace",
//                  "-scheme",
//                  "LovenseBrowser",
//                  "-configuration",
//                  "Release",
//                  "clean",
//                  "build",
//                  "-derivedDataPath",
//                  autoBuildPath
//)
//if xcodebuildResult.status == 1 {
//    print("启动器打包失败")
//    exit(1)
//}
//
//print("启动器打包成功")
//
//
