const std = @import("std");
const Allocator = std.mem.Allocator;
const tokenizeAny = std.mem.tokenizeAny;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day02.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(buffer);
    const p1_time = timer.lap();
    const p2 = try part2(buffer);
    const p2_time = timer.read();
    try stdout.print("Day02:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn part1(input: []const u8) !u32 {
    const max_red: u32 = 12;
    const max_green: u32 = 13;
    const max_blue: u32 = 14;
    var result: u32 = 0;
    var lines = tokenizeAny(u8, input, "\r\n");
    var round: u32 = 0;
    game: while (lines.next()) |line| {
        round += 1;
        var start = indexOf(u8, line, ":").?;
        var groups = tokenizeAny(u8, line[start + 2 ..], ";");
        while (groups.next()) |group| {
            var colours = tokenizeAny(u8, group, " ");
            while (colours.next()) |amount| {
                const num = try parseInt(u32, amount, 10);

                switch (colours.next().?[0]) {
                    'r' => if (num > max_red) continue :game,
                    'g' => if (num > max_green) continue :game,
                    'b' => if (num > max_blue) continue :game,
                    else => unreachable,
                }
            }
        }
        result += round;
    }
    return result;
}

fn part2(input: []const u8) !usize {
    var result: u32 = 0;
    var lines = tokenizeAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        var max_red: u32 = 0;
        var max_green: u32 = 0;
        var max_blue: u32 = 0;
        var start = indexOf(u8, line, ":").?;
        var colours = tokenizeAny(u8, line[start + 2 ..], " ;");
        while (colours.next()) |amount| {
            const num = try parseInt(u32, amount, 10);
            switch (colours.next().?[0]) {
                'r' => if (num > max_red) {
                    max_red = num;
                },
                'g' => if (num > max_green) {
                    max_green = num;
                },
                'b' => if (num > max_blue) {
                    max_blue = num;
                },
                else => unreachable,
            }
        }
        result += max_red * max_green * max_blue;
    }
    return result;
}

test "part1" {
    try std.testing.expect(8 == try part1(
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ));
}

test "part2" {
    try std.testing.expect(2286 == try part2(
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ));
}
