const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");
const day04 = @import("day04.zig");
const day05 = @import("day05.zig");
const day06 = @import("day06.zig");
const day07 = @import("day07.zig");
const day08 = @import("day08.zig");
const day09 = @import("day09.zig");
const day10 = @import("day10.zig");
const day11 = @import("day11.zig");
//const day12 = @import("day12.zig");
//const day13 = @import("day13.zig");
//const day14 = @import("day14.zig");
//const day15 = @import("day15.zig");
//const day16 = @import("day16.zig");
//const day17 = @import("day17.zig");
//const day18 = @import("day18.zig");
//const day19 = @import("day19.zig");
//const day20 = @import("day20.zig");
//const day21 = @import("day21.zig");
//const day22 = @import("day22.zig");
//const day23 = @import("day23.zig");
//const day24 = @import("day24.zig");
//const day25 = @import("day25.zig");

const Day = enum {
    day01,
    day02,
    day03,
    day04,
    day05,
    day06,
    day07,
    day08,
    day09,
    day10,
    day11,
    day12,
    day13,
    day14,
    day15,
    day16,
    day17,
    day18,
    day19,
    day20,
    day21,
    day22,
    day23,
    day24,
    day25,
    all,
};

const days = std.ComptimeStringMap(Day, .{
    .{ "day01", .day01 },
    .{ "day02", .day02 },
    .{ "day03", .day03 },
    .{ "day04", .day04 },
    .{ "day05", .day05 },
    .{ "day06", .day06 },
    .{ "day07", .day07 },
    .{ "day08", .day08 },
    .{ "day09", .day09 },
    .{ "day10", .day10 },
    .{ "day11", .day11 },
    .{ "day12", .day12 },
    .{ "day13", .day13 },
    .{ "day14", .day14 },
    .{ "day15", .day15 },
    .{ "day16", .day16 },
    .{ "day17", .day17 },
    .{ "day18", .day18 },
    .{ "day19", .day19 },
    .{ "day20", .day20 },
    .{ "day21", .day21 },
    .{ "day22", .day22 },
    .{ "day23", .day23 },
    .{ "day24", .day24 },
    .{ "day25", .day25 },
    .{ "all", .all },
});

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Create Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    if (args.next()) |day| {
        if (days.get(day)) |day_enum| {
            switch (day_enum) {
                .day01 => try day01.run(allocator, stdout),
                .day02 => try day02.run(allocator, stdout),
                .day03 => try day03.run(allocator, stdout),
                .day04 => try day04.run(allocator, stdout),
                .day05 => try day05.run(allocator, stdout),
                .day06 => try day06.run(allocator, stdout),
                .day07 => try day07.run(allocator, stdout),
                .day08 => try day08.run(allocator, stdout),
                .day09 => try day09.run(allocator, stdout),
                .day10 => try day10.run(allocator, stdout),
                .day11 => try day11.run(allocator, stdout),
                //                .day12 => try day12.run(allocator, stdout),
                //                .day13 => try day13.run(allocator, stdout),
                //                .day14 => try day14.run(allocator, stdout),
                //                .day15 => try day15.run(allocator, stdout),
                //                .day16 => try day16.run(allocator, stdout),
                //                .day17 => try day17.run(allocator, stdout),
                //                .day18 => try day18.run(allocator, stdout),
                //                .day19 => try day19.run(allocator, stdout),
                //                .day20 => try day20.run(allocator, stdout),
                //                .day21 => try day21.run(allocator, stdout),
                //                .day22 => try day22.run(allocator, stdout),
                //                .day23 => try day23.run(allocator, stdout),
                //                .day24 => try day24.run(allocator, stdout),
                //                .day25 => try day25.run(allocator, stdout),
                .all => {
                    try day01.run(allocator, stdout);
                    try day02.run(allocator, stdout);
                    try day03.run(allocator, stdout);
                    try day04.run(allocator, stdout);
                    try day05.run(allocator, stdout);
                    try day06.run(allocator, stdout);
                    try day07.run(allocator, stdout);
                    try day08.run(allocator, stdout);
                    try day09.run(allocator, stdout);
                    try day10.run(allocator, stdout);
                    try day11.run(allocator, stdout);
                    //                    try day12.run(allocator, stdout);
                    //                    try day13.run(allocator, stdout);
                    //                    try day14.run(allocator, stdout);
                    //                    try day15.run(allocator, stdout);
                    //                    try day16.run(allocator, stdout);
                    //                    try day17.run(allocator, stdout);
                    //                    try day18.run(allocator, stdout);
                    //                    try day19.run(allocator, stdout);
                    //                    try day20.run(allocator, stdout);
                    //                    try day21.run(allocator, stdout);
                    //                    try day22.run(allocator, stdout);
                    //                    try day23.run(allocator, stdout);
                    //                    try day24.run(allocator, stdout);
                    //                    try day25.run(allocator, stdout);
                },
                else => {
                    try stdout.print("invalid day\n", .{});
                    try stdout.print("Give the day as an argument e.g. zig build run -- day01", .{});
                },
            }
        } else {
            try stdout.print("invalid day\n", .{});
            try stdout.print("Give the day as an argument e.g. zig build run -- day01", .{});
        }
    } else {
        try stdout.print("Give the day as an argument e.g. zig build run -- day01", .{});
    }

    try bw.flush(); // don't forget to flush!
}
