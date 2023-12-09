const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day09.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day09:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn readInt(input: []const u8, i: *usize) i64 {
    var num: i64 = 0;
    if (input[i.*] == '-') {
        i.* += 1;
        while (i.* < input.len) : (i.* += 1) {
            switch (input[i.*]) {
                '0'...'9' => |c| num = num * 10 - (c - '0'),
                else => return num,
            }
        }
    } else {
        while (i.* < input.len) : (i.* += 1) {
            switch (input[i.*]) {
                '0'...'9' => |c| num = num * 10 + c - '0',
                else => return num,
            }
        }
    }
    return num;
}

fn nextLine(input: []const u8, i: *usize) void {
    while (i.* < input.len and (input[i.*] == '\r' or input[i.*] == '\n')) : (i.* += 1) {}
}

fn part1(alloc: Allocator, input: []const u8) !i64 {
    var result: i64 = 0;
    var i: usize = 0;
    var diffs = std.ArrayList(i64).init(alloc);
    defer diffs.deinit();
    while (i < input.len) {
        diffs.clearRetainingCapacity();
        try diffs.append(readInt(input, &i));
        while (i < input.len and input[i] == ' ') {
            i += 1;
            try diffs.append(readInt(input, &i));
        }
        nextLine(input, &i);

        var sum: i64 = 0;
        var different = true;
        while (different) {
            different = false;
            for (0..diffs.items.len - 1) |j| {
                diffs.items[j] = diffs.items[j + 1] - diffs.items[j];
                if (diffs.items[j] != diffs.items[0]) different = true;
            }
            sum += diffs.pop();
        }
        sum += diffs.pop();

        result += sum;
    }

    return result;
}

fn part2(alloc: Allocator, input: []const u8) !i64 {
    var result: i64 = 0;
    var i: usize = 0;
    var diffs = std.ArrayList(i64).init(alloc);
    defer diffs.deinit();
    var first = std.ArrayList(i64).init(alloc);
    defer first.deinit();
    while (i < input.len) {
        diffs.clearRetainingCapacity();
        try diffs.append(readInt(input, &i));
        while (i < input.len and input[i] == ' ') {
            i += 1;
            try diffs.append(readInt(input, &i));
        }
        nextLine(input, &i);

        var sum: i64 = 0;

        first.clearRetainingCapacity();
        var different = true;
        while (different) {
            different = false;
            try first.append(diffs.items[0]);
            for (0..diffs.items.len - 1) |j| {
                diffs.items[j] = diffs.items[j + 1] - diffs.items[j];
                if (diffs.items[j] != diffs.items[0]) different = true;
            }
            _ = diffs.pop();
        }
        try first.append(diffs.items[0]);
        for (0..first.items.len) |j| {
            sum = first.items[first.items.len - 1 - j] - sum;
        }

        result += sum;
    }

    return result;
}

test "part1" {
    try std.testing.expect(114 == try part1(std.testing.allocator,
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ));
}

test "part2" {
    try std.testing.expect(2 == try part2(std.testing.allocator,
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ));
}
