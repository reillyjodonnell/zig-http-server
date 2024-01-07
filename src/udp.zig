const std = @import("std");
const expect = std.testing.expect;
const net = std.net;
const os = std.os;

test "create a socket" {
    var socket = try Socket.init("127.0.0.1", 3000);
    try expect(@TypeOf(socket.socket) == std.os.socket_t);
}

const Socket = struct {
    address: std.net.Address,
    socket: std.os.socket_t,

    fn init(ip: []const u8, port: u16) !Socket {
        const parsed_address = try std.net.Address.parseIp4(ip, port);
        const sock = try std.os.socket(std.os.AF.INET, std.os.SOCK.DGRAM, 0);
        errdefer os.closeSocket(sock);
        return Socket{ .address = parsed_address, .socket = sock };
    }

    fn bind(self: *Socket) !void {
        try os.bind(self.socket, &self.address.any, self.address.getOsSockLen());
    }

    fn listen(self: *Socket) !void {
        var buffer: [1024]u8 = undefined; // Define a buffer for incoming data

        while (true) {
            const received_bytes = try std.os.recvfrom(self.socket, buffer[0..], 0, null, null); // Correct use of buffer
            std.debug.print("Received {d} bytes: {s}\n", .{ received_bytes, buffer[0..received_bytes] }); // Properly print received data
        }
    }
};
