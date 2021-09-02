//
//  Process+Extensions.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 8/24/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public extension Process {
    enum ProcessError: Error {
        case withError(Error)
        case stdError(String)
        case commandNotFound(String)
    }
    struct ProcessData {
        public var output = Data()
        public var error = Data()
        
        public var outputString: String {
            String(data: output, encoding: .utf8) ?? "unknown"
        }
        
        public var errorString: String {
            String(data: error, encoding: .utf8) ?? "unknown"
        }
        
//        if ([errorData length]) {
//            // this task failed, we should return nil and raise
//            //
//            NSString*  errorString = @"";
//
//            @try {
//                errorString = [[NSString alloc] initWithData:errorData encoding:NSASCIIStringEncoding];
//            } @catch (NSException* exception) {
//                IDDLogError(self, _cmd, @"Exception: %@", [exception description]);
//                IDDLogError(self, _cmd, @"(%@)", [exception backtrace]);
//            }
//
//            NSString* separator = @"\n\t *iddError*   ";
//            NSMutableArray* tokens = [[NSMutableArray alloc] initWithArray:[errorString componentsSeparatedByString:@"\n"]];
//
//            [tokens removeObject:@""];
//            IDDLogError(self, _cmd, @"task: '%@' arguments: '%@' errors: %@%@", command, [arguments componentsJoinedByString:@", "], separator, [tokens componentsJoinedByString:separator]);
//            *errors = errorData;
//        }
    }
    
    /// Initalize a process with the command and some args.
    ///
    /// - Parameters:
    ///   - launchPath: Sets the receiver’s executable.
    ///   - arguments: Sets the command arguments that should be used to launch the executable.
    convenience init(_ launchPath: String, _ arguments: [String] = []) {
        self.init()
        if #available(macOS 10.13, *) {
            self.executableURL = URL(fileURLWithPath: launchPath)
        } else {
            self.launchPath = launchPath
        }
        self.arguments = arguments
        self.currentDirectoryPath = NSHomeDirectory()
        self.environment = {
            var rv = ProcessInfo.processInfo.environment
            
            // http://www.promac.ru/book/Sams%20-%20Cocoa%20Programming/0672322307_ch24lev1sec2.html
            // all sort of problems with using an NSTask
            // if it leaks file handles than we are in trouble
            // it will fail afterwards with a stupid 'attempt to insert nil value'
            // Klajd Deda, October 28, 2008
            // https://stackoverflow.com/questions/55275078/objective-c-nstask-buffer-limitation
            // Klajd Deda, November 30, 2019
            //
            rv["NSUnbufferedIO"] = "YES"
            return rv
        }()
    }

    /**
     This code will fail due to security protections in the mac
     Make sure we hasFullDiskAccess returns true
     */
    func fetchData(
        timeOut timeOutInSeconds: Double = 0
    ) -> Result<ProcessData, ProcessError> {
        let command: String = {
            if #available(macOS 10.13, *) {
                return self.executableURL?.path ?? ""
            }
            return self.launchPath ?? ""
        }()
        let logger = Log4swift[Self]

        guard FileManager.default.hasFullDiskAccess
        else {
            logger.error("""
                    
                        Please enableFullDisk access for this app
                          Apple -> System Preferences -> Security & Privacy -> Full Disk Access
                          and drop this path into it \(Bundle.main.executablePath ?? "executablePath should be defined")
                    """)
            return .failure(.commandNotFound(command)) }
        guard URL(fileURLWithPath: command).fileExist
        else { return .failure(.commandNotFound(command)) }

        let semaphore = DispatchSemaphore(value: 0)
        var processData = ProcessData()
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()

        self.standardOutput = standardOutputPipe
        self.standardError = standardErrorPipe

        // if (IDDLogDebugLevel(self)) IDDLogDebug(self, _cmd, @"%@ \"%@\"", command, [arguments componentsJoinedByString:@"\" \""]);
        let taskDescription = "\(command + " " + (self.arguments ?? []).joined(separator: " "))"
        logger.info("\(taskDescription)")
        if timeOutInSeconds > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(timeOutInSeconds * 1_000))) {
                // this will capture us but that's ok
                guard self.isRunning
                else {
                    logger.info("'\(taskDescription)' is not running any longer")
                    return
                }
                logger.info("'\(taskDescription)' will be terminated immediately")
                self.terminate()
                Process.killProcess(pid: Int(self.processIdentifier))
                logger.info("'\(taskDescription)' should be terminated now.")
                logger.info("'\(taskDescription)' self.isRunning: \(self.isRunning ? "YES" : "NO")")
            }
        }
        
        standardOutputPipe.fileHandleForReading.readabilityHandler = { (file: FileHandle) in
            let data = file.availableData
            logger.debug("appending stdOut: '\(data.count) bytes'")
            logger.debug("appending stdOut: '\(String(data: data, encoding: .utf8) ?? "unknown") bytes'")
            processData.output.append(data)
        }
        standardErrorPipe.fileHandleForReading.readabilityHandler = { (file: FileHandle) in
            let data = file.availableData
            logger.debug("appending stdError: '\(data.count) bytes'")
            logger.debug("appending stdError: '\(String(data: data, encoding: .utf8) ?? "unknown") bytes'")
            processData.error.append(data)
        }

        self.terminationHandler = { (process: Process) in
            standardOutputPipe.fileHandleForReading.readabilityHandler = nil
            standardErrorPipe.fileHandleForReading.readabilityHandler = nil

            semaphore.signal()
        }

        if #available(macOS 10.13, *) {
            do {
                try self.run()
                _ = semaphore.wait(timeout: .now() + .milliseconds(Int(timeOutInSeconds * 1_000)))
                
                // fix from https://github.com/lroathe/PipeTest/blob/master/PipeTest/main.m
                // [task waitUntilExit]; // we don't do this or we would dead lock !!!
            } catch {
                logger.error("'\(taskDescription)' error: \(error)")
            }
        } else {
            // deprecated ...
            self.launch()
            _ = semaphore.wait(timeout: .now() + .milliseconds(Int(timeOutInSeconds * 1_000)))
        }
        
        if self.isRunning {
            // we want our tasks to complete normally.
            // we should run out of stuff to read if the task has ended.
            // or vice versa, since we are piped into the task
            // so we should not come here
            // however we seem to hit this spot some times !!!
            // but we will give em a second to terminate
            //
            var waitForTermination = 0
            let maxWait = 2 * 3600
            // maximum 2 hour ...
            // if it takes longer than that kill it
            //
            
            logger.debug("Waiting for task '\(command)' to terminate")
            while self.isRunning
                    && waitForTermination < maxWait {
                Thread.sleep(forTimeInterval: 0.1)
                waitForTermination += 1
            }
            if self.isRunning {
                // the task should be terminated by now, but in case it is not we try to force termination
                // Klajd Deda, October 28, 2008
                //
                logger.error("We have taken longer than the maxWait of '\(maxWait) seconds' and will terminate this task now.")
                logger.error("The task '\(command)' is still running !!!")
                self.terminate()
            }
        }
//        while ((buffer = [[task.standardError fileHandleForReading] availableData]) && [buffer length]) {
//            [errorData appendData:buffer];
//        }
//        while ((buffer = [[task.standardOutput fileHandleForReading] availableData]) && [buffer length]) {
//            [rv appendData:buffer];
//        }
        
        standardOutputPipe.fileHandleForReading.closeFile()
        standardOutputPipe.fileHandleForWriting.closeFile()
        standardErrorPipe.fileHandleForReading.closeFile()
        standardErrorPipe.fileHandleForWriting.closeFile()
        return .success(processData)
    }
    
    /**
     Convenience
     */
    static func fetchData(
        task: String,
        arguments: [String],
        timeOut timeOutInSeconds: Double = 0
    ) -> Result<ProcessData, ProcessError> {
        Process(task, arguments).fetchData(timeOut: timeOutInSeconds)
    }

    static func fetchString(
        task: String,
        arguments: [String],
        timeOut timeOutInSeconds: Double = 0
    ) -> String {
        let result = Process(task, arguments)
            .fetchData(timeOut: timeOutInSeconds)
            .map { $0.outputString }
        
        return (try? result.get()) ?? ""
    }
}
