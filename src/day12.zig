const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day12.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day12:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    while (i.* < input.len and (input[i.*] == '\r' or input[i.*] == '\n')) : (i.* += 1) {}
}

fn readLayout(layout: *std.ArrayList(u2), input: []const u8, i: *usize) !void {
    while (input[i.*] != ' ') : (i.* += 1) {
        try layout.append(switch (input[i.*]) {
            '?' => 1,
            '#' => 2,
            else => 0,
        });
    }
}

fn readArrangement(arrangement: *std.ArrayList(u8), input: []const u8, i: *usize) !void {
    var num: u8 = 0;
    while (i.* < input.len and input[i.*] != '\r' and input[i.*] != '\n') : (i.* += 1) {
        switch (input[i.*]) {
            '0'...'9' => |c| num = num * 10 + c - '0',
            ',' => {
                try arrangement.append(num);
                num = 0;
            },
            else => unreachable,
        }
    }
    try arrangement.append(num);
}

fn possibilities(layout: []u2, arrangement: []u8, curr: u8) usize {
    var count: usize = 0;
    var current = curr;
    var arr: usize = 0;
    for (0..layout.len) |i| {
        if (arr == arrangement.len) {
            for (layout[i..]) |l| if (l == 2) return count;
            break;
        }
        switch (layout[i]) {
            0 => {
                if (current == arrangement[arr]) {
                    current = 0;
                    arr += 1;
                } else if (current != 0) {
                    return count;
                }
            },
            1 => {
                if (current == arrangement[arr]) {
                    current = 0;
                    arr += 1;
                } else if (current > arrangement[arr]) {
                    return count;
                } else if (current == 0) {
                    var tmp = possibilities(layout[i + 1 ..], arrangement[arr..], 1);
                    count += tmp;
                } else {
                    current += 1;
                }
            },
            2 => {
                if (current < arrangement[arr]) {
                    current += 1;
                } else {
                    return count;
                }
            },
            3 => unreachable,
        }
    }
    if (arr == arrangement.len or (arrangement.len == arr + 1 and current == arrangement[arr])) {
        count += 1;
    }
    return count;
}

fn part1(alloc: Allocator, input: []const u8) !usize {
    var i: usize = 0;
    var count: usize = 0;
    var layout = std.ArrayList(u2).init(alloc);
    defer layout.deinit();
    var arrangement = std.ArrayList(u8).init(alloc);
    defer arrangement.deinit();
    while (i < input.len) {
        try readLayout(&layout, input, &i);
        defer layout.clearRetainingCapacity();
        i += 1;
        try readArrangement(&arrangement, input, &i);
        defer arrangement.clearRetainingCapacity();
        nextLine(input, &i);

        count += possibilities(layout.items, arrangement.items, 0);
    }

    return count;
}

fn possibilities2(alloc: Allocator, layout: []u2, arrangement: []u8) !usize {
    var dp = try alloc.alloc([][]usize, layout.len + 1);
    for (dp) |*a| {
        a.* = try alloc.alloc([]usize, arrangement.len + 1);
        for (a.*) |*b| {
            b.* = try alloc.alloc(usize, layout.len + 1);
            @memset(b.*, 0);
        }
    }
    defer {
        for (dp) |*a| {
            for (a.*) |*b| {
                alloc.free(b.*);
            }
            alloc.free(a.*);
        }
        alloc.free(dp);
    }

    dp[layout.len][arrangement.len][0] = 1;
    dp[layout.len][arrangement.len - 1][arrangement[arrangement.len - 1]] = 1;

    for (0..layout.len) |p| {
        const pos = layout.len - (p + 1);
        for (arrangement, 0..) |max_count, group| {
            for (0..max_count + 1) |count| {
                switch (layout[pos]) {
                    0 => {
                        if (count == 0) {
                            dp[pos][group][count] += dp[pos + 1][group][0];
                        } else if (group < arrangement.len and arrangement[group] == count) {
                            dp[pos][group][count] += dp[pos + 1][group + 1][0];
                        }
                    },
                    1 => {
                        if (count == 0) {
                            dp[pos][group][count] += dp[pos + 1][group][0];
                        } else if (group < arrangement.len and arrangement[group] == count) {
                            dp[pos][group][count] += dp[pos + 1][group + 1][0];
                        }
                        dp[pos][group][count] += dp[pos + 1][group][count + 1];
                    },
                    2 => {
                        dp[pos][group][count] += dp[pos + 1][group][count + 1];
                    },
                    3 => unreachable,
                }
            }
        }
        switch (layout[pos]) {
            0, 1 => {
                dp[pos][arrangement.len][0] += dp[pos + 1][arrangement.len][0];
            },
            else => {},
        }
    }

    return dp[0][0][0];
}

fn part2(alloc: Allocator, input: []const u8) !usize {
    var i: usize = 0;
    var count: usize = 0;
    var layout = std.ArrayList(u2).init(alloc);
    defer layout.deinit();
    var arrangement = std.ArrayList(u8).init(alloc);
    defer arrangement.deinit();
    while (i < input.len) {
        try readLayout(&layout, input, &i);
        var len = layout.items.len;
        try layout.ensureTotalCapacity(layout.items.len * 5 + 4);
        for (0..4) |_| {
            layout.appendAssumeCapacity(1);
            layout.appendSliceAssumeCapacity(layout.items[0..len]);
        }

        i += 1;

        try readArrangement(&arrangement, input, &i);
        len = arrangement.items.len;
        try arrangement.ensureTotalCapacity(arrangement.items.len * 5);
        for (0..4) |_| {
            arrangement.appendSliceAssumeCapacity(arrangement.items[0..len]);
        }

        nextLine(input, &i);

        count += try possibilities2(alloc, layout.items, arrangement.items);

        layout.clearRetainingCapacity();
        arrangement.clearRetainingCapacity();
    }
    return count;
}

test "part1" {
    try std.testing.expect(21 == try part1(std.testing.allocator,
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ));
}

test "part2" {
    try std.testing.expect(525152 == try part2(std.testing.allocator,
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ));
}
