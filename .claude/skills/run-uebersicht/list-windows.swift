// Lists on-screen windows, optionally filtered to one owner PID. Übersicht
// draws borderless windows at desktop-icon window levels, so a full-screen
// `screencapture -x` only shows whatever normal app is in front of them.
// This lists window IDs so you can grab one directly with
// `screencapture -l<id>`, which renders that window's content regardless
// of what's on top of it.
//
// Usage: swift list-windows.swift [owner-pid]
import CoreGraphics
import Foundation

let pidFilter = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) : nil
let options = CGWindowListOption(arrayLiteral: .optionAll)
guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: AnyObject]] else {
    exit(1)
}
for w in list {
    let ownerPID = w[kCGWindowOwnerPID as String] as? Int ?? -1
    if let pidFilter, ownerPID != pidFilter { continue }
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    if pidFilter == nil && !owner.contains("ersicht") { continue }
    let num = w[kCGWindowNumber as String] as? Int ?? -1
    let layer = w[kCGWindowLayer as String] as? Int ?? -1
    let bounds = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    print("\(num) pid=\(ownerPID) owner=\(owner) layer=\(layer) bounds=\(bounds)")
}
