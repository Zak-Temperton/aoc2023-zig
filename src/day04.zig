const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day04.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day04:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn part1(input: []const u8) !usize {
    var result: usize = 0;
    var lines = tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        var numbers = tokenizeAny(u8, line, ":|");
        _ = numbers.next();
        var winning_numbers: [10]u8 = undefined;
        var winning = tokenizeAny(u8, numbers.next().?, " ");
        var i: usize = 0;
        while (winning.next()) |w| : (i += 1) {
            winning_numbers[i] = try parseInt(u8, w, 10);
        }
        var points: usize = 0;
        var nums = tokenizeAny(u8, numbers.next().?, " ");
        while (nums.next()) |n| : (i += 1) {
            const num = try parseInt(u8, n, 10);
            if (std.mem.containsAtLeast(u8, &winning_numbers, 1, &.{num})) {
                if (points == 0) {
                    points = 1;
                } else {
                    points *= 2;
                }
            }
        }
        result += points;
    }
    return result;
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var result: usize = 0;
    var lines = tokenizeAny(u8, input, "\r\n");
    var cards = ArrayList([2]usize).init(alloc);
    defer cards.deinit();
    while (lines.next()) |line| {
        var numbers = tokenizeAny(u8, line, ":|");
        _ = numbers.next();
        var winning_numbers: [10]u8 = undefined;
        var winning = tokenizeAny(u8, numbers.next().?, " ");
        var i: usize = 0;
        while (winning.next()) |w| : (i += 1) {
            winning_numbers[i] = try parseInt(u8, w, 10);
        }
        var matching: usize = 0;
        var nums = tokenizeAny(u8, numbers.next().?, " ");
        while (nums.next()) |n| : (i += 1) {
            const num = try parseInt(u8, n, 10);
            if (std.mem.containsAtLeast(u8, &winning_numbers, 1, &.{num})) {
                matching += 1;
            }
        }
        try cards.append(.{ 1, matching });
    }
    for (cards.items, 0..) |card, i| {
        result += card[0];
        for (cards.items[i + 1 .. i + card[1] + 1]) |*c| {
            c.*[0] += card[0];
        }
    }

    return result;
}
