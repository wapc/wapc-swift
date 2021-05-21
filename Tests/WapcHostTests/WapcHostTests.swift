    import XCTest
    @testable import WapcHost

    final class WapcHostTests: XCTestCase {
        override func setUp() {
            self.continueAfterFailure = false
        }
        
        func testGuestCallRust() throws {
            let host = createHost("hello")
            XCTAssertNotNil(host)
            var wapcHost = host!
            let op = "wapc:sample!Hello"
            let bd: [UInt8] = Array("this is a test".utf8)
            let callResult = try wapcHost.guestCall(op: op, bd: bd)
            XCTAssertEqual(callResult, 1)
        }
        
        func testStressCallingRust() throws {
            let host = createHost("hello")
            XCTAssertNotNil(host)
            var wapcHost = host!
            let op = "wapc:sample!Hello"
            let bd: [UInt8] = Array("this is a test".utf8)
            for _ in 0...5000 {
                let callResult = try wapcHost.guestCall(op: op, bd: bd)
                XCTAssertEqual(callResult, 1)
            }
        }
        
        func testGuestCallAssemblyScript() throws {
            let host = createHost("hello_as")
            XCTAssertNotNil(host)
            var wapcHost = host!
            let op = "hello"
            let bd: [UInt8] = Array("this is a test".utf8);
            let callResult = try wapcHost.guestCall(op: op, bd: bd);
            XCTAssertEqual(callResult, 1)
        }
        
        func testGuestCallTinyGo() throws {
            let host = createHost("hello_tinygo")
            XCTAssertNotNil(host)
            var wapcHost = host!
            let op = "hello"
            let bd: [UInt8] = Array("this is a test".utf8);
            let callResult = try wapcHost.guestCall(op: op, bd: bd);
            XCTAssertEqual(callResult, 1)
        }
        
        func testGuestCallZig() throws {
            let host = createHost("hello_zig")
            XCTAssertNotNil(host)
            var wapcHost = host!
            let op = "hello"
            let bd: [UInt8] = Array("this is a test".utf8);
            let callResult = try wapcHost.guestCall(op: op, bd: bd);
            XCTAssertEqual(callResult, 1)
        }
        
        
        private func createHost(_ module: String) -> WapcHost? {
            if let host = try? WapcHost(module: loadModule(module: module)) {
                return host
            } else {
                return nil
            }
        }

        private func loadModule(module: String) -> [UInt8] {
            if let helloWasm = Bundle.module.path(forResource: module, ofType: "wasm") {
                var bytes = [UInt8]()
                if let data = NSData(contentsOfFile: helloWasm) {
                    var buffer = [UInt8](repeating: 0, count: data.length)
                    data.getBytes(&buffer, length: data.length)
                    bytes = buffer
                }
                return bytes
            } else {
                print("Unable to load module: ", module)
            }

            return []
        }

    }
