const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day19.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day19:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn skipUntil(input: []const u8, i: *usize, delimiter: u8) void {
    while (i.* < input.len and input[i.*] != delimiter) i.* += 1;
}
fn skipUntilEither(input: []const u8, i: *usize, delimiter1: u8, delimiter2: u8) void {
    while (i.* < input.len and input[i.*] != delimiter1 and input[i.*] != delimiter2) i.* += 1;
}

fn nextLine(input: []const u8, i: *usize) void {
    skipUntil(input, i, '\n');
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

const Key = union(enum) {
    accept,
    reject,
    goto: []const u8,
};

const Check = struct {
    val: u64,
    goto: Key,
};

const Rule = union(enum) {
    a_lt: Check,
    a_gt: Check,
    a_eq: Check,

    s_lt: Check,
    s_gt: Check,
    s_eq: Check,

    m_lt: Check,
    m_gt: Check,
    m_eq: Check,

    x_lt: Check,
    x_gt: Check,
    x_eq: Check,

    goto: Key,
};

fn addChecks(checks: *std.ArrayList(Rule), input: []const u8, i: *usize) !void {
    while (true) {
        switch (input[i.* + 1]) {
            '>' => {
                const part = input[i.*];
                i.* += 2;
                const val = readInt(u64, input, i);
                i.* += 1;
                const key = switch (input[i.*]) {
                    'A' => blk: {
                        i.* += 1;
                        break :blk .accept;
                    },
                    'R' => blk: {
                        i.* += 1;
                        break :blk .reject;
                    },
                    else => blk: {
                        const start = i.*;
                        skipUntilEither(input, i, ',', '}');
                        break :blk Key{ .goto = input[start..i.*] };
                    },
                };
                var check = Check{ .val = val, .goto = key };
                switch (part) {
                    'x' => try checks.append(Rule{ .x_gt = check }),
                    'a' => try checks.append(Rule{ .a_gt = check }),
                    's' => try checks.append(Rule{ .s_gt = check }),
                    'm' => try checks.append(Rule{ .m_gt = check }),
                    else => unreachable,
                }
            },
            '<' => {
                const part = input[i.*];
                i.* += 2;
                const val = readInt(u64, input, i);
                i.* += 1;
                const key = switch (input[i.*]) {
                    'A' => blk: {
                        i.* += 1;
                        break :blk .accept;
                    },
                    'R' => blk: {
                        i.* += 1;
                        break :blk .reject;
                    },
                    else => blk: {
                        const start = i.*;
                        skipUntilEither(input, i, ',', '}');
                        break :blk Key{ .goto = input[start..i.*] };
                    },
                };
                var check = Check{ .val = val, .goto = key };
                switch (part) {
                    'x' => try checks.append(Rule{ .x_lt = check }),
                    'a' => try checks.append(Rule{ .a_lt = check }),
                    's' => try checks.append(Rule{ .s_lt = check }),
                    'm' => try checks.append(Rule{ .m_lt = check }),
                    else => unreachable,
                }
            },
            '=' => {
                const part = input[i.*];
                i.* += 2;
                const val = readInt(u64, input, i);
                i.* += 1;
                const key = switch (input[i.*]) {
                    'A' => blk: {
                        i.* += 1;
                        break :blk .accept;
                    },
                    'R' => blk: {
                        i.* += 1;
                        break :blk .reject;
                    },
                    else => blk: {
                        const start = i.*;
                        skipUntilEither(input, i, ',', '}');
                        break :blk Key{ .goto = input[start..i.*] };
                    },
                };
                var check = Check{ .val = val, .goto = key };
                switch (part) {
                    'x' => try checks.append(Rule{ .x_eq = check }),
                    'a' => try checks.append(Rule{ .a_eq = check }),
                    's' => try checks.append(Rule{ .s_eq = check }),
                    'm' => try checks.append(Rule{ .m_eq = check }),
                    else => unreachable,
                }
            },
            ',', '}' => {
                switch (input[i.*]) {
                    'A' => try checks.append(Rule{ .goto = .accept }),
                    'R' => try checks.append(Rule{ .goto = .reject }),
                    else => unreachable,
                }

                i.* += 1;
            },
            else => {
                const start = i.*;
                skipUntilEither(input, i, ',', '}');
                try checks.append(Rule{ .goto = Key{ .goto = input[start..i.*] } });
            },
        }
        if (input[i.*] != '}') {
            i.* += 1;
        } else {
            break;
        }
    }
}

fn addRules(alloc: Allocator, rules: *std.StringHashMap([]const Rule), input: []const u8, i: *usize) !void {
    while (input[i.*] != '\r' and input[i.*] != '\n') {
        var start = i.*;
        skipUntil(input, i, '{');
        var name = input[start..i.*];
        i.* += 1;
        var checks = std.ArrayList(Rule).init(alloc);
        errdefer checks.deinit();
        try addChecks(&checks, input, i);
        try rules.put(name, try checks.toOwnedSlice());
        nextLine(input, i);
    }
}

fn readRatings(input: []const u8, i: *usize) [4]u64 {
    var ratings: [4]u64 = undefined;
    for (&ratings) |*rating| {
        i.* += 3;
        rating.* = readInt(u64, input, i);
    }
    i.* += 1;
    nextLine(input, i);
    return ratings;
}

fn gotoKey(goto: Key, key: *[]const u8, ratings: [4]u64) ?u64 {
    switch (goto) {
        .accept => return ratings[0] + ratings[1] + ratings[2] + ratings[3],
        .reject => return 0,
        .goto => |next| {
            key.* = next;
            return null;
        },
    }
}

fn acceptedSum(rules: std.StringHashMap([]const Rule), ratings: [4]u64) u64 {
    var key: []const u8 = "in";
    while (true) {
        if (rules.get(key)) |checks| {
            for (checks) |check| {
                switch (check) {
                    .x_lt => |x_lt| if (ratings[0] < x_lt.val) {
                        if (gotoKey(x_lt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .x_gt => |x_gt| if (ratings[0] > x_gt.val) {
                        if (gotoKey(x_gt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .x_eq => |x_eq| if (ratings[0] == x_eq.val) {
                        if (gotoKey(x_eq.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .m_lt => |m_lt| if (ratings[1] < m_lt.val) {
                        if (gotoKey(m_lt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .m_gt => |m_gt| if (ratings[1] > m_gt.val) {
                        if (gotoKey(m_gt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .m_eq => |m_eq| if (ratings[1] == m_eq.val) {
                        if (gotoKey(m_eq.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .a_lt => |a_lt| if (ratings[2] < a_lt.val) {
                        if (gotoKey(a_lt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .a_gt => |a_gt| if (ratings[2] > a_gt.val) {
                        if (gotoKey(a_gt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .a_eq => |a_eq| if (ratings[2] == a_eq.val) {
                        if (gotoKey(a_eq.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .s_lt => |s_lt| if (ratings[3] < s_lt.val) {
                        if (gotoKey(s_lt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .s_gt => |s_gt| if (ratings[3] > s_gt.val) {
                        if (gotoKey(s_gt.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },
                    .s_eq => |s_eq| if (ratings[3] == s_eq.val) {
                        if (gotoKey(s_eq.goto, &key, ratings)) |sum| {
                            return sum;
                        } else {
                            break;
                        }
                    },

                    .goto => |goto| if (gotoKey(goto, &key, ratings)) |sum| {
                        return sum;
                    } else {
                        break;
                    },
                }
            }
        }
    }
}

fn part1(alloc: Allocator, input: []const u8) !u64 {
    var rules = std.StringHashMap([]const Rule).init(alloc);
    defer {
        var iter = rules.valueIterator();
        while (iter.next()) |next| alloc.free(next.*);
        rules.deinit();
    }
    var i: usize = 0;
    try addRules(alloc, &rules, input, &i);
    nextLine(input, &i);
    var sum: u64 = 0;
    while (i < input.len) {
        sum += acceptedSum(rules, readRatings(input, &i));
    }
    return sum;
}

fn numAcceptedRules(rules: std.StringHashMap([]const Rule), checks: []const Rule, lower: *[4]u64, upper: *[4]u64) u64 {
    var result: u64 = 0;
    for (checks, 0..) |check, i| {
        switch (check) {
            .x_lt => |ch| if (lower[0] <= ch.val and ch.val <= upper[0]) {
                switch (ch.goto) {
                    .accept => {
                        result += (ch.val - lower[0]) * (upper[1] - lower[1] + 1) * (upper[2] - lower[2] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        upper[0] = ch.val - 1;
                        result += numAccepted(rules, lower, upper, goto);
                        upper.* = tmp_upper;
                        lower.* = tmp_lower;
                    },
                }
                lower[0] = ch.val;
            },
            .x_gt => |ch| if (lower[0] <= ch.val and ch.val <= upper[0]) {
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - ch.val) * (upper[1] - lower[1] + 1) * (upper[2] - lower[2] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        lower[0] = ch.val + 1;
                        result += numAccepted(rules, lower, upper, goto);
                        lower.* = tmp_lower;
                        upper.* = tmp_upper;
                    },
                }
                upper[0] = ch.val;
            },
            .x_eq => |ch| if (lower[0] <= ch.val and ch.val <= upper[0]) {
                var tmp1 = lower[0];
                var tmp2 = upper[0];
                switch (ch.goto) {
                    .accept => {
                        result += (upper[1] - lower[1] + 1) * (upper[2] - lower[2] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        lower[0] = ch.val;
                        upper[0] = ch.val;
                        result += numAccepted(rules, lower, upper, goto);
                    },
                }
                var new_upper = upper.*;
                var new_lower = lower.*;
                new_upper[0] = tmp2;
                new_lower[0] = ch.val + 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], &new_lower, &new_upper);

                lower[0] = tmp1;
                upper[0] = ch.val - 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], lower, upper);

                break;
            },

            .m_lt => |ch| if (lower[1] <= ch.val and ch.val <= upper[1]) {
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (ch.val - lower[1]) * (upper[2] - lower[2] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        upper[1] = ch.val - 1;
                        result += numAccepted(rules, lower, upper, goto);
                        upper.* = tmp_upper;
                        lower.* = tmp_lower;
                    },
                }
                lower[1] = ch.val;
            },
            .m_gt => |ch| if (lower[1] <= ch.val and ch.val <= upper[1]) {
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - ch.val) * (upper[2] - lower[2] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        lower[1] = ch.val + 1;
                        result += numAccepted(rules, lower, upper, goto);
                        lower.* = tmp_lower;
                        upper.* = tmp_upper;
                    },
                }
                upper[1] = ch.val;
            },
            .m_eq => |ch| if (lower[1] <= ch.val and ch.val <= upper[1]) {
                var tmp1 = lower[1];
                var tmp2 = upper[1];
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[2] - lower[2] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        lower[1] = ch.val;
                        upper[1] = ch.val;
                        result += numAccepted(rules, lower, upper, goto);
                    },
                }
                var new_upper = upper.*;
                var new_lower = lower.*;
                new_upper[1] = tmp2;
                new_lower[1] = ch.val + 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], &new_lower, &new_upper);

                lower[1] = tmp1;
                upper[1] = ch.val - 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], lower, upper);

                break;
            },

            .a_lt => |ch| if (lower[2] <= ch.val and ch.val <= upper[2]) {
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - lower[1] + 1) * (ch.val - lower[2]) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        upper[2] = ch.val - 1;
                        result += numAccepted(rules, lower, upper, goto);
                        upper.* = tmp_upper;
                        lower.* = tmp_lower;
                    },
                }
                lower[2] = ch.val;
            },
            .a_gt => |ch| if (lower[2] <= ch.val and ch.val <= upper[2]) {
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - lower[1] + 1) * (upper[2] - ch.val) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        lower[2] = ch.val + 1;
                        result += numAccepted(rules, lower, upper, goto);
                        lower.* = tmp_lower;
                        upper.* = tmp_upper;
                    },
                }
                upper[2] = ch.val;
            },
            .a_eq => |ch| if (lower[2] <= ch.val and ch.val <= upper[2]) {
                var tmp1 = lower[2];
                var tmp2 = upper[2];
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - lower[1] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        lower[2] = ch.val;
                        upper[2] = ch.val;
                        result += numAccepted(rules, lower, upper, goto);
                    },
                }
                var new_upper = upper.*;
                var new_lower = lower.*;
                new_upper[2] = tmp2;
                new_lower[2] = ch.val + 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], &new_lower, &new_upper);

                lower[2] = tmp1;
                upper[2] = ch.val - 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], lower, upper);

                break;
            },

            .s_lt => |ch| if (lower[3] <= ch.val and ch.val <= upper[3]) {
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - lower[1] + 1) * (upper[2] - lower[2] + 1) * (ch.val - lower[3]);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        upper[3] = ch.val - 1;
                        result += numAccepted(rules, lower, upper, goto);
                        upper.* = tmp_upper;
                        lower.* = tmp_lower;
                    },
                }
                lower[3] = ch.val;
            },
            .s_gt => |ch| if (lower[3] <= ch.val and ch.val <= upper[3]) {
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - lower[1] + 1) * (upper[2] - lower[2] + 1) * (upper[3] - ch.val);
                    },
                    .reject => {},
                    .goto => |goto| {
                        var tmp_upper = upper.*;
                        var tmp_lower = lower.*;
                        lower[3] = ch.val + 1;
                        result += numAccepted(rules, lower, upper, goto);
                        lower.* = tmp_lower;
                        upper.* = tmp_upper;
                    },
                }
                upper[3] = ch.val;
            },
            .s_eq => |ch| if (lower[3] <= ch.val and ch.val <= upper[3]) {
                var tmp1 = lower[3];
                var tmp2 = upper[3];
                switch (ch.goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - lower[1] + 1) * (upper[2] - lower[2] + 1);
                    },
                    .reject => {},
                    .goto => |goto| {
                        lower[3] = ch.val;
                        upper[3] = ch.val;
                        result += numAccepted(rules, lower, upper, goto);
                    },
                }
                var new_upper = upper.*;
                var new_lower = lower.*;
                new_upper[3] = tmp2;
                new_lower[3] = ch.val + 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], &new_lower, &new_upper);

                lower[3] = tmp1;
                upper[3] = ch.val - 1;
                result += numAcceptedRules(rules, checks[i + 1 ..], lower, upper);

                break;
            },

            .goto => |goto| {
                switch (goto) {
                    .accept => {
                        result += (upper[0] - lower[0] + 1) * (upper[1] - lower[1] + 1) * (upper[2] - lower[2] + 1) * (upper[3] - lower[3] + 1);
                    },
                    .reject => {},
                    .goto => |go| {
                        result += numAccepted(rules, lower, upper, go);
                    },
                }
            },
        }
    }
    return result;
}

fn numAccepted(rules: std.StringHashMap([]const Rule), lower: *[4]u64, upper: *[4]u64, key: []const u8) u64 {
    var result: u64 = 0;
    if (rules.get(key)) |checks| {
        result = numAcceptedRules(rules, checks, lower, upper);
        return result;
    } else {
        unreachable;
    }
}

fn part2(alloc: Allocator, input: []const u8) !u64 {
    var rules = std.StringHashMap([]const Rule).init(alloc);
    defer {
        var iter = rules.valueIterator();
        while (iter.next()) |next| alloc.free(next.*);
        rules.deinit();
    }
    var i: usize = 0;
    try addRules(alloc, &rules, input, &i);
    var lower = [4]u64{ 1, 1, 1, 1 };
    var upper = [4]u64{ 4000, 4000, 4000, 4000 };
    const result = numAccepted(rules, &lower, &upper, "in");

    return result;
}

test "part1" {
    try std.testing.expect(19114 == try part1(std.testing.allocator,
        \\px{a<2006:qkq,m>2090:A,rfg}
        \\pv{a>1716:R,A}
        \\lnx{m>1548:A,A}
        \\rfg{s<537:gd,x>2440:R,A}
        \\qs{s>3448:A,lnx}
        \\qkq{x<1416:A,crn}
        \\crn{x>2662:A,R}
        \\in{s<1351:px,qqz}
        \\qqz{s>2770:qs,m<1801:hdj,R}
        \\gd{a>3333:R,R}
        \\hdj{m>838:A,pv}
        \\
        \\{x=787,m=2655,a=1222,s=2876}
        \\{x=1679,m=44,a=2067,s=496}
        \\{x=2036,m=264,a=79,s=2244}
        \\{x=2461,m=1339,a=466,s=291}
        \\{x=2127,m=1623,a=2188,s=1013}
        \\
    ));
}

test "part2" {
    try std.testing.expect(167409079868000 == try part2(std.testing.allocator,
        \\px{a<2006:qkq,m>2090:A,rfg}
        \\pv{a>1716:R,A}
        \\lnx{m>1548:A,A}
        \\rfg{s<537:gd,x>2440:R,A}
        \\qs{s>3448:A,lnx}
        \\qkq{x<1416:A,crn}
        \\crn{x>2662:A,R}
        \\in{s<1351:px,qqz}
        \\qqz{s>2770:qs,m<1801:hdj,R}
        \\gd{a>3333:R,R}
        \\hdj{m>838:A,pv}
        \\
        \\{x=787,m=2655,a=1222,s=2876}
        \\{x=1679,m=44,a=2067,s=496}
        \\{x=2036,m=264,a=79,s=2244}
        \\{x=2461,m=1339,a=466,s=291}
        \\{x=2127,m=1623,a=2188,s=1013}
        \\
    ));
}
test "other" {
    try std.testing.expect(4000 * 4000 * 4000 * (3999) == try part2(std.testing.allocator,
        \\in{s=1351:R,A}
        \\
        \\
    ));
}
