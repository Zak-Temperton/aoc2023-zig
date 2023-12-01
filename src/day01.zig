const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day01.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = part1(buffer);
    const p1_time = timer.lap();
    const p2 = part2(buffer);
    const p2_time = timer.read();
    try stdout.print("Day01:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn part1(input: []const u8) u32 {
    var result: u32 = 0;
    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        var val: u32 = 0;
        for (0..line.len) |i| {
            if (line[i] >= '0' and line[i] <= '9') {
                val += 10 * (line[i] - '0');
                break;
            }
        }
        for (1..line.len + 1) |i| {
            if (line[line.len - i] >= '0' and line[line.len - i] <= '9') {
                val += line[line.len - i] - '0';
                break;
            }
        }
        result += val;
    }
    return result;
}

fn readNumber(input: []const u8) ?u32 {
    if (input.len < 3) return null;
    const numbers = [_][]const u8{
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
    };
    loop: for (numbers, 1..) |number, i| {
        if (number.len > input.len) continue;
        for (number, 0..) |c, j| {
            if (c != input[j]) {
                continue :loop;
            }
        }
        return @truncate(i);
    }
    return null;
}

fn part2(input: []const u8) usize {
    var result: u32 = 0;
    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        var val: u32 = 0;
        for (0..line.len) |i| {
            if (line[i] >= '0' and line[i] <= '9') {
                val += 10 * (line[i] - '0');
                break;
            }
            if (readNumber(line[i..])) |n| {
                val += 10 * n;
                break;
            }
        }
        for (1..line.len + 1) |i| {
            if (line[line.len - i] >= '0' and line[line.len - i] <= '9') {
                val += line[line.len - i] - '0';
                break;
            }
            if (readNumber(line[line.len - i ..])) |n| {
                val += n;
                break;
            }
        }
        result += val;
    }
    return result;
}

test "part1" {
    try std.testing.expect(142 == part1(
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ));
}

test "part2" {
    try std.testing.expect(281 == part2(
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ));
}
