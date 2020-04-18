//
//  LogHelper.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 19/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import CocoaLumberjack
import RxCocoa


class LogHelper {

    private static let starCount = 90
    static var bannerLine = String(repeating: "*", count: starCount)
    static var shared = LogHelper()

    private var fileLogger: DDFileLogger!
    private var mainConsoleLogger: DDOSLogger!
    private var networkSubsystemConsoleLogger: DDOSLogger!

    var networkLog: DDLog!

    fileprivate func disableStandardRxCocoaNetworkLogging() {
        Logging.URLRequests = { _ in false }
    }

    fileprivate func createLoggingSubsystems(_ bundle: Bundle) {
        self.mainConsoleLogger = DDOSLogger(subsystem: bundle.bundleIdentifier, category: "Main")
        self.networkSubsystemConsoleLogger = DDOSLogger(subsystem: bundle.bundleIdentifier, category: "Network")
        self.fileLogger = DDFileLogger() // File Logger
        self.fileLogger.rollingFrequency = 60 * 60 * 24 * 3 // 3 days
        self.fileLogger.logFileManager.maximumNumberOfLogFiles = 7
    }

    fileprivate func configureMainLogger() {
        DDLog.add(self.mainConsoleLogger)
        DDLog.add(fileLogger)
    }

    fileprivate func createNetworkLogger() {
        self.networkLog = DDLog()
        self.networkLog.add(self.fileLogger)
        self.networkLog.add(self.networkSubsystemConsoleLogger)
    }

    private init() {
        let bundle: Bundle = .main
        createLoggingSubsystems(bundle)

        configureMainLogger()
        createNetworkLogger()

        self.disableStandardRxCocoaNetworkLogging()
        let filePath = fileLogger.currentLogFileInfo?.filePath
        DDLogDebug("Loger initalized, logging to file: \(filePath ?? "💩")")
    }

    static func fancyBanner(forMessage msg: String) {

        let msgWithSpacesCount = msg.count + 2
        let leftSpaceCount = Self.starCount - msgWithSpacesCount
        let prefixStarsCount = leftSpaceCount / 2
        let postfixStarsCount = prefixStarsCount + leftSpaceCount % 2
        let prefixStars = String(repeating: "*", count: prefixStarsCount)
        let postfixStars = String(repeating: "*", count: postfixStarsCount)

        let starsTop = Self.bannerLine

        DDLogInfo(starsTop)
        DDLogInfo(prefixStars + " " + msg + " " + postfixStars)
        DDLogInfo(starsTop)
    }
}

extension LogHelper {
    public func convertResponseToString(_ response: URLResponse?, _ data: Data?, _ error: NSError? = nil, _ interval: TimeInterval) -> String {
        let ms = Int(interval * 1000)

        if let response = response as? HTTPURLResponse {
            let headersString = Self.stringify(json: response.allHeaderFields, prettyPrinted: true)
            let bodyString = (data != nil) ? (String(data: data!, encoding: .utf8) ?? "No body") : "No body"
            var initialStatus: String
            if 200 ..< 300 ~= response.statusCode {
                initialStatus = "Success (\(ms)ms):"
            }
            else {
                initialStatus = "Failure (\(ms)ms):"
            }
            return "\(initialStatus) \nStatus: \(response.statusCode) \nHeaders: \(headersString)\nBody: \(bodyString)"
        }

        if let error = error {
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                return "Canceled (\(ms)ms)"
            }
            return "Failure (\(ms)ms): NSError > \(error)"
        }

        return "<Unhandled response from server>"
    }

    static func stringify(json: Any, prettyPrinted: Bool = false) -> String {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
          options = JSONSerialization.WritingOptions.prettyPrinted
        }

        do {
          let data = try JSONSerialization.data(withJSONObject: json, options: options)
          if let string = String(data: data, encoding: String.Encoding.utf8) {
            return string
          }
        } catch {
          print(error)
        }

        return ""
    }
}
