# waPC Swift Host

This is the (incomplete) Swift implementation of the **waPC** standard for WebAssembly host runtimes.

## Usage
Refer to the [Tests](./Tests/WapcHostTests/WapcHostTests.swift) for usage examples with the included "hello" sample modules.

### Note
This library is not fully implemented yet. The following is an incomplete list of functionality this library requires:
- [x] Run a WebAssembly Module originally written in Rust
- [x] Run a WebAssembly Module originally written in TinyGo
- [x] Run a WebAssembly Module originally written in Zig
- [ ] Run a WebAssembly Module originally written in AssemblyScript (Does not work)
- [ ] Run a WebAssembly Module originally written in Swift (Untested)
- [ ] Provide host call upon WapcHost initialization instead of predefined log implementation
- [x] Implement `__console_log`    Host    Guest calls host to log to host’s stdout (if permitted)
- [x] Implement `__host_call`    Host    Guest calls to request the host perform an operation
- [ ] Implement `__host_response`    Host    Tells the host the pointer address at which to store its response
- [ ] Implement `__host_response_len`    Host    Returns the length of the host’s response
- [x] Implement `__host_error`    Host    Tells the host the pointer address at which to store its error blob
- [x] Implement `__host_error_len`    Host    Returns the length of the host error blob
- [ ] Implement `__guest_response`    Host    Called by the guest to set the pointer and length of the guest’s response blob
- [x] Implement `__guest_error`    Host    Called by the guest to set the pointer and length of the guest’s error blob
- [x] Implement `__guest_request`    Host    Called by the guest to tell the host the pointer addresses of where to store the request’s operation (string) and request payload (blob) values.
- [x] Implement `__guest_call`    Guest    Invoked by the host to tell the guest to begin processing a function call. The guest will then retrieve the parameters and set response values via host calls.
- [ ] Resolve state capturing that happens when registering handler functions, specifically with `__guest_request` that necessitates us to call `addImportHandler` only after the `__guest_call` function is called.
