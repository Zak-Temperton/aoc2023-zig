const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day05.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day05:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn part1(alloc: Allocator, input: []const u8) !u64 {
    var seeds = ArrayList(u64).init(alloc);
    defer seeds.deinit();

    var lines = tokenizeAny(u8, input, "\r\n");
    //seeds
    if (lines.next()) |line| {
        var words = tokenizeAny(u8, line, " ");
        _ = words.next();
        while (words.next()) |word| {
            try seeds.append(try parseInt(u64, word, 10));
        }
    }
    //maps
    while (lines.index < lines.buffer.len) {
        var new_seeds = try seeds.clone();
        errdefer new_seeds.deinit();
        while (lines.next()) |line| {
            if (line[0] >= 'a' and line[0] <= 'z') break;
            var words = tokenizeAny(u8, line, " ");
            var dest_start = try parseInt(u64, words.next().?, 10);
            var source_start = try parseInt(u64, words.next().?, 10);
            var range = try parseInt(u64, words.next().?, 10);
            for (seeds.items, 0..) |seed, i| {
                if (seed >= source_start and seed < source_start + range) {
                    new_seeds.items[i] = dest_start + (seed - source_start);
                }
            }
        }

        seeds.deinit();
        seeds = new_seeds;
    }

    return std.mem.min(u64, seeds.items);
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var seeds = ArrayList([2]u64).init(alloc);
    defer seeds.deinit();

    var lines = tokenizeAny(u8, input, "\r\n");
    //seeds
    if (lines.next()) |line| {
        var words = tokenizeAny(u8, line, " ");
        _ = words.next();
        while (words.next()) |word| {
            const start = try parseInt(u64, word, 10);
            const len = try parseInt(u64, words.next().?, 10);
            try seeds.append(.{ start, start + len - 1 });
        }
    }
    //maps
    while (lines.index < lines.buffer.len) {
        var new_seeds = try seeds.clone();
        errdefer new_seeds.deinit();
        while (lines.next()) |line| {
            if (line[0] >= 'a' and line[0] <= 'z') break;
            var words = tokenizeAny(u8, line, " ");
            var dest_start = try parseInt(u64, words.next().?, 10);
            var source_start = try parseInt(u64, words.next().?, 10);
            var range = try parseInt(u64, words.next().?, 10);
            const dest_end = dest_start + range - 1;
            const source_end = source_start + range - 1;
            try seeds.ensureTotalCapacity(seeds.items.len * 2);
            for (seeds.items, 0..) |*seed, i| {
                if (source_start <= seed[1] and source_end >= seed[0]) {
                    if (source_start <= seed[0] and source_end >= seed[1]) {
                        new_seeds.items[i][0] = dest_start + (seed[0] - source_start);
                        new_seeds.items[i][1] = dest_start + (seed[1] - source_start);
                    } else if (source_start <= seed[0] and source_end < seed[1]) {
                        new_seeds.items[i][0] = source_start + range;
                        try new_seeds.append(.{ dest_start + (seed[0] - source_start), dest_end });
                        seed[0] = source_end + 1;
                    } else if (source_start > seed[0] and source_end >= seed[1]) {
                        new_seeds.items[i][1] = source_start - 1;
                        try new_seeds.append(.{ dest_start, dest_start + (seed[1] - source_start) });
                        seed[1] = source_start - 1;
                    } else if (source_start > seed[0] and source_end < seed[1]) {
                        new_seeds.items[i][1] = source_start - 1;
                        try new_seeds.append(.{ dest_start, dest_end });
                        try new_seeds.append(.{ source_start + range, seed[1] });
                        seeds.appendAssumeCapacity(.{ source_start + range, seed[1] });
                        seed[1] = source_start - 1;
                    }
                }
            }
        }

        seeds.deinit();
        seeds = new_seeds;
    }

    var min: u64 = std.math.maxInt(usize);
    for (seeds.items) |seed_range| {
        if (seed_range[0] < min) min = seed_range[0];
    }

    return min;
}

test "part1" {
    try std.testing.expect(35 == try part1(std.testing.allocator,
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ));
}

test "part2" {
    try std.testing.expect(46 == try part2(std.testing.allocator,
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ));
}
