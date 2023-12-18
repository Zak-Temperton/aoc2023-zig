const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day18.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day18:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    while (i.* < input.len and input[i.*] != '\n') i.* += 1;
    i.* += 1;
}

fn readInt(comptime T: type, input: []const u8, i: *usize) T {
    var res: T = 0;
    while (i.* < input.len) : (i.* += 1) {
        switch (input[i.*]) {
            '0'...'9' => |c| res = res * 10 + c - '0',
            else => return res,
        }
    }
    return res;
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var i: usize = 0;
    var x: isize = 0;
    var y: isize = 0;

    var shape = std.AutoHashMap(isize, std.ArrayList(isize)).init(alloc);
    errdefer {
        var iterator = shape.valueIterator();
        while (iterator.next()) |row| row.deinit();
    }
    defer shape.deinit();
    try shape.put(0, blk: {
        var row = std.ArrayList(isize).init(alloc);
        try row.append(0);
        break :blk row;
    });

    var last_dir: u8 = 'D';
    while (i < input.len) {
        const dir = input[i];
        i += 2;
        const dist = readInt(isize, input, &i);

        switch (dir) {
            'L' => {
                if (last_dir == 'D') {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
                x -= dist;
            },
            'R' => {
                if (last_dir == 'U') {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
                x += dist;
            },
            'U' => {
                var target = y - dist;
                if (last_dir == 'R') y -= 1;
                while (y > target) : (y -= 1) {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
            },
            'D' => {
                var target = y + dist;
                if (last_dir == 'L') y += 1;
                while (y < target) : (y += 1) {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
            },
            else => unreachable,
        }
        last_dir = dir;
        nextLine(input, &i);
    }
    var area: usize = 0;
    var iterator = shape.iterator();
    while (iterator.next()) |row| {
        std.mem.sortUnstable(isize, row.value_ptr.items, {}, std.sort.asc(isize));

        var j: usize = 0;
        while (j < row.value_ptr.items.len - 1) : (j += 2) {
            if (j > 2 and row.value_ptr.items[j - 1] == row.value_ptr.items[j]) {
                area += @intCast(row.value_ptr.items[j + 1] - row.value_ptr.items[j]);
            } else {
                area += @intCast(row.value_ptr.items[j + 1] - row.value_ptr.items[j] + 1);
            }
        }
        row.value_ptr.deinit();
    }
    return area;
}

fn readHex(comptime T: type, input: []const u8, i: *usize) T {
    var res: T = 0;
    const len = i.* + 5;
    while (i.* < len) : (i.* += 1) {
        switch (input[i.*]) {
            '0'...'9' => |c| res = res * 16 + c - '0',
            'a'...'f' => |c| res = res * 16 + c + 10 - 'a',
            else => return res,
        }
    }
    return res;
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var i: usize = 0;
    var x: isize = 0;
    var y: isize = 0;

    var shape = std.AutoHashMap(isize, std.ArrayList(isize)).init(alloc);
    errdefer {
        var iterator = shape.valueIterator();
        while (iterator.next()) |row| row.deinit();
    }
    defer shape.deinit();
    try shape.put(0, blk: {
        var row = std.ArrayList(isize).init(alloc);
        try row.append(0);
        break :blk row;
    });

    var last_dir: u8 = 'D';
    while (i < input.len) {
        i += 3;
        while (input[i] != ' ') i += 1;
        i += 3;
        const dist = readHex(isize, input, &i);
        var dir = input[i] - '0';

        switch (dir) {
            2 => {
                if (last_dir == 1) {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
                x -= dist;
            },
            0 => {
                if (last_dir == 3) {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
                x += dist;
            },
            3 => {
                var target = y - dist;
                if (last_dir == 0) y -= 1;
                while (y > target) : (y -= 1) {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
            },
            1 => {
                var target = y + dist;
                if (last_dir == 2) y += 1;
                while (y < target) : (y += 1) {
                    var row = try shape.getOrPut(y);
                    if (!row.found_existing) {
                        row.value_ptr.* = std.ArrayList(isize).init(alloc);
                    }
                    try row.value_ptr.*.append(x);
                }
            },
            else => unreachable,
        }
        last_dir = dir;
        nextLine(input, &i);
    }
    var area: usize = 0;
    var iterator = shape.iterator();
    while (iterator.next()) |row| {
        std.mem.sortUnstable(isize, row.value_ptr.items, {}, std.sort.asc(isize));

        var j: usize = 0;
        while (j < row.value_ptr.items.len - 1) : (j += 2) {
            if (j > 2 and row.value_ptr.items[j - 1] == row.value_ptr.items[j]) {
                area += @intCast(row.value_ptr.items[j + 1] - row.value_ptr.items[j]);
            } else {
                area += @intCast(row.value_ptr.items[j + 1] - row.value_ptr.items[j] + 1);
            }
        }
        row.value_ptr.deinit();
    }
    return area;
}

test "part1" {
    try std.testing.expect(62 == try part1(std.testing.allocator,
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ));
}

test "part2" {
    try std.testing.expect(952408144115 == try part2(std.testing.allocator,
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ));
}
