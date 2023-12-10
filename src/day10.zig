const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day10.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day10:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    while (i.* < input.len and (input[i.*] == '\r' or input[i.*] == '\n')) : (i.* += 1) {}
}

fn createMap(alloc: Allocator, input: []const u8, map: *std.ArrayList(std.ArrayList(u8)), start: *[2]usize) !void {
    var x: usize = 0;
    var y: usize = 0;
    var row = std.ArrayList(u8).init(alloc);
    for (input) |c| {
        switch (c) {
            '\r' => {},
            '\n' => {
                try map.append(row);
                row = try std.ArrayList(u8).initCapacity(alloc, map.getLast().items.len);
                y += 1;
                x = 0;
            },
            'S' => {
                start.* = .{ x, y };
                try row.append(c);
                x += 1;
            },
            else => {
                try row.append(c);
                x += 1;
            },
        }
    }
    try map.append(row);
}

fn canStep(dir: u2, pipe: u8) bool {
    if (pipe == '.') return false;
    return switch (pipe) {
        '|' => dir == 1 or dir == 3,
        '-' => dir == 0 or dir == 2,
        'J' => dir == 0 or dir == 1,
        'L' => dir == 1 or dir == 2,
        'F' => dir == 3 or dir == 2,
        '7' => dir == 0 or dir == 3,
        else => unreachable,
    };
}

fn step(dir: u2, pipe: u8) u2 {
    return switch (pipe) {
        'J' => if (dir == 0) 3 else 2,
        'L' => if (dir == 1) 0 else 3,
        'F' => if (dir == 2) 1 else 0,
        '7' => if (dir == 0) 1 else 2,
        else => dir,
    };
}

fn traverseLoop(map: []std.ArrayList(u8), start: [2]usize) u32 {
    for (0..4) |d| {
        var dir: u2 = @truncate(d);
        var x = start[0];
        var y = start[1];
        switch (dir) {
            0 => x += 1,
            2 => x -= 1,
            1 => y += 1,
            3 => y -= 1,
        }
        var pipe = map[y].items[x];
        if (canStep(dir, pipe)) {
            var loop: u32 = 1;
            while (pipe != 'S') : (loop += 1) {
                dir = step(dir, pipe);
                switch (dir) {
                    0 => x += 1,
                    2 => x -= 1,
                    1 => y += 1,
                    3 => y -= 1,
                }
                pipe = map[y].items[x];
            }
            return loop;
        }
    }
    unreachable;
}
fn part1(alloc: Allocator, input: []const u8) !i64 {
    var map = std.ArrayList(std.ArrayList(u8)).init(alloc);
    defer {
        for (map.items) |*row| row.deinit();
        map.deinit();
    }
    var start: [2]usize = undefined;
    try createMap(alloc, input, &map, &start);
    return traverseLoop(map.items, start) / 2;
}

fn paintLoop(map: []std.ArrayList(u8), start: [2]usize) void {
    for (0..4) |d| {
        var dir: u2 = @truncate(d);
        var x = start[0];
        var y = start[1];
        switch (dir) {
            0 => x += 1,
            2 => x -= 1,
            1 => y += 1,
            3 => y -= 1,
        }
        var pipe = &map[y].items[x];
        if (canStep(dir, pipe.*)) {
            while (pipe.* != 'S') {
                var n_dir = step(dir, pipe.*);
                if (dir == 3 or n_dir == 1) {
                    pipe.* = '!';
                } else {
                    pipe.* = '_';
                }
                dir = n_dir;
                switch (dir) {
                    0 => x += 1,
                    2 => x -= 1,
                    1 => y += 1,
                    3 => y -= 1,
                }
                pipe = &map[y].items[x];
            }
            if (dir == 3 or d == 1) {
                pipe.* = '!';
            } else {
                pipe.* = '_';
            }
            return;
        }
    }
    unreachable;
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var map = std.ArrayList(std.ArrayList(u8)).init(alloc);
    defer {
        for (map.items) |*row| row.deinit();
        map.deinit();
    }
    var start: [2]usize = undefined;
    try createMap(alloc, input, &map, &start);

    paintLoop(map.items, start);

    var entraped: u32 = 0;
    for (map.items) |r| {
        var inside = false;
        for (r.items) |c| {
            switch (c) {
                '!' => inside = !inside,
                '_' => {},
                else => if (inside) {
                    entraped += 1;
                },
            }
        }
    }

    return entraped;
}

test "part1" {
    try std.testing.expect(8 == try part1(std.testing.allocator,
        \\...F7.
        \\..FJ|.
        \\.SJ.L7
        \\.|F--J
        \\.LJ...
    ));
}

test "part2" {
    try std.testing.expect(8 == try part2(std.testing.allocator,
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    ));
}
