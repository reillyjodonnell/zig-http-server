const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Server address and port
    const address = try std.net.Address.parseIp4("127.0.0.1", 8080);

    // Create a TCP client socket
    const client_socket = try std.net.tcpConnectToAddress(address);
    defer client_socket.close();

    // Get command line arguments
    const args = std.os.argv;
    if (args.len < 2) {
        std.debug.print("Usage: send <message>\n", .{});
        return;
    }
    var message = args[1];

    // Calculate the length of the string (excluding the null-terminator)
    const length = std.mem.len(message);

    // Create a slice from the pointer
    const slice = message[0..length];

    // Send a message
    try client_socket.writeAll(slice);
    var buffer: [1024]u8 = undefined;

    const bytes_read = try client_socket.read(&buffer);
    std.debug.print("Received: {s}\n", .{buffer[0..bytes_read]});
}
