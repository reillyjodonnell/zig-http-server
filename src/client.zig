const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Server address and port
    const address = try std.net.Address.parseIp4("127.0.0.1", 8080);

    // Create a TCP client socket
    const client_socket = try std.net.tcpConnectToAddress(address);
    defer client_socket.close();

    // Connect to the server

    // Send a message
    const message = "Hello, Zig Server!";
    try client_socket.writeAll(message);

    std.debug.print("SENT", .{});

    // Optionally, receive a response (if your server sends a response)
    // var response: [1024]u8 = undefined;
    // const bytes_read = try connection.stream.read(&response);
    // std.debug.print("Received: {s}\n", .{response[0..bytes_read]});
}
