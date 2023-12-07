const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day07.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day07:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn readInt(comptime T: type, input: []const u8, i: *usize) T {
    var num: T = 0;
    while (i.* < input.len) : (i.* += 1) {
        switch (input[i.*]) {
            '0'...'9' => |c| num = num * 10 + c - '0',
            else => return num,
        }
    }
    return num;
}

fn skipUntil(input: []const u8, i: *usize, delimiter: u8) void {
    while (i.* < input.len and input[i.*] != delimiter) : (i.* += 1) {}
}

fn skip(input: []const u8, i: *usize, delimiter: u8) void {
    while (i.* < input.len and input[i.*] == delimiter) : (i.* += 1) {}
}

fn charToNum(char: u8) u8 {
    return switch (char) {
        '1'...'9' => char - '1',
        'T' => 9,
        'J' => 10,
        'Q' => 11,
        'K' => 12,
        'A' => 13,
        else => unreachable,
    };
}

fn asc(context: void, lhs: Hand, rhs: Hand) bool {
    _ = context;
    var i: usize = 0;
    while (lhs.cards[i] == rhs.cards[i]) : (i += 1) {}
    return charToNum(lhs.cards[i]) < charToNum(rhs.cards[i]);
}

const Hand = struct { cards: []const u8, val: u64 };

fn part1(alloc: Allocator, input: []const u8) !u64 {
    var five_kind = std.ArrayList(Hand).init(alloc);
    defer five_kind.deinit();
    var four_kind = std.ArrayList(Hand).init(alloc);
    defer four_kind.deinit();
    var full_house = std.ArrayList(Hand).init(alloc);
    defer full_house.deinit();
    var three_kind = std.ArrayList(Hand).init(alloc);
    defer three_kind.deinit();
    var two_pair = std.ArrayList(Hand).init(alloc);
    defer two_pair.deinit();
    var one_pair = std.ArrayList(Hand).init(alloc);
    defer one_pair.deinit();
    var high_card = std.ArrayList(Hand).init(alloc);
    defer high_card.deinit();

    var i: usize = 0;
    loop: while (i < input.len) {
        var j = i;
        skipUntil(input, &j, ' ');
        var counts: [14]u8 = [1]u8{0} ** 14;
        for (input[i..j]) |c| {
            counts[charToNum(c)] += 1;
        }
        j += 1;
        const val = readInt(u64, input, &j);
        const card = Hand{ .cards = input[i .. j - 1], .val = val };
        skipUntil(input, &j, '\n');
        j += 1;
        i = j;
        for (counts, 0..) |count, a| {
            switch (count) {
                0, 1 => {},
                2 => {
                    for (counts[a + 1 ..]) |count2| {
                        if (count2 == 3) {
                            try full_house.append(card);
                            continue :loop;
                        } else if (count2 == 2) {
                            try two_pair.append(card);
                            continue :loop;
                        }
                    }
                    try one_pair.append(card);
                    continue :loop;
                },
                3 => {
                    for (counts[a + 1 ..]) |count2| {
                        if (count2 == 2) {
                            try full_house.append(card);
                            continue :loop;
                        }
                    }
                    try three_kind.append(card);
                    continue :loop;
                },
                4 => {
                    try four_kind.append(card);
                    continue :loop;
                },
                5 => {
                    try five_kind.append(card);
                    continue :loop;
                },
                else => unreachable,
            }
        }
        try high_card.append(card);
    }
    std.mem.sortUnstable(Hand, five_kind.items, {}, asc);
    std.mem.sortUnstable(Hand, four_kind.items, {}, asc);
    std.mem.sortUnstable(Hand, full_house.items, {}, asc);
    std.mem.sortUnstable(Hand, three_kind.items, {}, asc);
    std.mem.sortUnstable(Hand, two_pair.items, {}, asc);
    std.mem.sortUnstable(Hand, one_pair.items, {}, asc);
    std.mem.sortUnstable(Hand, high_card.items, {}, asc);
    var result: u64 = 0;
    var rank: u64 = 1;
    for (high_card.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (one_pair.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (two_pair.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (three_kind.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (full_house.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (four_kind.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (five_kind.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    return result;
}

fn charToNum2(char: u8) u8 {
    return switch (char) {
        'J' => 0,
        '1'...'9' => char - '0',
        'T' => 10,
        'Q' => 11,
        'K' => 12,
        'A' => 13,
        else => unreachable,
    };
}
fn asc2(context: void, lhs: Hand, rhs: Hand) bool {
    _ = context;
    var i: usize = 0;
    while (lhs.cards[i] == rhs.cards[i]) : (i += 1) {}
    return charToNum2(lhs.cards[i]) < charToNum2(rhs.cards[i]);
}

fn part2(alloc: Allocator, input: []const u8) !u64 {
    var five_kind = std.ArrayList(Hand).init(alloc);
    defer five_kind.deinit();
    var four_kind = std.ArrayList(Hand).init(alloc);
    defer four_kind.deinit();
    var full_house = std.ArrayList(Hand).init(alloc);
    defer full_house.deinit();
    var three_kind = std.ArrayList(Hand).init(alloc);
    defer three_kind.deinit();
    var two_pair = std.ArrayList(Hand).init(alloc);
    defer two_pair.deinit();
    var one_pair = std.ArrayList(Hand).init(alloc);
    defer one_pair.deinit();
    var high_card = std.ArrayList(Hand).init(alloc);
    defer high_card.deinit();

    var i: usize = 0;
    loop: while (i < input.len) {
        var j = i;
        skipUntil(input, &j, ' ');
        var counts: [14]u8 = [1]u8{0} ** 14;
        var jokers: u8 = 0;
        for (input[i..j]) |c| {
            if (c == 'J') {
                jokers += 1;
            } else {
                counts[charToNum2(c)] += 1;
            }
        }
        if (jokers > 0) counts[std.mem.indexOfMax(u8, &counts)] += jokers;
        j += 1;
        const val = readInt(u64, input, &j);
        const card = Hand{ .cards = input[i .. j - 1], .val = val };
        skipUntil(input, &j, '\n');
        j += 1;
        i = j;
        for (counts, 0..) |count, a| {
            switch (count) {
                0, 1 => {},
                2 => {
                    for (counts[a + 1 ..]) |count2| {
                        if (count2 == 3) {
                            try full_house.append(card);
                            continue :loop;
                        } else if (count2 == 2) {
                            try two_pair.append(card);
                            continue :loop;
                        }
                    }
                    try one_pair.append(card);
                    continue :loop;
                },
                3 => {
                    for (counts[a + 1 ..]) |count2| {
                        if (count2 == 2) {
                            try full_house.append(card);
                            continue :loop;
                        }
                    }
                    try three_kind.append(card);
                    continue :loop;
                },
                4 => {
                    try four_kind.append(card);
                    continue :loop;
                },
                5 => {
                    try five_kind.append(card);
                    continue :loop;
                },
                else => unreachable,
            }
        }
        try high_card.append(card);
    }

    std.mem.sortUnstable(Hand, five_kind.items, {}, asc2);
    std.mem.sortUnstable(Hand, four_kind.items, {}, asc2);
    std.mem.sortUnstable(Hand, full_house.items, {}, asc2);
    std.mem.sortUnstable(Hand, three_kind.items, {}, asc2);
    std.mem.sortUnstable(Hand, two_pair.items, {}, asc2);
    std.mem.sortUnstable(Hand, one_pair.items, {}, asc2);
    std.mem.sortUnstable(Hand, high_card.items, {}, asc2);

    var result: u64 = 0;
    var rank: u64 = 1;
    for (high_card.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (one_pair.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (two_pair.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (three_kind.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (full_house.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (four_kind.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    for (five_kind.items) |card| {
        result += card.val * rank;
        rank += 1;
    }
    return result;
}

test "part1" {
    try std.testing.expect(6440 == try part1(std.testing.allocator,
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ));
}

test "part2" {
    try std.testing.expect(5905 == try part2(std.testing.allocator,
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ));
}
