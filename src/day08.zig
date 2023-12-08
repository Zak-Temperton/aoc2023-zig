const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day08.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day08:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn readWord(input: []const u8, i: *usize) []const u8 {
    const start = i.*;
    while (i.* < input.len and input[i.*] >= 'A' and input[i.*] <= 'Z') : (i.* += 1) {}
    return input[start..i.*];
}

fn nextLine(input: []const u8, i: *usize) void {
    while (i.* < input.len and (input[i.*] == '\r' or input[i.*] == '\n')) : (i.* += 1) {}
}

fn stringToNode(str: []const u8) u32 {
    var node: u32 = 0;
    for (str) |c| {
        node <<= 5;
        node += c - 'A';
    }
    return node;
}

fn nodeToString(node: u32) [3]u8 {
    var n = node;
    var str: [3]u8 = undefined;
    for (&str) |*c| {
        c.* = @truncate('A' + (n & 0x1F));
        n >>= 5;
    }
    return str;
}

fn part1(alloc: Allocator, input: []const u8) !u64 {
    var i: usize = 0;
    const path = readWord(input, &i);
    nextLine(input, &i);
    nextLine(input, &i);

    var paths = std.AutoHashMap(u32, [2]u32).init(alloc);
    defer paths.deinit();

    while (i < input.len) {
        const key = readWord(input, &i);
        i += 4;
        const left = readWord(input, &i);
        i += 2;
        const right = readWord(input, &i);
        i += 1;
        nextLine(input, &i);
        try paths.put(stringToNode(key), .{ stringToNode(left), stringToNode(right) });
    }

    var current = stringToNode("AAA");
    const target = stringToNode("ZZZ");
    var steps: u64 = 0;
    while (true) {
        for (path) |p| {
            var node = paths.get(current).?;
            if (current == target) return steps;
            if (p == 'L') {
                current = node[0];
            } else {
                current = node[1];
            }
            steps += 1;
        }
    }
}

fn part2(alloc: Allocator, input: []const u8) !u64 {
    var i: usize = 0;
    const path = readWord(input, &i);
    nextLine(input, &i);
    nextLine(input, &i);

    var paths = std.AutoHashMap(u32, [2]u32).init(alloc);
    defer paths.deinit();
    var current = std.ArrayList(u32).init(alloc);
    defer current.deinit();
    while (i < input.len) {
        const key = readWord(input, &i);
        i += 4;
        const left = readWord(input, &i);
        i += 2;
        const right = readWord(input, &i);
        i += 1;
        nextLine(input, &i);
        if (key[2] == 'A') {
            try current.append(stringToNode(key));
        }
        try paths.put(stringToNode(key), .{ stringToNode(left), stringToNode(right) });
    }

    var starting = try std.ArrayList(u64).initCapacity(alloc, current.items.len);
    defer starting.deinit();

    for (current.items) |*curr| {
        var steps: u64 = 0;
        loop: while (true) {
            for (path) |p| {
                var node = paths.get(curr.*).?;
                if (curr.* & 0x1F == 25) break :loop;
                if (p == 'L') {
                    curr.* = node[0];
                } else {
                    curr.* = node[1];
                }
                steps += 1;
            }
        }
        try starting.append(steps);
    }

    var steps: u64 = 1;
    for (starting.items) |n| {
        steps = (steps / std.math.gcd(n, steps)) * n;
    }
    return steps;
}

test "part1" {
    try std.testing.expect(2 == try part1(std.testing.allocator,
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ
    ));
}

test "part2" {
    try std.testing.expect(6 == try part2(std.testing.allocator,
        \\LR
        \\
        \\AAA = (AAB, XXX)
        \\AAB = (XXX, AAZ)
        \\AAZ = (AAB, XXX)
        \\BBA = (BBB, XXX)
        \\BBB = (BBC, BBC)
        \\BBC = (BBZ, BBZ)
        \\BBZ = (BBB, BBB)
        \\XXX = (XXX, XXX)
    ));
}
