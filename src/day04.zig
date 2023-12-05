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
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day04:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn find(comptime T: type, input: []const T, i: usize, delimiter: T) ?usize {
    for (input[i..], i..) |c, j| {
        if (c == delimiter) return j;
    }
    return null;
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var result: usize = 0;
    var winning_numbers = try ArrayList(u8).initCapacity(alloc, 10);
    defer winning_numbers.deinit();
    var i: usize = 0;
    while (i < input.len) {
        if (find(u8, input, i, ':')) |j| {
            i = j + 2;
        } else {
            return error.InvalidInput;
        }
        var num: u8 = 0;
        for (input[i..], i..) |c, j| {
            switch (c) {
                '0'...'9' => {
                    num = num * 10 + c - '0';
                },
                ' ' => {
                    if (num != 0) {
                        try winning_numbers.append(num);
                    }
                    num = 0;
                },
                else => {
                    i = j + 2;
                    break;
                },
            }
        }
        var points: usize = 0;
        match: for (input[i..], i..) |c, j| {
            switch (c) {
                '0'...'9' => {
                    num = num * 10 + c - '0';
                },
                ' ' => {
                    if (num != 0 and find(u8, winning_numbers.items, 0, num) != null) {
                        if (points == 0) {
                            points = 1;
                        } else {
                            points *= 2;
                        }
                    }
                    num = 0;
                },
                else => {
                    if (num != 0 and find(u8, winning_numbers.items, 0, num) != null) {
                        if (points == 0) {
                            points = 1;
                        } else {
                            points *= 2;
                        }
                    }
                    for (input[j..], j..) |e, k| {
                        if (e == '\n') {
                            i = k + 1;
                            break :match;
                        }
                    }
                    i = j + 1;
                    break :match;
                },
            }
        }
        result += points;
        winning_numbers.clearRetainingCapacity();
    }

    return result;
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var result: usize = 0;
    var cards = ArrayList([2]usize).init(alloc);
    defer cards.deinit();
    var winning_numbers = try ArrayList(u8).initCapacity(alloc, 10);
    defer winning_numbers.deinit();
    var i: usize = 0;
    while (i < input.len) {
        if (find(u8, input, i, ':')) |j| {
            i = j + 2;
        } else {
            return error.InvalidInput;
        }
        var num: u8 = 0;
        for (input[i..], i..) |c, j| {
            switch (c) {
                '0'...'9' => {
                    num = num * 10 + c - '0';
                },
                ' ' => {
                    if (num != 0) {
                        try winning_numbers.append(num);
                    }
                    num = 0;
                },
                else => {
                    i = j + 2;
                    break;
                },
            }
        }
        var matching: usize = 0;
        match: for (input[i..], i..) |c, j| {
            switch (c) {
                '0'...'9' => {
                    num = num * 10 + c - '0';
                },
                ' ' => {
                    if (num != 0 and find(u8, winning_numbers.items, 0, num) != null) {
                        matching += 1;
                    }
                    num = 0;
                },
                else => {
                    if (num != 0 and find(u8, winning_numbers.items, 0, num) != null) {
                        matching += 1;
                    }
                    for (input[j..], j..) |e, k| {
                        if (e == '\n') {
                            i = k + 1;
                            break :match;
                        }
                    }
                    i = j + 1;
                    break :match;
                },
            }
        }
        try cards.append(.{ 1, matching });
        winning_numbers.clearRetainingCapacity();
    }

    for (cards.items, 1..) |card, j| {
        result += card[0];
        for (cards.items[j .. j + card[1]]) |*c| {
            c.*[0] += card[0];
        }
    }

    return result;
}

test "part1" {
    try std.testing.expect(13 == try part1(std.testing.allocator,
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ));
}

test "part2" {
    try std.testing.expect(30 == try part2(std.testing.allocator,
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ));
}
