const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day13.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day13:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    if (i.* < input.len and input[i.*] == '\r') i.* += 1;
    if (i.* < input.len and input[i.*] == '\n') i.* += 1;
}

fn mirrors(items: []u32) ?usize {
    var i: usize = 1;
    loop: while (i < items.len) : (i += 2) {
        for (0..i / 2 + 1) |j| {
            if (items[j] != items[i - j]) {
                continue :loop;
            }
        }
        return i / 2 + 1;
    }
    i = 1;
    loop: while (i < items.len - 1) : (i += 2) {
        for (0..(items.len - i - 1) / 2 + 1) |j| {
            if (items[i + j] != items[items.len - j - 1]) {
                continue :loop;
            }
        }
        return (i + (items.len - 1 - i) / 2 + 1);
    }
    return null;
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var i: usize = 0;
    var horizontal = std.ArrayList(u32).init(alloc);
    defer horizontal.deinit();
    var verticle = std.ArrayList(u32).init(alloc);
    defer verticle.deinit();
    var sum: usize = 0;
    while (i < input.len) {
        var width: usize = 0;
        var j = i;
        while (i < input.len and (input[i] == '.' or input[i] == '#')) {
            var num: u32 = 0;
            while (i < input.len) : (i += 1) {
                switch (input[i]) {
                    '.' => num <<= 1,
                    '#' => {
                        num <<= 1;
                        num += 1;
                    },
                    else => {
                        try horizontal.append(num);
                        break;
                    },
                }
            }
            if (width == 0) width = i - j;
            nextLine(input, &i);
        }
        nextLine(input, &i);

        for (1..width + 1) |v| {
            var num: u32 = 0;
            for (horizontal.items) |h| {
                num <<= 1;
                num |= 1 & (h >> @truncate(width - v));
            }
            try verticle.append(num);
        }

        if (mirrors(horizontal.items)) |m| sum += 100 * m;
        if (mirrors(verticle.items)) |m| sum += m;

        horizontal.clearRetainingCapacity();
        verticle.clearRetainingCapacity();
    }
    return sum;
}

fn smugdedMirrors(items: []u32) ?usize {
    var i: usize = 1;
    loop: while (i < items.len) : (i += 2) {
        var sum: u6 = 0;
        for (0..i / 2 + 1) |j| {
            sum += @popCount(items[j] ^ items[i - j]);
            if (sum > 1) continue :loop;
        }
        if (sum == 1)
            return i / 2 + 1;
    }
    i = 1;
    loop: while (i < items.len - 1) : (i += 2) {
        var sum: u6 = 0;
        for (0..(items.len - i - 1) / 2 + 1) |j| {
            sum += @popCount(items[i + j] ^ items[items.len - j - 1]);
            if (sum > 1) {
                continue :loop;
            }
        }
        if (sum == 1)
            return (i + (items.len - 1 - i) / 2 + 1);
    }
    return null;
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var i: usize = 0;
    var horizontal = std.ArrayList(u32).init(alloc);
    defer horizontal.deinit();
    var verticle = std.ArrayList(u32).init(alloc);
    defer verticle.deinit();
    var sum: usize = 0;
    while (i < input.len) {
        var width: usize = 0;
        var j = i;
        while (i < input.len and (input[i] == '.' or input[i] == '#')) {
            var num: u32 = 0;
            while (i < input.len) : (i += 1) {
                switch (input[i]) {
                    '.' => num <<= 1,
                    '#' => {
                        num <<= 1;
                        num += 1;
                    },
                    else => {
                        try horizontal.append(num);
                        break;
                    },
                }
            }
            if (width == 0) width = i - j;
            nextLine(input, &i);
        }
        nextLine(input, &i);

        for (1..width + 1) |v| {
            var num: u32 = 0;
            for (horizontal.items) |h| {
                num <<= 1;
                num |= 1 & (h >> @truncate(width - v));
            }
            try verticle.append(num);
        }

        if (smugdedMirrors(horizontal.items)) |m| {
            sum += 100 * m;
        }
        if (smugdedMirrors(verticle.items)) |m| {
            sum += m;
        }

        horizontal.clearRetainingCapacity();
        verticle.clearRetainingCapacity();
    }

    return sum;
}

test "part1" {
    try std.testing.expect(405 == try part1(std.testing.allocator,
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
        \\
    ));
}

test "part2" {
    try std.testing.expect(400 == try part2(std.testing.allocator,
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
        \\
    ));
}
