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

const Hand = struct { cards: []const u8, val: u64 };

const Game = struct {
    five_kind: std.ArrayList(Hand),
    four_kind: std.ArrayList(Hand),
    full_house: std.ArrayList(Hand),
    three_kind: std.ArrayList(Hand),
    two_pair: std.ArrayList(Hand),
    one_pair: std.ArrayList(Hand),
    high_card: std.ArrayList(Hand),

    fn init(alloc: Allocator) Game {
        return .{
            .five_kind = std.ArrayList(Hand).init(alloc),
            .four_kind = std.ArrayList(Hand).init(alloc),
            .full_house = std.ArrayList(Hand).init(alloc),
            .three_kind = std.ArrayList(Hand).init(alloc),
            .two_pair = std.ArrayList(Hand).init(alloc),
            .one_pair = std.ArrayList(Hand).init(alloc),
            .high_card = std.ArrayList(Hand).init(alloc),
        };
    }

    fn deinit(self: *Game) void {
        self.five_kind.deinit();
        self.four_kind.deinit();
        self.full_house.deinit();
        self.three_kind.deinit();
        self.two_pair.deinit();
        self.one_pair.deinit();
        self.high_card.deinit();
    }

    fn appendHand(self: *Game, hand: Hand, counts: [14]u8) !void {
        for (counts, 0..) |count, a| {
            switch (count) {
                0, 1 => {},
                2 => {
                    for (counts[a + 1 ..]) |count2| {
                        if (count2 == 3) {
                            try self.full_house.append(hand);
                            return;
                        } else if (count2 == 2) {
                            try self.two_pair.append(hand);
                            return;
                        }
                    }
                    try self.one_pair.append(hand);
                    return;
                },
                3 => {
                    for (counts[a + 1 ..]) |count2| {
                        if (count2 == 2) {
                            try self.full_house.append(hand);
                            return;
                        }
                    }
                    try self.three_kind.append(hand);
                    return;
                },
                4 => {
                    try self.four_kind.append(hand);
                    return;
                },
                5 => {
                    try self.five_kind.append(hand);
                    return;
                },
                else => unreachable,
            }
        }
        try self.high_card.append(hand);
    }

    fn solve(self: *Game, comptime lessThanFn: fn (void, lhs: Hand, rhs: Hand) bool) u64 {
        std.mem.sortUnstable(Hand, self.five_kind.items, {}, lessThanFn);
        std.mem.sortUnstable(Hand, self.four_kind.items, {}, lessThanFn);
        std.mem.sortUnstable(Hand, self.full_house.items, {}, lessThanFn);
        std.mem.sortUnstable(Hand, self.three_kind.items, {}, lessThanFn);
        std.mem.sortUnstable(Hand, self.two_pair.items, {}, lessThanFn);
        std.mem.sortUnstable(Hand, self.one_pair.items, {}, lessThanFn);
        std.mem.sortUnstable(Hand, self.high_card.items, {}, lessThanFn);
        var result: u64 = 0;
        var rank: u64 = 1;
        for (self.high_card.items) |card| {
            result += card.val * rank;
            rank += 1;
        }
        for (self.one_pair.items) |card| {
            result += card.val * rank;
            rank += 1;
        }
        for (self.two_pair.items) |card| {
            result += card.val * rank;
            rank += 1;
        }
        for (self.three_kind.items) |card| {
            result += card.val * rank;
            rank += 1;
        }
        for (self.full_house.items) |card| {
            result += card.val * rank;
            rank += 1;
        }
        for (self.four_kind.items) |card| {
            result += card.val * rank;
            rank += 1;
        }
        for (self.five_kind.items) |card| {
            result += card.val * rank;
            rank += 1;
        }
        return result;
    }
};

fn asc(context: void, lhs: Hand, rhs: Hand) bool {
    _ = context;
    var i: usize = 0;
    while (lhs.cards[i] == rhs.cards[i]) : (i += 1) {}
    return charToNum(lhs.cards[i]) < charToNum(rhs.cards[i]);
}

fn part1(alloc: Allocator, input: []const u8) !u64 {
    var game = Game.init(alloc);
    defer game.deinit();
    var i: usize = 0;
    while (i < input.len) {
        var j = i;
        skipUntil(input, &j, ' ');
        var counts: [14]u8 = [1]u8{0} ** 14;
        const cards = input[i..j];
        for (cards) |c| {
            counts[charToNum(c)] += 1;
        }
        j += 1;
        const val = readInt(u64, input, &j);
        const hand = Hand{ .cards = cards, .val = val };
        skipUntil(input, &j, '\n');
        j += 1;
        i = j;
        try game.appendHand(hand, counts);
    }

    return game.solve(asc);
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
    var game = Game.init(alloc);
    defer game.deinit();
    var i: usize = 0;
    while (i < input.len) {
        var j = i;
        skipUntil(input, &j, ' ');
        var counts: [14]u8 = [1]u8{0} ** 14;
        var jokers: u8 = 0;
        const cards = input[i..j];
        for (cards) |c| {
            if (c == 'J') {
                jokers += 1;
            } else {
                counts[charToNum2(c)] += 1;
            }
        }
        if (jokers > 0) counts[std.mem.indexOfMax(u8, &counts)] += jokers;
        j += 1;
        const val = readInt(u64, input, &j);
        const hand = Hand{ .cards = cards, .val = val };
        skipUntil(input, &j, '\n');
        j += 1;
        i = j;

        try game.appendHand(hand, counts);
    }

    return game.solve(asc2);
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
