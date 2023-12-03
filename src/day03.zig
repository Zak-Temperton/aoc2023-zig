const std = @import("std");
const Allocator = std.mem.Allocator;
const HashMap = std.AutoHashMap;
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day03.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day03:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn adjacent(input: HashMap([2]usize, void), x: usize, y: usize, len: usize) bool {
    for (x -| 1..x + len + 1) |xx| {
        if (input.contains(.{ xx, y -| 1 })) return true;
        if (input.contains(.{ xx, y + 1 })) return true;
    }
    if (input.contains(.{ x -| 1, y })) return true;
    if (input.contains(.{ x + len, y })) return true;
    return false;
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var result: usize = 0;
    var lines = tokenizeAny(u8, input, "\r\n");
    var symbols = HashMap([2]usize, void).init(alloc);
    defer symbols.deinit();
    var numbers = std.ArrayList([4]usize).init(alloc);
    defer numbers.deinit();
    var y: usize = 0;
    while (lines.next()) |line| : (y += 1) {
        var num: u32 = 0;
        var num_len: usize = 0;
        var x: usize = 0;
        for (line) |c| {
            switch (c) {
                '0'...'9' => {
                    num = num * 10 + c - '0';
                    num_len += 1;
                },
                '.' => {
                    if (num != 0) {
                        try numbers.append(.{ x - num_len, y, num_len, num });
                        num = 0;
                        num_len = 0;
                    }
                },
                else => {
                    if (num != 0) {
                        try numbers.append(.{ x - num_len, y, num_len, num });
                        num = 0;
                        num_len = 0;
                    }
                    try symbols.put(.{ x, y }, {});
                },
            }
            x += 1;
        }
        if (num != 0) {
            try numbers.append(.{ x - num_len, y, num_len, num });
        }
    }
    for (numbers.items) |number| {
        if (adjacent(symbols, number[0], number[1], number[2])) {
            result += number[3];
        }
    }
    return result;
}
fn adjacentGear(input: HashMap([2]usize, [2]usize), x: usize, y: usize, len: usize, num: usize) void {
    for (x -| 1..x + len + 1) |xx| {
        if (input.getPtr(.{ xx, y -| 1 })) |*v| {
            if (v.*[0] == 0) {
                v.*[0] = num;
            } else {
                v.*[1] = num;
            }
            return;
        }
        if (input.getPtr(.{ xx, y + 1 })) |*v| {
            if (v.*[0] == 0) {
                v.*[0] = num;
            } else {
                v.*[1] = num;
            }
            return;
        }
    }
    if (input.getPtr(.{ x -| 1, y })) |*v| {
        if (v.*[0] == 0) {
            v.*[0] = num;
        } else {
            v.*[1] = num;
        }
        return;
    }
    if (input.getPtr(.{ x + len, y })) |*v| {
        if (v.*[0] == 0) {
            v.*[0] = num;
        } else {
            v.*[1] = num;
        }
    }
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var result: usize = 0;
    var lines = tokenizeAny(u8, input, "\r\n");
    var gears = HashMap([2]usize, [2]usize).init(alloc);
    defer gears.deinit();
    var numbers = std.ArrayList([4]usize).init(alloc);
    defer numbers.deinit();
    var y: usize = 0;
    while (lines.next()) |line| : (y += 1) {
        var num: u32 = 0;
        var num_len: usize = 0;
        var x: usize = 0;
        for (line) |c| {
            switch (c) {
                '0'...'9' => {
                    num = num * 10 + c - '0';
                    num_len += 1;
                },
                '.' => {
                    if (num != 0) {
                        try numbers.append(.{ x - num_len, y, num_len, num });
                        num = 0;
                        num_len = 0;
                    }
                },
                '*' => {
                    if (num != 0) {
                        try numbers.append(.{ x - num_len, y, num_len, num });
                        num = 0;
                        num_len = 0;
                    }
                    try gears.put(.{ x, y }, .{ 0, 0 });
                },
                else => {
                    if (num != 0) {
                        try numbers.append(.{ x - num_len, y, num_len, num });
                        num = 0;
                        num_len = 0;
                    }
                },
            }
            x += 1;
        }
        if (num != 0) {
            try numbers.append(.{ x - num_len, y, num_len, num });
        }
    }
    for (numbers.items) |number| {
        adjacentGear(gears, number[0], number[1], number[2], number[3]);
    }
    var iter = gears.valueIterator();
    while (iter.next()) |gear| {
        result += gear[0] * gear[1];
    }
    return result;
}

test "part1" {
    try std.testing.expect(4361 == try part1(std.testing.allocator,
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ));
}

test "part2" {
    try std.testing.expect(467835 == try part2(std.testing.allocator,
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ));
}
