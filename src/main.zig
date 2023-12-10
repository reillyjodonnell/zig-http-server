const std = @import("std");
const socket = std.os.socket;

pub fn main() !void {
    try httpServer("127.0.0.1", 8080);
}

const server = std.http.Server;

fn httpServer(address: []const u8, port: u16) !void {
    var parsed_address = try std.net.Address.parseIp4(address, port);

    var server_socket = std.net.StreamServer.init(.{});
    defer server_socket.deinit();

    try server_socket.listen(parsed_address);

    while (true) {
        const client_socket = try server_socket.accept();

        // Handle client connection in a new thread or here directly
        // For example, read data from client_socket
        var buffer: [1024]u8 = undefined;
        const bytes_read = try client_socket.stream.read(&buffer);
        std.debug.print("Received: {s}\n", .{buffer[0..bytes_read]});

        try client_socket.stream.writeAll("Response from server!");
    }
}
