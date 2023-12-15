const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day15.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = part1(buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day15:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn part1(input: []const u8) u32 {
    var i: usize = 0;
    var sum: u32 = 0;
    while (i < input.len and (input[i] != '\r' or input[i] != '\n')) {
        var hash: u8 = 0;
        while (i < input.len) : (i += 1) {
            switch (input[i]) {
                ',', '\r', '\n' => {
                    i += 1;
                    break;
                },
                else => |c| {
                    hash +%= c;
                    hash *%= 17;
                },
            }
        }
        sum += hash;
    }
    return sum;
}
const Entry = struct { key: []const u8, val: u8 };
fn findAndReplace(haystack: []Entry, needle: Entry) bool {
    for (haystack) |*straw| {
        if (std.mem.eql(u8, straw.key, needle.key)) {
            straw.val = needle.val;
            return true;
        }
    }
    return false;
}
fn findAndRemove(haystack: *std.ArrayList(Entry), key: []const u8) void {
    for (haystack.items, 0..) |straw, i| {
        if (std.mem.eql(u8, straw.key, key)) {
            _ = haystack.orderedRemove(i);
            return;
        }
    }
}
fn part2(alloc: Allocator, input: []const u8) !usize {
    var i: usize = 0;
    var boxes: [256]std.ArrayList(Entry) = undefined;
    for (&boxes) |*box| box.* = std.ArrayList(Entry).init(alloc);
    defer for (&boxes) |*box| box.deinit();

    while (i < input.len and (input[i] != '\r' or input[i] != '\n')) {
        var hash: u8 = 0;
        const start = i;
        while (i < input.len) : (i += 1) {
            switch (input[i]) {
                '=' => {
                    var entry = .{ .key = input[start..i], .val = input[i + 1] - '0' };
                    if (!findAndReplace(boxes[hash].items, entry)) {
                        try boxes[hash].append(entry);
                    }
                    i += 3;
                    break;
                },
                '-' => {
                    findAndRemove(&boxes[hash], input[start..i]);
                    i += 2;
                    break;
                },
                else => |c| {
                    hash +%= c;
                    hash *%= 17;
                },
            }
        }
    }
    var sum: usize = 0;
    for (boxes, 1..) |box, b| {
        for (box.items, 1..) |item, j| {
            sum += b * j * item.val;
        }
    }
    return sum;
}

test "part1" {
    try std.testing.expect(1320 == part1(
        \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    ));
}

test "part2" {
    try std.testing.expect(145 == try part2(std.testing.allocator,
        \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    ));
}
