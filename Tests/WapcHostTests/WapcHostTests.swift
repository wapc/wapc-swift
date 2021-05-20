    import XCTest
    @testable import WapcHost

    final class WapcHostTests: XCTestCase {
        func testCanLoadWasm() {
            XCTAssertNotNil(loadHello())
        }
        
        func testCanCallGuestCall() throws {
            if var wapcHost = loadHello(){
                let op = "wapc:sample!Hello"
                let bd: [UInt8] = Array("this is a test".utf8);
                let callResult = try wapcHost.__guest_call(op: op, bd: bd);
                XCTAssertEqual(callResult, 1)
            } else {
                XCTAssert(false)
            }
        }
        
        func loadHello() -> WapcHost? {
            if let host = try? WapcHost(module: loadModule(module: "/Users/btownsend/github.com/wapc/WapcHost/Tests/WapcHostTests/hello.wasm")) {
                return host
            } else {
                return nil
            }
        }
        
        func loadModule(module: String) -> [UInt8] {
            print("loading module from ", module)

            var bytes = [UInt8]()
            if let data = NSData(contentsOfFile: module) {
                var buffer = [UInt8](repeating: 0, count: data.length)
                data.getBytes(&buffer, length: data.length)
                bytes = buffer
            }
            return bytes
        }

    }
