const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day17.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day17:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    if (i.* < input.len and input[i.*] == '\r') i.* += 1;
    if (i.* < input.len and input[i.*] == '\n') i.* += 1;
}

fn contains(haystack: [][3]usize, needle: [3]usize) bool {
    for (haystack) |hay|
        if (hay[0] == needle[0] and hay[1] == needle[1] and hay[2] == needle[2])
            return true;
    return false;
}

fn minPathMax3(alloc: Allocator, map: []const []const u8, traversed: [2]std.ArrayList([]u32)) !u32 {
    var next = std.ArrayList([3]usize).init(alloc);
    defer next.deinit();
    try next.append(.{ 0, 0, 0 });
    try next.append(.{ 0, 0, 1 });

    var found_min: u32 = std.math.maxInt(u32);

    while (next.items.len != 0) {
        var min_index: usize = 0;
        {
            const m = next.items[0];
            var min = traversed[m[2]].items[m[0]][m[1]] -| (map.len + map[0].len - 2);
            for (next.items[1..], 1..) |n, i| {
                const tmp = traversed[n[2]].items[n[0]][n[1]] -| (map.len - n[0] + map[0].len - n[1] - 2);
                if (tmp < min) {
                    min = tmp;
                    min_index = i;
                }
            }
        }

        const pos = next.swapRemove(min_index);
        const loss: u32 = traversed[pos[2]].items[pos[0]][pos[1]];
        // std.debug.print("{d} {d}\n", .{ pos, loss });

        if (loss >= found_min) continue;
        if (pos[0] == map.len - 1 and pos[1] == map[0].len - 1) {
            found_min = loss;
            continue;
        }
        var sum_n: u32 = loss;
        var sum_e: u32 = loss;
        var sum_s: u32 = loss;
        var sum_w: u32 = loss;
        for (1..4) |i| {
            if (pos[2] != 0) {
                if (pos[0] >= i) {
                    sum_w += map[pos[0] - i][pos[1]] - '0';
                    if (traversed[0].items[pos[0] - i][pos[1]] > sum_w) {
                        traversed[0].items[pos[0] - i][pos[1]] = sum_w;
                        const new_pos = .{ pos[0] - i, pos[1], 0 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }

                if (pos[0] < map.len - i) {
                    sum_e += map[pos[0] + i][pos[1]] - '0';
                    if (traversed[0].items[pos[0] + i][pos[1]] > sum_e) {
                        traversed[0].items[pos[0] + i][pos[1]] = sum_e;
                        const new_pos = .{ pos[0] + i, pos[1], 0 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }
            } else {
                if (pos[1] >= i) {
                    sum_n += map[pos[0]][pos[1] - i] - '0';
                    if (traversed[1].items[pos[0]][pos[1] - i] > sum_n) {
                        traversed[1].items[pos[0]][pos[1] - i] = sum_n;
                        const new_pos = .{ pos[0], pos[1] - i, 1 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }
                if (pos[1] < map[0].len - i) {
                    sum_s += map[pos[0]][pos[1] + i] - '0';
                    if (traversed[1].items[pos[0]][pos[1] + i] > sum_s) {
                        traversed[1].items[pos[0]][pos[1] + i] = sum_s;
                        const new_pos = .{ pos[0], pos[1] + i, 1 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }
            }
        }
    }
    return found_min;
}

fn minPathMin4(alloc: Allocator, map: []const []const u8, traversed: [2]std.ArrayList([]u32)) !u32 {
    var next = std.ArrayList([3]usize).init(alloc);
    defer next.deinit();
    try next.append(.{ 0, 0, 0 });
    try next.append(.{ 0, 0, 1 });

    var found_min: u32 = std.math.maxInt(u32);

    while (next.items.len != 0) {
        var min_index: usize = 0;
        {
            const m = next.items[0];
            var min = traversed[m[2]].items[m[0]][m[1]] -| (map.len + map[0].len - 2);
            for (next.items[1..], 1..) |n, i| {
                const tmp = traversed[n[2]].items[n[0]][n[1]] -| (map.len - n[0] + map[0].len - n[1] - 2);
                if (tmp < min) {
                    min = tmp;
                    min_index = i;
                }
            }
        }

        const pos = next.swapRemove(min_index);
        const loss: u32 = traversed[pos[2]].items[pos[0]][pos[1]];
        // std.debug.print("{d} {d}\n", .{ pos, loss });
        if (loss >= found_min) continue;
        if (pos[0] == map.len - 1 and pos[1] == map[0].len - 1) {
            found_min = loss;
            continue;
        }
        var sum_n: u32 = loss;
        var sum_e: u32 = loss;
        var sum_s: u32 = loss;
        var sum_w: u32 = loss;
        if (pos[2] != 0) {
            if (pos[0] >= 4) {
                for (1..4) |j| {
                    const i = pos[0] - j;
                    sum_w += map[i][pos[1]] - '0';
                }
                for (4..@min(pos[0] + 1, 11)) |j| {
                    const i = pos[0] - j;
                    sum_w += map[i][pos[1]] - '0';
                    if (traversed[0].items[i][pos[1]] > sum_w) {
                        traversed[0].items[i][pos[1]] = sum_w;
                        const new_pos = .{ i, pos[1], 0 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }
            }
            if (pos[0] + 4 <= map.len - 1) {
                for (pos[0] + 1..pos[0] + 4) |i| {
                    sum_e += map[i][pos[1]] - '0';
                }
                for (pos[0] + 4..@min(pos[0] + 11, map.len)) |i| {
                    sum_e += map[i][pos[1]] - '0';
                    if (traversed[0].items[i][pos[1]] > sum_e) {
                        traversed[0].items[i][pos[1]] = sum_e;
                        const new_pos = .{ i, pos[1], 0 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }
            }
        } else {
            if (pos[1] >= 4) {
                for (1..4) |j| {
                    const i = pos[1] - j;
                    sum_n += map[pos[0]][i] - '0';
                }
                for (4..@min(pos[1] + 1, 11)) |j| {
                    const i = pos[1] - j;
                    sum_n += map[pos[0]][i] - '0';
                    if (traversed[1].items[pos[0]][i] > sum_n) {
                        traversed[1].items[pos[0]][i] = sum_n;
                        const new_pos = .{ pos[0], i, 1 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }
            }
            if (pos[1] + 4 <= map[0].len - 1) {
                for (pos[1] + 1..pos[1] + 4) |i| {
                    sum_s += map[pos[0]][i] - '0';
                }
                for (pos[1] + 4..@min(pos[1] + 11, map[0].len)) |i| {
                    sum_s += map[pos[0]][i] - '0';
                    if (traversed[1].items[pos[0]][i] > sum_s) {
                        traversed[1].items[pos[0]][i] = sum_s;
                        const new_pos = .{ pos[0], i, 1 };
                        if (!contains(next.items, new_pos))
                            try next.append(new_pos);
                    }
                }
            }
        }
    }
    return found_min;
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var map = std.ArrayList([]u8).init(alloc);
    var traversed: [2]std.ArrayList([]u32) = undefined;
    for (&traversed) |*dir| dir.* = std.ArrayList([]u32).init(alloc);
    defer {
        for (map.items) |row| alloc.free(row);
        map.deinit();
        for (&traversed) |*dir| {
            for (dir.items) |row| alloc.free(row);
            dir.deinit();
        }
    }

    var i: usize = 0;
    while (i < input.len) {
        const start = i;
        while (i < input.len and input[i] != '\r' and input[i] != '\n') : (i += 1) {}

        var row = try alloc.alloc(u8, i - start);
        @memcpy(row, input[start..i]);
        try map.append(row);

        for (&traversed) |*dir| {
            var trav_row = try alloc.alloc(u32, i - start);
            @memset(trav_row, std.math.maxInt(u32));
            try dir.append(trav_row);
        }

        nextLine(input, &i);
    }
    for (traversed) |dir| {
        dir.items[0][0] = 0;
    }

    return try minPathMax3(alloc, map.items, traversed);
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var map = std.ArrayList([]u8).init(alloc);
    var traversed: [2]std.ArrayList([]u32) = undefined;
    for (&traversed) |*dir| dir.* = std.ArrayList([]u32).init(alloc);
    defer {
        for (map.items) |row| alloc.free(row);
        map.deinit();
        for (&traversed) |*dir| {
            for (dir.items) |row| alloc.free(row);
            dir.deinit();
        }
    }

    var i: usize = 0;
    while (i < input.len) {
        const start = i;
        while (i < input.len and input[i] != '\r' and input[i] != '\n') : (i += 1) {}

        var row = try alloc.alloc(u8, i - start);
        @memcpy(row, input[start..i]);
        try map.append(row);

        for (&traversed) |*dir| {
            var trav_row = try alloc.alloc(u32, i - start);
            @memset(trav_row, std.math.maxInt(u32));
            try dir.append(trav_row);
        }

        nextLine(input, &i);
    }
    for (traversed) |dir| {
        dir.items[0][0] = 0;
    }

    return try minPathMin4(alloc, map.items, traversed);
}

test "part1" {
    try std.testing.expect(102 == try part1(std.testing.allocator,
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    ));
}

test "part2" {
    try std.testing.expect(94 == try part2(std.testing.allocator,
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    ));
    try std.testing.expect(71 == try part2(std.testing.allocator,
        \\111111111111
        \\999999999991
        \\999999999991
        \\999999999991
        \\999999999991
    ));
}
