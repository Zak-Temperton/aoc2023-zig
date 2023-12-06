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

fn part1(input: []const u8) !u64 {
    var result: u64 = 1;
    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    var times = std.mem.tokenizeAny(u8, lines.next().?, " ");
    var distances = std.mem.tokenizeAny(u8, lines.next().?, " ");
    _ = times.next();
    _ = distances.next();

    while (times.next()) |time| {
        if (distances.next()) |distance| {
            const t = try std.fmt.parseInt(u64, time, 10);
            const d = try std.fmt.parseInt(u64, distance, 10);
            result *= binarySearch(t, d);
        }
    }

    return result;
}

fn part2(input: []const u8) u64 {
    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    var time: u64 = 0;
    if (lines.next()) |line| {
        var words = std.mem.tokenizeAny(u8, line, " ");
        _ = words.next();
        while (words.next()) |word| {
            for (word) |c| {
                time = time * 10 + c - '0';
            }
        }
    }
    var distance: u64 = 0;
    if (lines.next()) |line| {
        var words = std.mem.tokenizeAny(u8, line, " ");
        _ = words.next();
        while (words.next()) |word| {
            for (word) |c| {
                distance = distance * 10 + c - '0';
            }
        }
    }

    var wins: u64 = 0;
    for (0..time) |p| {
        if (p * (time - p) > distance) {
            wins = time - p - p + 1;
            break;
        }
    }
    return binarySearch(time, distance);
}

fn binarySearch(range: u64, target: u64) u64 {
    var min: u64 = 0;
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
