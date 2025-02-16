//
//  JSONLWriter.swift
//  JSONLStream
//
//  Created by John Haney on 2/15/25.
//

import Foundation
import OSLog

fileprivate let logger = Logger(subsystem: "com.appsyoucanmake.JSONLStream", category: "JSONLWriter")

public class JSONLWriter {
    private let fileHandle: FileHandle
    private let fileURL: URL

    public init?(fileURL: URL, appendIfExists: Bool = true) {
        self.fileURL = fileURL

        // Ensure file exists, or create it
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        } else if !appendIfExists {
            return nil
        }

        // Try to open file for appending
        do {
            self.fileHandle = try FileHandle(forWritingTo: fileURL)
            self.fileHandle.seekToEndOfFile() // Move to end for appending
        } catch {
            logger.error("Failed to open file: \(error)")
            return nil
        }
    }

    /// Writes a single JSON object (encoded as `Data`) to the file
    public func write(jsonData: Data) {
        do {
            try fileHandle.write(contentsOf: jsonData)
            try fileHandle.write(contentsOf: Data("\n".utf8)) // Add newline for JSONL format
        } catch {
            logger.error("Error writing to file: \(error)")
        }
    }

    /// Writes a single `Encodable` object to the file as JSONL
    public func write<T: Encodable>(jsonObject: T) {
        do {
            let jsonData = try JSONEncoder().encode(jsonObject)
            write(jsonData: jsonData)
        } catch {
            logger.error("Error encoding object: \(error)")
        }
    }

    /// Closes the file handle
    public func close() {
        do {
            try fileHandle.close()
        } catch {
            logger.error("Error closing file: \(error)")
        }
    }

    /// Automatically closes the file when the object is deallocated
    deinit {
        close()
    }
}
