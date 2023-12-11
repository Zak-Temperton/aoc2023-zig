const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day11.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day11:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn createMap(input: []const u8, map: *std.ArrayList([2]usize), expansion: usize) !void {
    var x: usize = 0;
    var y: usize = 0;
    var width: usize = 0;
    var expand = true;
    for (input) |c| {
        switch (c) {
            '\r' => {},
            '\n' => {
                y += if (expand) expansion else 1;
                expand = true;
                width = x;
                x = 0;
            },
            '#' => {
                expand = false;
                try map.append(.{ x, y });
                x += 1;
            },
            else => {
                x += 1;
            },
        }
    }
    var xx: usize = 0;
    loop: while (xx < width) {
        for (map.items) |galaxy| {
            if (galaxy[0] == xx) {
                xx += 1;
                continue :loop;
            }
        }
        for (map.items) |*galaxy| {
            if (galaxy[0] > xx) {
                galaxy[0] += expansion - 1;
            }
        }
        width += expansion - 1;
        xx += expansion;
    }
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var map = std.ArrayList([2]usize).init(alloc);
    defer map.deinit();
    try createMap(input, &map, 2);
    var sum: usize = 0;
    for (map.items, 0..) |galaxy1, i| {
        for (map.items[i + 1 ..]) |galaxy2| {
            if (galaxy1[0] < galaxy2[0]) {
                sum += galaxy2[0] - galaxy1[0] + galaxy2[1] - galaxy1[1];
            } else {
                sum += galaxy1[0] - galaxy2[0] + galaxy2[1] - galaxy1[1];
            }
        }
    }
    return sum;
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var map = std.ArrayList([2]usize).init(alloc);
    defer map.deinit();
    try createMap(input, &map, 1_000_000);
    var sum: usize = 0;
    for (map.items, 0..) |galaxy1, i| {
        for (map.items[i + 1 ..]) |galaxy2| {
            if (galaxy1[0] < galaxy2[0]) {
                sum += galaxy2[0] - galaxy1[0] + galaxy2[1] - galaxy1[1];
            } else {
                sum += galaxy1[0] - galaxy2[0] + galaxy2[1] - galaxy1[1];
            }
        }
    }
    return sum;
}

test "part1" {
    try std.testing.expect(374 == try part1(std.testing.allocator,
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ));
}

test "part2" {
    try std.testing.expect(82000210 == try part2(std.testing.allocator,
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ));
}
