const std = @import("std");
const socket = std.os.socket;
const test_allocator = std.testing.allocator;

const expect = std.testing.expect;

fn spawnServerOnSeparateThread() !void {
    var http_server = try HttpServer.init("127.0.0.1", 3000);
    try http_server.listen();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var server_thread = try std.Thread.spawn(.{ .allocator = allocator }, spawnServerOnSeparateThread, .{});
    defer server_thread.join();
}

fn spawnClientOnSeparateThread() !void {
    // Attempt to connect to the server
    const client_address = try std.net.Address.parseIp4("127.0.0.1", 3000);
    const client_socket = try std.net.tcpConnectToAddress(client_address);
    const message: []const u8 = "close";
    try client_socket.writeAll(message[0..]);
    defer client_socket.close(); // Ensure the socket is closed after the test
}

// test "http server" {
//     var client_thread = try std.Thread.spawn(.{ .allocator = test_allocator }, spawnClientOnSeparateThread, .{});
//     var server_thread = try std.Thread.spawn(.{ .allocator = test_allocator }, spawnServerOnSeparateThread, .{});

//     defer client_thread.join();
//     defer server_thread.join();
//     // If the code reaches here without an error, the connection was successful
//     std.debug.print("Successfully connected to the server.\n", .{});
// }

const HttpServer = struct {
    address: []const u8,
    port: u16,
    parsed_address: std.net.Address,

    fn init(address: []const u8, port: u16) !HttpServer {
        var parsed_address = try std.net.Address.parseIp4(address, port);
        return HttpServer{ .address = address, .port = port, .parsed_address = parsed_address };
    }

    fn parseConnection(connection: std.net.StreamServer.Connection) !bool {
        var buffer: [1024]u8 = undefined;
        var bytes_read = try connection.stream.read(&buffer);
        if (std.mem.eql(u8, buffer[0..bytes_read], "close")) {
            return false;
        }
        return true;
    }

    fn handleRequest(connection: std.net.StreamServer.Connection) !void {
        try connection.stream.writeAll(
            \\HTTP/1.1 200 OK
            \\Content-Type: text/html
            \\X-Powered-By:Zig
            \\
            \\<html><body>Hello World</body></html>
        );
        connection.stream.close();
    }

    fn listen(self: *HttpServer) !void {
        var server_socket = std.net.StreamServer.init(.{});
        try server_socket.listen(self.parsed_address);

        std.debug.print("Server running on http://{s}:{d}", .{ self.address, self.port });
        var listen_for_connections: bool = true;
        while (listen_for_connections) {
            var connection = try server_socket.accept();
            listen_for_connections = try parseConnection(connection);
            try handleRequest(connection);
        }
        // Close the server socket after exiting the loop
        server_socket.close();
    }
};

test "store headers from a request" {
    var example: []const u8 =
        \\GET / HTTP/1.1 
        \\Host: 127.0.0.1:3000
        \\Connection: keep-alive
        \\sec-ch-ua: "Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"
        \\sec-ch-ua-mobile: ?0
        \\sec-ch-ua-platform: "macOS"
        \\Upgrade-Insecure-Requests: 1
        \\User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36
        \\Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
        \\Sec-Fetch-Site: none
        \\Sec-Fetch-Mode: navigate
        \\Sec-Fetch-User: ?1
        \\Sec-Fetch-Dest: document
        \\Accept-Encoding: gzip, deflate, br
        \\Accept-Language: en-US,en;q=0.9
    ;
    var http_request = try parseHeaders(example);

    try expect(std.mem.eql(u8, http_request.http_method, "GET"));
    try expect(std.mem.eql(u8, http_request.path, "/"));
    try expect(std.mem.eql(u8, http_request.version, "HTTP/1.1"));
}

const HttpRequest = struct {
    http_method: []const u8,
    path: []const u8,
    version: []const u8,

    fn init(http_method: []const u8, path: []const u8, version: []const u8) HttpRequest {
        return HttpRequest{ .http_method = http_method, .path = path, .version = version };
    }
};

const HttpHeaderParseError = error{
    InvalidHttpMethodType,
};

fn parseHeaders(text: []const u8) !HttpRequest {
    var it = std.mem.tokenizeAny(u8, text, "\n");
    var parsed_method: []const u8 = undefined;
    var path: []const u8 = undefined;
    var version: []const u8 = undefined;

    //first line of the HTTP request contains the method, path, and HTTP version.
    if (it.next()) |first_line| {
        var first_line_it = std.mem.tokenizeAny(u8, first_line, " ");
        parsed_method = first_line_it.next() orelse return error.InvalidRequest;
        path = first_line_it.next() orelse return error.InvalidRequest;
        version = first_line_it.next() orelse return error.InvalidRequest;
    }
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeAny(u8, line, " ");
        _ = line_it;
    }

    return HttpRequest.init(parsed_method, path, version);
}

test "combine strings together" {
    var string_one: []const u8 = "hello";
    var string_two: []const u8 = " ";
    var string_three: []const u8 = "this is a combined string!";
    var combined_one_and_two = try combineSlices(test_allocator, string_one, string_two);
    try expect(std.mem.eql(u8, combined_one_and_two, "hello "));
    defer test_allocator.free(combined_one_and_two); // Free after use
    var combined_two_and_three = try combineSlices(test_allocator, combined_one_and_two, string_three);
    defer test_allocator.free(combined_two_and_three);
    try expect(std.mem.eql(u8, combined_two_and_three, "hello this is a combined string!"));
}

fn combineSlices(allocator: std.mem.Allocator, slice_one: []const u8, slice_two: []const u8) ![]u8 {
    // get the new length
    const length = slice_one.len + slice_two.len;

    var merged_slice = try allocator.alloc(u8, length);

    std.mem.copy(u8, merged_slice[0..slice_one.len], slice_one);
    std.mem.copy(u8, merged_slice[slice_one.len..], slice_two);
    return merged_slice;
}
