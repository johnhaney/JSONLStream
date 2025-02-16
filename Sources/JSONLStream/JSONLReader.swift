//
//  JSONLReader.swift
//  JSONLStream
//
//  Created by John Haney on 2/15/25.
//

import Foundation
import OSLog

fileprivate let logger = Logger(subsystem: "com.appsyoucanmake.JSONLStream", category: "JSONLReader")

public class JSONLReader {
    private let fileURL: URL
    
    public init?(fileURL: URL) {
        self.fileURL = fileURL
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            logger.error("File does not exist: \(fileURL.path)")
            return nil
        }
        
        if !FileManager.default.isReadableFile(atPath: fileURL.path) {
            logger.error("File is not readable: \(fileURL.path)")
            return nil
        }
    }
    
    public func allObjects<T: Decodable>() async -> [T] {
        var output: [T] = []
        for await object: T in self.objects() {
            output.append(object)
        }
        return output
    }

    public func allData() async -> [Data] {
        var output: [Data] = []
        for await data in self.dataLines() {
            output.append(data)
        }
        return output
    }

    public func objects<T: Decodable>() -> AsyncStream<T> {
        AsyncStream { continuation in
            let dataLines = self.dataLines()
            let decoder = JSONDecoder()
            Task {
                for await data in dataLines {
                    // try to decode each data blob
                    do {
                        let object = try decoder.decode(T.self, from: data)
                        // if it decodes, emit it
                        continuation.yield(object)
                        // after each emit, allow other work to happen
                        await Task.yield()
                    } catch {
                        // log decode problems at a trace level.
                        // maybe the user is expecting some lines to fail?
                        logger.trace("Did not decode data of length \(data.count) to expected type, error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    public func dataLines() -> AsyncStream<Data> {
        let fileURL = self.fileURL
        return AsyncStream { continuation in
            Task {
                do {
                    let fileHandle = try FileHandle(forReadingFrom: fileURL)
                    defer {
                        do {
                            try fileHandle.close()
                        } catch {
                            logger.error("Error closing file handle: \(error.localizedDescription)")
                        }
                    }
                    
                    let newline = Data("\n".utf8)
                    
                    var buffer = Data()
                    
                    // grab data in chunks
                    while let chunk = try? fileHandle.read(upToCount: 1024),
                          !chunk.isEmpty {
                        buffer.append(chunk)
                        
                        // divide the buffer as long as we keep finding \n characters
                        while let range = buffer.range(of: newline) {
                            let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
                            
                            // send out the data blob we found
                            if !lineData.isEmpty {
                                continuation.yield(lineData)
                                // allow other tasks to work after each data is sent out
                                await Task.yield()
                            }
                        }
                    }
                    
                    // last line
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }
                    
                    continuation.finish()
                } catch {
                    logger.error("Error reading data from file: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
}
