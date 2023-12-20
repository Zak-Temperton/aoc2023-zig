const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(alloc: Allocator, stdout: anytype) !void {
    const file = try std.fs.cwd().openFile("src/data/day18.txt", .{ .mode = .read_only });
    const buffer = try file.reader().readAllAlloc(alloc, std.math.maxInt(u32));
    defer alloc.free(buffer);

    var timer = try std.time.Timer.start();
    const p1 = try part1(alloc, buffer);
    const p1_time = timer.lap();
    const p2 = try part2(alloc, buffer);
    const p2_time = timer.read();
    try stdout.print("Day18:\n  part1: {d} {d}ns\n  part2: {d} {d}ns\n", .{ p1, p1_time, p2, p2_time });
}

fn nextLine(input: []const u8, i: *usize) void {
    while (i.* < input.len and input[i.*] != '\n') i.* += 1;
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

fn readHex(comptime T: type, input: []const u8, i: *usize) T {
    var res: T = 0;
    const len = i.* + 5;
    while (i.* < len) : (i.* += 1) {
        switch (input[i.*]) {
            '0'...'9' => |c| res = res * 16 + c - '0',
            'a'...'f' => |c| res = res * 16 + c + 10 - 'a',
            else => return res,
        }
    }
    return res;
}

const Shape = struct {
    const Row = struct {
        const RowTreap = std.Treap([2]isize, Row.order);
        const RowNode = RowTreap.Node;

        y: isize,
        treap: RowTreap,

        fn order(a: [2]isize, b: [2]isize) std.math.Order {
            return std.math.order(a[0], b[0]);
        }

        fn put(self: *Row, alloc: Allocator, x: isize, dist: isize) !void {
            var entry = self.treap.getEntryFor(.{ x, dist });
            if (entry.node) |n| {
                entry.set(null);
                alloc.destroy(n);
            } else {
                var node = try alloc.create(RowNode);
                entry.set(node);
            }
        }

        fn deinit(self: *Row, alloc: Allocator) void {
            if (self.treap.root) |root| deinitTreap(alloc, root);
        }
    };

    const ShapeTreap = std.Treap(isize, std.math.order);
    const ShapeNode = ShapeTreap.Node;

    rows: ShapeTreap,
    map: std.AutoHashMapUnmanaged(isize, Row),
    allocator: Allocator,

    fn init(alloc: Allocator) Shape {
        return .{
            .rows = .{},
            .map = .{},
            .allocator = alloc,
        };
    }

    fn put(self: *Shape, y: isize, x: isize, dist: isize) !void {
        var entry = self.rows.getEntryFor(y);
        if (entry.node) |node| {
            try self.map.getPtr(node.key).?.put(self.allocator, x, dist);
        } else {
            var node = try self.allocator.create(ShapeNode);
            entry.set(node);
            try self.map.put(self.allocator, y, blk: {
                var row = Row{ .y = y, .treap = .{} };
                try row.put(self.allocator, x, dist);
                break :blk row;
            });
        }
    }

    fn minHeight(list: *std.ArrayList([2]isize), limit: isize) !isize {
        var min: isize = std.math.maxInt(isize);
        for (list.items) |n| {
            if (n[1] < min) min = n[1];
        }
        if (min >= limit) {
            min = limit;
        }
        for (list.items) |*n| {
            n[1] -= min;
        }
        return min;
    }

    fn asc(context: void, l: [2]isize, r: [2]isize) bool {
        _ = context;
        return l[0] < r[0];
    }

    fn removeZeros(list: *std.ArrayList([2]isize)) void {
        var i: usize = 0;
        while (i < list.items.len) {
            if (list.items[i][1] == 0) {
                _ = list.orderedRemove(i);
            } else {
                i += 1;
            }
        }
    }

    fn insert(list: *std.ArrayList([2]isize), s: usize, new: [2]isize) !usize {
        if (s < list.items.len) {
            for (list.items[s..], s..) |item, i| {
                if (item[0] > new[0]) {
                    try list.insert(i, new);
                    return i + 1;
                }
            }
        }
        try list.append(new);
        return list.items.len;
    }

    fn area(self: *Shape) !isize {
        var sum: isize = 0;
        var iter = self.rows.inorderIterator();

        var curr = std.ArrayList([2]isize).init(self.allocator);
        defer curr.deinit();

        var y: isize = 0;
        if (iter.next()) |first| {
            y = first.key;
            var row = self.map.getPtr(first.key).?;
            var row_iter = row.treap.inorderIterator();
            while (row_iter.next()) |next| try curr.append(next.key);
        }
        while (iter.next()) |next| {
            var diff = next.key - y;
            y = next.key;
            var min = try minHeight(&curr, diff);
            while (diff > 0 and curr.items.len > 0) {
                std.debug.assert(curr.items.len & 1 == 0);
                var block: isize = 0;
                var i: usize = 0;
                while (i < curr.items.len - 1) : (i += 2) {
                    block += curr.items[i + 1][0] - curr.items[i][0] + 1;
                }
                sum += block * (min);

                diff -= min;

                removeZeros(&curr);
                min = try minHeight(&curr, diff);
            }

            var row = self.map.getPtr(next.key).?;
            var row_iter = row.treap.inorderIterator();
            var i: usize = 0;
            while (row_iter.next()) |col| {
                i = try insert(&curr, i, col.key);
            }
        }

        var i: usize = 0;
        while (i < curr.items.len - 1) : (i += 2) {
            std.debug.assert(curr.items[i + 1][1] == curr.items[i][1]);
            sum += (curr.items[i + 1][0] - curr.items[i][0] + 1) * curr.items[i][1];
        }

        return sum;
    }

    fn deinit(self: *Shape) void {
        if (self.rows.root) |root| deinitTreap(self.allocator, root);
        var map_iter = self.map.valueIterator();
        while (map_iter.next()) |next| next.deinit(self.allocator);
        self.map.deinit(self.allocator);
    }
};

fn deinitTreap(alloc: Allocator, root: anytype) void {
    for (root.children) |child| {
        if (child) |c| deinitTreap(alloc, c);
    }
    alloc.destroy(root);
}

fn part1Shape(shape: *Shape, y: *isize, x: *isize, last_dir: *u8, last_dist: *isize, dir: u8, dist: isize) !void {
    switch (dir) {
        'L' => {
            if (last_dir.* == 'U') {
                if (last_dist.* > 1)
                    try shape.put(y.* + 1, x.*, last_dist.* - 1);
            } else {
                if (last_dist.* > 0)
                    try shape.put(y.* + 1 - last_dist.*, x.*, last_dist.*);
            }
            x.* -= dist;
        },
        'R' => {
            if (last_dir.* == 'U') {
                if (last_dist.* > 0)
                    try shape.put(y.*, x.*, last_dist.*);
            } else {
                if (last_dist.* > 1)
                    try shape.put(y.* + 1 - last_dist.*, x.*, last_dist.* - 1);
            }
            x.* += dist;
        },
        'U' => {
            y.* -= dist;
            if (last_dir.* == 'R') {
                last_dist.* = dist;
            } else {
                last_dist.* = dist + 1;
            }
        },
        'D' => {
            if (last_dir.* == 'R') {
                last_dist.* = dist + 1;
            } else {
                last_dist.* = dist;
            }
            y.* += dist;
        },
        else => unreachable,
    }
    last_dir.* = dir;
}

fn part1(alloc: Allocator, input: []const u8) !isize {
    var i: usize = 0;
    var x: isize = 0;
    var y: isize = 0;

    var shape = Shape.init(alloc);
    defer shape.deinit();

    const first_dir = input[i];
    i += 2;
    const first_dist = readInt(isize, input, &i);
    nextLine(input, &i);

    var last_dir: u8 = first_dir;
    var last_dist: isize = first_dist;

    switch (first_dir) {
        'L' => {
            x -= first_dist;
        },
        'R' => {
            x += first_dist;
        },
        else => unreachable,
    }
    while (i < input.len) {
        const dir = input[i];
        i += 2;
        const dist = readInt(isize, input, &i);
        nextLine(input, &i);
        try part1Shape(
            &shape,
            &y,
            &x,
            &last_dir,
            &last_dist,
            dir,
            dist,
        );
    }
    try part1Shape(
        &shape,
        &y,
        &x,
        &last_dir,
        &last_dist,
        first_dir,
        first_dist,
    );
    return try shape.area();
}

fn part2Shape(shape: *Shape, y: *isize, x: *isize, last_dir: *u8, last_dist: *isize, dir: u8, dist: isize) !void {
    switch (dir) {
        2 => {
            if (last_dir.* == 3) {
                if (last_dist.* > 1)
                    try shape.put(y.* + 1, x.*, last_dist.* - 1);
            } else {
                if (last_dist.* > 0)
                    try shape.put(y.* + 1 - last_dist.*, x.*, last_dist.*);
            }
            x.* -= dist;
        },
        0 => {
            if (last_dir.* == 3) {
                if (last_dist.* > 0)
                    try shape.put(y.*, x.*, last_dist.*);
            } else {
                if (last_dist.* > 1)
                    try shape.put(y.* + 1 - last_dist.*, x.*, last_dist.* - 1);
            }
            x.* += dist;
        },
        3 => {
            y.* -= dist;
            if (last_dir.* == 0) {
                last_dist.* = dist;
            } else {
                last_dist.* = dist + 1;
            }
        },
        1 => {
            if (last_dir.* == 0) {
                last_dist.* = dist + 1;
            } else {
                last_dist.* = dist;
            }
            y.* += dist;
        },
        else => unreachable,
    }
    last_dir.* = dir;
}

fn part2(alloc: Allocator, input: []const u8) !isize {
    var i: usize = 0;
    var x: isize = 0;
    var y: isize = 0;

    var shape = Shape.init(alloc);

    defer shape.deinit();
    i += 3;
    while (input[i] != ' ') i += 1;
    i += 3;
    const first_dist = readHex(isize, input, &i);
    var first_dir = input[i] - '0';
    nextLine(input, &i);

    var last_dir: u8 = first_dir;
    var last_dist: isize = first_dist;

    switch (first_dir) {
        2 => {
            x -= first_dist;
        },
        0 => {
            x += first_dist;
        },
        else => unreachable,
    }
    while (i < input.len) {
        i += 3;
        while (input[i] != ' ') i += 1;
        i += 3;
        const dist = readHex(isize, input, &i);
        var dir = input[i] - '0';
        nextLine(input, &i);
        try part2Shape(
            &shape,
            &y,
            &x,
            &last_dir,
            &last_dist,
            dir,
            dist,
        );
    }
    {
        try part2Shape(
            &shape,
            &y,
            &x,
            &last_dir,
            &last_dist,
            first_dir,
            first_dist,
        );
    }
    return try shape.area();
}

test "part1" {
    try std.testing.expect(62 == try part1(std.testing.allocator,
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ));
}

test "part2" {
    try std.testing.expect(952408144115 == try part2(std.testing.allocator,
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ));
}
