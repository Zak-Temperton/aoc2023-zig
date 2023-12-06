const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day06.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(buffer);
    const p1_time = timer.lap();
    const p2 = part2(buffer);
    const p2_time = timer.read();
    try stdout.print("Day06:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn readInt(comptime T: type, input: []const u8, i: *usize) T {
    var num: T = 0;
    while (i.* < input.len) : (i.* += 1) {
        switch (input[i.*]) {
            '0'...'9' => |c| num = num * 10 + c - '0',
            else => return num,
        }
    }
    return num;
}

fn skipUntil(input: []const u8, i: *usize, delimiter: u8) void {
    while (i.* < input.len and input[i.*] != delimiter) : (i.* += 1) {}
}

fn skip(input: []const u8, i: *usize, delimiter: u8) void {
    while (i.* < input.len and input[i.*] == delimiter) : (i.* += 1) {}
}

fn part1(input: []const u8) !u64 {
    var result: u64 = 1;
    var i: usize = 0;
    skipUntil(input, &i, ' ');
    skip(input, &i, ' ');
    var j: usize = i;
    skipUntil(input, &j, ':');
    j += 1;
    skip(input, &j, ' ');

    while (input[j] != '\r') {
        var t = readInt(u64, input, &i);
        skip(input, &i, ' ');
        var d = readInt(u64, input, &j);
        skip(input, &j, ' ');
        result *= binarySearch(t, d);
    }

    return result;
}

fn readInts(comptime T: type, input: []const u8, i: *usize) T {
    var num: T = 0;
    while (i.* < input.len) : (i.* += 1) {
        switch (input[i.*]) {
            '0'...'9' => |c| num = num * 10 + c - '0',
            ' ' => {},
            else => return num,
        }
    }
    return num;
}

fn part2(input: []const u8) u64 {
    var i: usize = 0;
    skipUntil(input, &i, ' ');
    var time: u64 = readInts(u64, input, &i);
    skipUntil(input, &i, ' ');
    var distance: u64 = readInts(u64, input, &i);
    return binarySearch(time, distance);
}

fn binarySearch(range: u64, target: u64) u64 {
    var min: u64 = 1;
    var max: u64 = range;
    while (max > min) {
        var pos = min + ((max - min) / 2);
        if (pos * (range - pos) > target) {
            max = pos;
        } else {
            min = pos + 1;
        }
    }
    return range - max - max + 1;
}

test "part1" {
    try std.testing.expect(288 == try part1(
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ));
}

test "part2" {
    try std.testing.expect(71503 == part2(
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ));
}
