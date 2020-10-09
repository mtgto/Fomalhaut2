import Cocoa

enum BookAccessibleError: Error {
  case brokenFile
}

protocol BookAccessible {
  func pageCount() -> Int

  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, Error>) -> Void)
}
