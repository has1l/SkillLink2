//
//  AppLog.swift
//  Llinks
//

import Foundation

struct AppLog {
    static func d(_ tag: String, _ msg: String) {
        #if DEBUG
        print("[\(tag)] \(msg)")
        #endif
    }

    static func i(_ tag: String, _ msg: String) {
        #if DEBUG
        print("[\(tag)] \(msg)")
        #endif
    }

    static func w(_ tag: String, _ msg: String) {
        #if DEBUG
        print("[\(tag)] \(msg)")
        #endif
    }

    static func e(_ tag: String, _ msg: String) {
        print("[\(tag)] \(msg)")
    }
}
