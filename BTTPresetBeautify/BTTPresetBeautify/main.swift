//
//  main.swift
//  BTTPresetBeautify
//
//  Created by BB9z on 2018/12/15.
//  Copyright © 2018 B9Software. All rights reserved.
//

import Foundation

extension Array {
    /// 安全的获取元素，index 超出范围返回 nil
    func rf_object(at index: Int) -> Element? {
        if 0..<count ~= index {
            return self[index]
        }
        return nil
    }
}

/// 打印帮助
func printUsage() {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    
    print("""
BTTPresetBeautify - Beautify BetterTouchTool preset file

Usage: \(executableName) file [output]
""")
}

/// 输出错误信息到 stderr
func log(error: String) {
    fputs("\(error)\n", stderr)
}

guard CommandLine.argc > 1 else {
    printUsage()
    exit(EXIT_SUCCESS)
}

guard let inputFile: String = CommandLine.arguments.rf_object(at: 1) else {
    log(error: "Bad input file argument.")
    exit(EXIT_FAILURE)
}
guard FileManager.default.isReadableFile(atPath: inputFile) else {
    log(error: "Cannot read file at \(inputFile).")
    exit(EXIT_FAILURE)
}

func LoadPreset(_ file: URL) -> BTTPreset {
    do {
        let inputData = try Data(contentsOf: file)
        let json = try JSONSerialization.jsonObject(with: inputData, options: [])
        guard let obj = json as? [String: Any] else {
            log(error: "Bad preset data.")
            exit(EXIT_FAILURE)
        }
        return BTTPreset(json: obj)
    } catch {
        log(error: error.localizedDescription)
        exit(EXIT_FAILURE)
    }
}

func MakeOutputURL(inputURL: URL, output: String?) -> URL {
    guard let output = output else {
        return inputURL
    }
    let url = URL(fileURLWithPath: output)
    if output.hasSuffix("/") {
        return url.appendingPathComponent(inputURL.lastPathComponent)
    }
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
        return url.appendingPathComponent(inputURL.lastPathComponent)
    }
    return url
}

let inputURL = URL(fileURLWithPath: inputFile)
let preset = LoadPreset(inputURL)

preset.beautify()
do {
    let url = MakeOutputURL(inputURL: inputURL, output: CommandLine.arguments.rf_object(at: 2))
    try preset.write(toFile: url)
    print("The preset has been successfully written to \(url.path)")
} catch {
    log(error: "Preset save fail:")
    log(error: error.localizedDescription)
    exit(EXIT_FAILURE)
}

