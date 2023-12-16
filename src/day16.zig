const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day16.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day16:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    if (i.* < input.len and input[i.*] == '\r') i.* += 1;
    if (i.* < input.len and input[i.*] == '\n') i.* += 1;
}

const Beam = struct { x: usize, y: usize, dir: u2 };

fn numEnergized(alloc: Allocator, map: [][]u8, beam: Beam) !usize {
    const width = map[0].len;
    const height = map.len;

    var energized = try std.ArrayList(u128).initCapacity(alloc, height);
    defer energized.deinit();
    for (0..height) |_| energized.appendAssumeCapacity(0);

    var beams = std.ArrayList(Beam).init(alloc);
    defer beams.deinit();
    try beams.append(beam);

    var blocks = std.AutoHashMap([2]usize, void).init(alloc);
    defer blocks.deinit();

    while (beams.popOrNull()) |curr_beam| {
        switch (curr_beam.dir) {
            0 => {
                for (curr_beam.x..width) |x| {
                    if (blocks.contains(.{ x, curr_beam.y })) break;
                    energized.items[curr_beam.y] |= @as(u128, 1) << @truncate(x);
                    switch (map[curr_beam.y][x]) {
                        '.' => {},
                        '-' => {},
                        '|' => {
                            if (curr_beam.y != height - 1) try beams.append(.{ .x = x, .y = curr_beam.y + 1, .dir = 1 });
                            if (curr_beam.y != 0) try beams.append(.{ .x = x, .y = curr_beam.y - 1, .dir = 3 });
                            try blocks.put(.{ x, curr_beam.y }, {});
                            break;
                        },
                        '\\' => {
                            if (curr_beam.y != height - 1) try beams.append(.{ .x = x, .y = curr_beam.y + 1, .dir = 1 });
                            break;
                        },
                        '/' => {
                            if (curr_beam.y != 0) try beams.append(.{ .x = x, .y = curr_beam.y - 1, .dir = 3 });
                            break;
                        },
                        else => |c| std.debug.print("{c}\n", .{c}),
                    }
                }
            },
            1 => {
                for (curr_beam.y..map.len) |y| {
                    if (blocks.contains(.{ curr_beam.x, y })) break;
                    energized.items[y] |= @as(u128, 1) << @truncate(curr_beam.x);
                    switch (map[y][curr_beam.x]) {
                        '.' => {},
                        '|' => {},
                        '-' => {
                            if (curr_beam.x != width - 1) try beams.append(.{ .x = curr_beam.x + 1, .y = y, .dir = 0 });
                            if (curr_beam.x != 0) try beams.append(.{ .x = curr_beam.x - 1, .y = y, .dir = 2 });
                            try blocks.put(.{ curr_beam.x, y }, {});
                            break;
                        },
                        '\\' => {
                            if (curr_beam.x != width - 1) try beams.append(.{ .x = curr_beam.x + 1, .y = y, .dir = 0 });
                            break;
                        },
                        '/' => {
                            if (curr_beam.x != 0) try beams.append(.{ .x = curr_beam.x - 1, .y = y, .dir = 2 });
                            break;
                        },

                        else => |c| std.debug.print("{c}\n", .{c}),
                    }
                }
            },
            2 => {
                for (0..curr_beam.x + 1) |j| {
                    var x = curr_beam.x - j;
                    if (blocks.contains(.{ x, curr_beam.y })) break;
                    energized.items[curr_beam.y] |= @as(u128, 1) << @truncate(x);
                    switch (map[curr_beam.y][x]) {
                        '.' => {},
                        '-' => {},
                        '|' => {
                            if (curr_beam.y != height - 1) try beams.append(.{ .x = x, .y = curr_beam.y + 1, .dir = 1 });
                            if (curr_beam.y != 0) try beams.append(.{ .x = x, .y = curr_beam.y - 1, .dir = 3 });
                            try blocks.put(.{ x, curr_beam.y }, {});
                            break;
                        },
                        '\\' => {
                            if (curr_beam.y != 0) try beams.append(.{ .x = x, .y = curr_beam.y - 1, .dir = 3 });
                            break;
                        },
                        '/' => {
                            if (curr_beam.y != height - 1) try beams.append(.{ .x = x, .y = curr_beam.y + 1, .dir = 1 });
                            break;
                        },
                        else => |c| std.debug.print("{c}\n", .{c}),
                    }
                }
            },
            3 => {
                for (0..curr_beam.y + 1) |j| {
                    var y = curr_beam.y - j;
                    if (blocks.contains(.{ curr_beam.x, y })) break;
                    energized.items[y] |= @as(u128, 1) << @truncate(curr_beam.x);
                    switch (map[y][curr_beam.x]) {
                        '.' => {},
                        '|' => {},
                        '-' => {
                            if (curr_beam.x != width - 1) try beams.append(.{ .x = curr_beam.x + 1, .y = y, .dir = 0 });
                            if (curr_beam.x != 0) try beams.append(.{ .x = curr_beam.x - 1, .y = y, .dir = 2 });
                            try blocks.put(.{ curr_beam.x, y }, {});
                            break;
                        },
                        '\\' => {
                            if (curr_beam.x != 0) try beams.append(.{ .x = curr_beam.x - 1, .y = y, .dir = 2 });
                            break;
                        },
                        '/' => {
                            if (curr_beam.x != width - 1) try beams.append(.{ .x = curr_beam.x + 1, .y = y, .dir = 0 });
                            break;
                        },
                        else => |c| std.debug.print("{c}\n", .{c}),
                    }
                }
            },
        }
    }
    var sum: u32 = 0;
    for (energized.items) |item| sum += @popCount(item);
    return sum;
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var map = std.ArrayList([]u8).init(alloc);
    defer {
        for (map.items) |row| alloc.free(row);
        map.deinit();
    }

    var i: usize = 0;
    while (i < input.len) {
        const start = i;
        while (i < input.len and input[i] != '\r' and input[i] != '\n') : (i += 1) {}
        var row = try alloc.alloc(u8, i - start);
        @memcpy(row, input[start..i]);
        try map.append(row);
        nextLine(input, &i);
    }

    return try numEnergized(alloc, map.items, .{ .x = 0, .y = 0, .dir = 0 });
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var map = std.ArrayList([]u8).init(alloc);
    defer {
        for (map.items) |row| alloc.free(row);
        map.deinit();
    }

    var i: usize = 0;
    while (i < input.len) {
        const start = i;
        while (i < input.len and input[i] != '\r' and input[i] != '\n') : (i += 1) {}
        var row = try alloc.alloc(u8, i - start);
        @memcpy(row, input[start..i]);
        try map.append(row);
        nextLine(input, &i);
    }

    var max: usize = 0;
    for (0..map.items.len) |y| {
        {
            const sum = try numEnergized(alloc, map.items, .{ .x = 0, .y = y, .dir = 0 });
            if (sum > max) max = sum;
        }
        {
            const sum = try numEnergized(alloc, map.items, .{ .x = map.items[0].len - 1, .y = y, .dir = 2 });
            if (sum > max) max = sum;
        }
    }
    for (0..map.items[0].len) |x| {
        {
            const sum = try numEnergized(alloc, map.items, .{ .x = x, .y = 0, .dir = 1 });
            if (sum > max) max = sum;
        }
        {
            const sum = try numEnergized(alloc, map.items, .{ .x = x, .y = map.items.len - 1, .dir = 3 });
            if (sum > max) max = sum;
        }
    }
    return max;
}

test "part1" {
    try std.testing.expect(46 == try part1(std.testing.allocator,
        \\.|...\....
        \\|.-.\.....
        \\.....|-...
        \\........|.
        \\..........
        \\.........\
        \\..../.\\..
        \\.-.-/..|..
        \\.|....-|.\
        \\..//.|....
    ));
}

test "part2" {
    try std.testing.expect(51 == try part2(std.testing.allocator,
        \\.|...\....
        \\|.-.\.....
        \\.....|-...
        \\........|.
        \\..........
        \\.........\
        \\..../.\\..
        \\.-.-/..|..
        \\.|....-|.\
        \\..//.|....
    ));
}
