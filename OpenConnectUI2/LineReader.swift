import Foundation

public class LineReader {

  fileprivate let file: UnsafeMutablePointer<FILE>!

  init?(fileHandle: FileHandle) {
    file = fdopen(fileHandle.fileDescriptor, "r")
  }

  public var nextLine: String? {
    var line: UnsafeMutablePointer<CChar>?
    var linecap: Int = 0
    defer { free(line) }
    return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
  }

  deinit {
    fclose(file)
  }
}

extension LineReader: Sequence {
  public func makeIterator() -> AnyIterator<String> {
    AnyIterator<String> {
      self.nextLine
    }
  }
}
