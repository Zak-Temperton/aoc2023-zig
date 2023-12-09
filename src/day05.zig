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

fn part1(alloc: Allocator, input: []const u8) !u64 {
    var seeds = ArrayList(u64).init(alloc);
    defer seeds.deinit();

    //seeds
    var i: usize = 0;
    skipUntil(input, &i, ' ');
    while (input[i] == ' ') {
        i += 1;
        try seeds.append(readInt(u64, input, &i));
    }
    skipUntil(input, &i, '\n');
    i += 1;
    skipUntil(input, &i, '\n');
    i += 1;
    //maps
    while (i < input.len) {
        var new_seeds = try seeds.clone();
        errdefer new_seeds.deinit();
        while (i < input.len) {
            if (input[i] < '0' or input[i] > '9') {
                skipUntil(input, &i, '\n');
                i += 1;
                break;
            }
            const dest_start = readInt(u64, input, &i);
            skip(input, &i, ' ');
            const source_start = readInt(u64, input, &i);
            skip(input, &i, ' ');
            const range = readInt(u64, input, &i);
            skipUntil(input, &i, '\n');
            i += 1;
            for (seeds.items, 0..) |seed, j| {
                if (seed >= source_start and seed < source_start + range) {
                    new_seeds.items[j] = dest_start + (seed - source_start);
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

    //seeds
    var i: usize = 0;
    skipUntil(input, &i, ' ');
    while (input[i] == ' ') {
        i += 1;
        const a = readInt(u64, input, &i);
        skip(input, &i, ' ');
        const b = readInt(u64, input, &i);
        try seeds.append(.{ a, a + b - 1 });
    }
    skipUntil(input, &i, '\n');
    i += 1;
    skipUntil(input, &i, '\n');
    i += 1;
    skipUntil(input, &i, '\n');
    i += 1;

    //maps
    while (i < input.len) {
        var new_seeds = try seeds.clone();
        errdefer new_seeds.deinit();
        while (i < input.len) {
            if (input[i] < '0' or input[i] > '9') {
                skipUntil(input, &i, '\n');
                i += 1;
                skipUntil(input, &i, '\n');
                i += 1;
                break;
            }
            const dest_start = readInt(u64, input, &i);
            skip(input, &i, ' ');
            const source_start = readInt(u64, input, &i);
            skip(input, &i, ' ');
            const range = readInt(u64, input, &i);
            skipUntil(input, &i, '\n');
            i += 1;
            const dest_end = dest_start + range - 1;
            const source_end = source_start + range - 1;
            //allow for adding new seed ranges without resizing in loop
            try seeds.ensureTotalCapacity(seeds.items.len * 2);
            for (seeds.items, 0..) |*seed, j| {
                if (source_start <= seed[1] and source_end >= seed[0]) {
                    if (source_start <= seed[0] and source_end >= seed[1]) {
                        new_seeds.items[j][0] = dest_start + (seed[0] - source_start);
                        new_seeds.items[j][1] = dest_start + (seed[1] - source_start);
                    } else if (source_start <= seed[0] and source_end < seed[1]) {
                        new_seeds.items[j][0] = source_start + range;
                        try new_seeds.append(.{ dest_start + (seed[0] - source_start), dest_end });
                        seed[0] = source_end + 1;
                    } else if (source_start > seed[0] and source_end >= seed[1]) {
                        new_seeds.items[j][1] = source_start - 1;
                        try new_seeds.append(.{ dest_start, dest_start + (seed[1] - source_start) });
                        seed[1] = source_start - 1;
                    } else if (source_start > seed[0] and source_end < seed[1]) {
                        new_seeds.items[j][1] = source_start - 1;
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
