import Foundation
import WasmInterpreter
import Logging

public struct WapcHost {
    private let HOST_NS = "wapc"
    private let _vm: WasmInterpreter
    private var _state: ModuleState
    private let _logger = Logger(label: "WapcHost")

    init(module: [UInt8]) throws {
        _vm = try WasmInterpreter(stackSize: 1 * 120 * 1024, module: module)
        _state = ModuleState()
        
        if (try? _vm.addImportHandler(named: "__guest_response", namespace: HOST_NS, block: self.guestResponse)) == nil {
            _logger.warning("Guest did not import __guest_response")
        }
        if (try? _vm.addImportHandler(named: "__guest_error", namespace: HOST_NS, block: self.guestError)) == nil {
            _logger.warning("Guest did not import __guest_error")
        }
        if (try? _vm.addImportHandler(named: "__host_call", namespace: HOST_NS, block: self.hostCall)) == nil {
            _logger.warning("Guest did not import __host_call")
        }
        if (try? _vm.addImportHandler(named: "__host_response_len", namespace: HOST_NS, block: self.hostResponseLen)) == nil {
            _logger.warning("Guest did not import __host_response_len")
        }
        if (try? _vm.addImportHandler(named: "__host_response", namespace: HOST_NS, block: self.hostResponse)) == nil {
            _logger.warning("Guest did not import __host_response")
        }
        if (try? _vm.addImportHandler(named: "__host_error_len", namespace: HOST_NS, block: self.hostErrorLen)) == nil {
            _logger.warning("Guest did not import __host_error_len")
        }
        if (try? _vm.addImportHandler(named: "__host_error", namespace: HOST_NS, block: self.hostError)) == nil {
            _logger.warning("Guest did not import __host_error")
        }
        if (try? _vm.addImportHandler(named: "__console_log", namespace: HOST_NS, block: self.consoleLog)) == nil {
            _logger.warning("Guest did not import __console_log")
        }
        if (try? _vm.addImportHandler(named: "fd_write", namespace: "wasi_unstable", block: self.fd_write)) == nil {
            // Only required for TinyGo guests, supressing warning
        }
        
        // Call exported module initialization functions
        if (try? _vm.call("_start")) == nil {
            // Only present on TinyGo guests
            _logger.debug("_start function not exported")
        }
        if (try? _vm.call("wapc_init")) == nil {
            _logger.warning("wapc_init function not exported")
        }

        _logger.debug("Host initialized successfully")
    }
    
    private func guestRequest(opPtr: Int32, ptr: Int32) throws -> Void {
        _logger.info("Guest request invoked")
        if let inv = self._state.getGuestRequest() {
            try self._vm.writeToHeap(string: inv.op, byteOffset: Int(opPtr))
            try self._vm.writeToHeap(bytes: inv.msg, byteOffset: Int(ptr))
        } else {
            _logger.warning("No invocation registered")
        }
    }
    
    private func guestError(ptr: Int32, len: Int32) throws -> Void {
        let error = try self._vm.bytesFromHeap(byteOffset: Int(ptr), length: Int(len))
        if let string = String(bytes: error, encoding: .utf8) {
            _logger.info("Guest error: \(string)")
        } else {
            _logger.error("Failed to deserialize guest error, not utf8 bytes")
        }
    }
    
    private func guestResponse(ptr: Int32, len: Int32) throws -> Void {
        _logger.info("Guest response invoked")
    }
    
    private func hostCall(bdPtr: Int32, bdLen: Int32, nsPtr: Int32, nsLen: Int32, opPtr: Int32, opLen: Int32, ptr: Int32, len: Int32) throws -> Int32 {
        //TODO: implement an actual host call https://github.com/wapc/wapc-rust/blob/master/src/lib.rs#L247
        let binding = try self._vm.bytesFromHeap(byteOffset: Int(bdPtr), length: Int(bdLen))
        let namespace = try self._vm.bytesFromHeap(byteOffset: Int(nsPtr), length: Int(nsLen))
        let operation = try self._vm.bytesFromHeap(byteOffset: Int(opPtr), length: Int(opLen))
        let body = try self._vm.bytesFromHeap(byteOffset: Int(ptr), length: Int(len))
        if let bd = String(bytes: binding, encoding: .utf8), let ns = String(bytes: namespace, encoding: .utf8), let op = String(bytes: operation, encoding: .utf8), let vec = String(bytes: body, encoding: .utf8) {
            _logger.info("Guest invoked '\(bd)->\(ns):\(op) with a payload of \(vec)'")
            return 1
        } else {
            _logger.error("Failed to deserialize host call arguments")
            return 0
        }
    }
    
    private func hostResponse(ptr: Int32) throws {
        _logger.info("Host response invoked")
    }
    
    private func hostResponseLen() throws -> Int32 {
        _logger.info("Host response len invoked")
        return 0
    }
    
    private func hostError(ptr: Int32) throws {
        if let err = self._state.getHostError() {
            try self._vm.writeToHeap(string: err, byteOffset: Int(ptr))
        } else {
            _logger.error("No host error, not writing to heap")
        }
    }
    
    private func hostErrorLen() throws -> Int32 {
        if let err = self._state.getHostError() {
            return Int32(err.count)
        } else {
            return 0
        }
    }
    
    private func consoleLog(ptr: Int32, len: Int32) throws {
        let logBytes = try self._vm.bytesFromHeap(byteOffset: Int(ptr), length: Int(len))
        if let log = String(bytes: logBytes, encoding: .utf8) {
            _logger.info("Guest logged: \(log)")
        } else {
            _logger.error("Failed to deserialize guest error, not utf8 bytes")
        }
    }

    mutating func guestCall(op: String, bd: [UInt8]) throws -> Int {
        self._state.setGuestRequest(inv: Invocation(op: op, msg: bd))
        // Add the `__guest_request` operation here to capture the invocation in the closure
        guard (try? _vm.addImportHandler(named: "__guest_request", namespace: HOST_NS, block: self.guestRequest)) != nil else {
            _logger.error("Unable to add __guest_request import handler")
            return 0
        }
        
        // Return `1` for a successful call
        _logger.info("Trying to call")
        if (try? _vm.call("__guest_call", Int32(op.count), Int32(bd.count))) != nil {
            return 1
        } else {
            return 0
        }
    }
    
    // Required for TinyGo guests
    private func fd_write(fileDescriptor: Int32, iovsPtr: Int32, iovsLen: Int32, writtenPtr: Int32) throws -> Int32 {
        if fileDescriptor != 1 {
            _logger.error("Only writing to stdout (1) with fd_write is supported")
            return 0
        }
        var iovsCount = iovsLen
        var iovsPointer = iovsPtr
        var bytesWritten: Int32 = 0
        while iovsCount > 0 {
            iovsCount -= 1
            let base: Int32 = try _vm.valueFromHeap(byteOffset: Int(iovsPointer))
            let length: Int32 = try _vm.valueFromHeap(byteOffset: Int(iovsPointer + 4))
            let str = try _vm.bytesFromHeap(byteOffset: Int(base), length: Int(length))
            iovsPointer += 8
            bytesWritten += length
            print("\(String(bytes: str, encoding: .utf8)!)", terminator: "")
        }
        return 0
    }
}

struct Invocation {
    var op: String
    var msg: [UInt8]
    
    init(op: String, msg: [UInt8]) {
        self.op = op
        self.msg = msg
    }
}

struct ModuleState {
    private var guestRequest: Invocation?
    private var guestResponse: [UInt8]?
    private var hostResponse: [UInt8]?
    private var hostError: String?
    
    func getGuestRequest() -> Invocation? {
        return self.guestRequest
    }
    
    mutating func setGuestRequest(inv: Invocation) {
        self.guestRequest = inv
    }
    
    func getHostResponse() -> [UInt8]? {
        return self.hostResponse
    }
    
    mutating func setHostResponse(response: [UInt8]) {
        self.hostResponse = response
    }
    
    func getHostError() -> String? {
        return self.hostError
    }
    
    mutating func setHostError(error: String) {
        self.hostError = error
    }
}
