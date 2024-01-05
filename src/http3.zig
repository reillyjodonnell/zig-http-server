const std = @import("std");
const expect = std.testing.expect;
pub fn main() !void {}

test "HTTP3 server" {
    var server = Http3Server{
        .port = 3000,
    };

    // Start the server
    _ = try server.start();

    const udp_socket = std.os.SOCK.DGRAM;

    // Give the server a moment to start up
    const sleep_duration = std.time.milliseconds(100);
    std.testing.allocator.sleep(sleep_duration);

    // Simulate a client request
    const address = std.net.Address.initIp4(std.net.IPv4Address.any, server.port);
    const client = std.net.StreamSocket.init(.{});
    try client.connect(address);

    try expect()

    

    client.close();

    // the server should be listening
    // how do we test from the perspective of the user?
}

const Http3Server = struct {
    port: u32,

    fn start(self: *Http3Server) !void {
        _ = self;
    }
};
