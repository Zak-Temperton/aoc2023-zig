const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day14.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day14:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    if (i.* < input.len and input[i.*] == '\r') i.* += 1;
    if (i.* < input.len and input[i.*] == '\n') i.* += 1;
}

fn sumPopCount(slice: []u128) u128 {
    var sum: u128 = 0;
    for (slice, 0..) |rock, r| {
        sum += @popCount(rock) * (slice.len - r);
    }
    return sum;
}

fn setUp(input: []const u8, rocks: *std.ArrayList(u128), blocks: *std.ArrayList(u128)) !usize {
    var i: usize = 0;
    var width: usize = undefined;
    while (i < input.len) {
        width = i;
        var rock: u128 = 0;
        var block: u128 = 0;
        while (input[i] != '\r' and input[i] != '\n') : (i += 1) {
            rock <<= 1;
            block <<= 1;
            switch (input[i]) {
                '.' => {},
                '#' => {
                    block |= 1;
                },
                else => {
                    rock |= 1;
                },
            }
        }
        width = i - width;
        try rocks.append(rock);
        try blocks.append(block);
        nextLine(input, &i);
    }
    return width;
}

fn part1(alloc: Allocator, input: []const u8) !u128 {
    var rocks = std.ArrayList(u128).init(alloc);
    defer rocks.deinit();
    var blocks = std.ArrayList(u128).init(alloc);
    defer blocks.deinit();

    _ = try setUp(input, &rocks, &blocks);

    slideNorth(rocks.items, blocks.items);

    return sumPopCount(rocks.items);
}

fn slideNorth(rocks: []u128, blocks: []const u128) void {
    for (1..rocks.len + 1) |r| {
        for (0..rocks.len - r) |j| {
            const tmp = rocks[j];
            rocks[j] |= rocks[j + 1] & ~(rocks[j] | blocks[j]);
            rocks[j + 1] ^= tmp ^ rocks[j];
        }
    }
}

fn slideWest(rocks: []u128, blocks: []const u128, width: usize) void {
    for (0..rocks.len) |j| {
        for (0..width) |c| {
            for (1..width - c) |n| {
                const m = n - 1;
                const rock_mask = @as(u128, 1) << @truncate(m);
                const block_mask = @as(u128, 1) << @truncate(m + 1);
                if (rocks[j] & rock_mask != 0 and blocks[j] & block_mask == 0 and rocks[j] & block_mask == 0) {
                    rocks[j] ^= rock_mask | block_mask;
                }
            }
        }
    }
}

fn slideSouth(rocks: []u128, blocks: []const u128) void {
    for (0..rocks.len) |r| {
        for (1..rocks.len - r) |j| {
            const k = rocks.len - j;
            const tmp = rocks[k];
            rocks[k] |= rocks[k - 1] & ~(rocks[k] | blocks[k]);
            rocks[k - 1] ^= tmp ^ rocks[k];
        }
    }
}

fn slideEast(rocks: []u128, blocks: []const u128, width: usize) void {
    for (0..rocks.len) |j| {
        for (0..width) |c| {
            for (1..width - c) |m| {
                const rock_mask = @as(u128, 1) << @truncate(m);
                const block_mask = @as(u128, 1) << @truncate(m - 1);
                if (rocks[j] & rock_mask != 0 and blocks[j] & block_mask == 0 and rocks[j] & block_mask == 0) {
                    rocks[j] ^= rock_mask | block_mask;
                }
            }
        }
    }
}

fn find(haystack: [][]u128, needle: []u128) ?usize {
    for (haystack, 0..) |h, i| {
        if (std.mem.eql(u128, h, needle)) return i;
    }
    return null;
}

fn part2(alloc: Allocator, input: []const u8) !u128 {
    var rocks = std.ArrayList(u128).init(alloc);
    defer rocks.deinit();
    var blocks = std.ArrayList(u128).init(alloc);
    defer blocks.deinit();

    const width = try setUp(input, &rocks, &blocks);

    var seen = std.ArrayList([]u128).init(alloc);
    defer {
        for (seen.items) |item| alloc.free(item);
        seen.deinit();
    }

    var clone: std.ArrayList(u128) = undefined;
    defer clone.deinit();

    var iter: usize = 0;
    while (true) : (iter += 1) {
        if (find(seen.items, rocks.items)) |index| {
            return sumPopCount(seen.items[index + (1_000_000_000 - index) % (iter - index)]);
        } else {
            clone = try rocks.clone();
            try seen.append(try clone.toOwnedSlice());
        }

        slideNorth(rocks.items, blocks.items);
        slideWest(rocks.items, blocks.items, width);
        slideSouth(rocks.items, blocks.items);
        slideEast(rocks.items, blocks.items, width);
    }
}

test "part1" {
    try std.testing.expect(136 == try part1(std.testing.allocator,
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
        \\
    ));
}

test "part2" {
    try std.testing.expect(64 == try part2(std.testing.allocator,
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
        \\
    ));
}
