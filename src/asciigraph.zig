const std = @import("std");
pub const options = @import("options.zig");
pub const colors = @import("ansiColor.zig");
pub const util = @import("utils.zig");

const math = @import("std").math;
pub const ColorStruct = colors.AnsiColor;

const EscapeSequence = struct {
    const reset = "\x1B[2J\x1B[H\x1B[?25l";
};

const cell = struct {
    text: []const u8,
    color: ColorStruct,
    pub fn init(t: []u8, c: ColorStruct) cell {
        return cell{
            .text = t,
            .color = c,
        };
    }
};

pub fn prepareCellMatrix(x: u8, y: u8, allocator: std.mem.Allocator) ![][]cell {
    var cells: [][]cell = undefined;
    cells = try allocator.alloc([]cell, x);
    for (cells) |*row| {
        row.* = try allocator.alloc(cell, y);
        for (row.*, 0..) |_, i| {
            row.*[i] = .{ .text = " ", .color = colors.Default };
        }
    }

    return cells;
}

pub fn prepareMatrix(x: u8, y: u8, allocator: std.mem.Allocator) ![][]f64 {
    var matrix: [][]f64 = undefined;
    matrix = try allocator.alloc([]f64, x);
    for (matrix) |*row| {
        row.* = try allocator.alloc(f64, y);
        for (row.*, 0..) |_, i| {
            row.*[i] = 0;
        }
    }

    return matrix;
}

pub fn fillRandom(map: []const []f64) void {
    var random = std.crypto.random;
    for (map) |row| {
        for (0..row.len) |index| {
            row[index] = @floatFromInt(random.int(u8));
        }
    }
}

pub fn fillPoints(map: []const []f64) void {
    for (map) |row| {
        for (0..row.len) |index| {
            row[index] = prepareSineWave(index);
        }
    }
}

pub fn prepareSineWave(index: usize) f64 {
    const _index: f64 = @floatFromInt(index);
    return (15 * (std.math.sin(_index * ((std.math.pi * 4) / 120.0))));
}

pub fn PlotGraph(allocator: std.mem.Allocator, out: *std.Io.Writer, data: [][]f64, configs: options.config) !void {
    var logMaximum: f64 = undefined;
    var default = configs;

    // Deep copy?
    var lenMax: usize = 0;
    var dataCopy: [][]f64 = try prepareMatrix(configs.rows, configs.columns, allocator);
    for (data, 0..) |_, i| {
        const row = data[i];
        if (row.len > lenMax) {
            lenMax = row.len;
        }
        for (row, 0..) |innerValue, j| {
            dataCopy[i][j] = innerValue;
        }
    }

    var minimum: f64 = std.math.inf(f64);
    var maximum: f64 = std.math.inf(f64);

    for (dataCopy) |row| {
        const minValue = util.minValue(row);
        const maxValue = util.maxValue(row);
        if (minValue < minimum) {
            minimum = minValue;
        }

        if (maxValue < maximum) {
            maximum = maxValue;
        }
    }

    const interval: f64 = @abs(maximum - minimum);

    if (default.height <= 0) {
        default.height = util.calculateHeight(interval);
    }

    if (default.offset <= 0) {
        default.offset = 3;
    }

    var ratio: f64 = 1;
    if (interval != 0) {
        ratio = default.height / interval;
    }

    const min2: f64 = util.round(minimum * ratio);
    const max2: f64 = util.round(maximum * ratio);

    const intmin2: i8 = @as(i8, @intFromFloat(min2));
    const intmax2: i8 = @as(i8, @intFromFloat(max2));

    const rowSize: usize = @abs(intmax2 - intmin2);
    const width: usize = lenMax + default.offset;

    const _row: u8 = @abs(intmax2 - intmin2) + 1;
    const _width: u8 = @intCast((lenMax + default.offset));

    var plot: [][]cell = try prepareCellMatrix(_row, _width, allocator);
    var precision: usize = default.precision;

    //Add Max(float64, float64)
    logMaximum = std.math.log10(@max(maximum, minimum));
    if (minimum == 0 and maximum == 0) {
        logMaximum = @as(f64, -1);
    }

    if (logMaximum < 0) {
        const value = try std.math.mod(i8, @intFromFloat(logMaximum), 1);
        if (value != 0) {
            precision += @as(u8, @intFromFloat(logMaximum));
        } else {
            precision += @as(u8, @intFromFloat(logMaximum)) - 1;
        }
    } else if (logMaximum > 2) {
        precision = 2;
    }

    // defaults
    var charBuf: []u8 = undefined;
    charBuf = try allocator.alloc(u8, 50);
    const charMax = try std.fmt.bufPrint(charBuf, "{d:.[1]}", .{ maximum, precision });
    const charMin = try std.fmt.bufPrint(charBuf, "{d:.[1]}", .{ minimum, precision });

    const maxCharLength = @as(usize, @intCast(charMax.len));
    const minCharLength = @as(usize, @intCast(charMin.len));

    // maxWidth
    var maxWidth: usize = 0;
    const sign: usize = 1;
    if (maxCharLength > maxWidth) {
        maxWidth = maxCharLength + sign;
    } else {
        maxWidth = minCharLength + sign;
    }

    // axis and labels
    var y = min2;
    while (y < max2 + 1) : (y += 1) {
        var magnitude: f64 = undefined;
        if (rowSize > 0) {
            magnitude = maximum - ((y - min2) * interval / @as(f64, @floatFromInt(rowSize)));
        } else {
            magnitude = @as(f64, y);
        }

        var buf: []u8 = undefined;
        buf = try allocator.alloc(u8, maxWidth + precision + 1 + 1);

        var label: []u8 = undefined;
        label = try std.fmt.bufPrint(buf, "{d:.[1]}", .{ magnitude, precision });
        if (magnitude < 0) {
            label = try std.fmt.bufPrint(buf, "{d:.[1]}", .{ magnitude, precision });
        }

        if (label.len < maxWidth) {
            var diff = maxWidth - label.len;
            if (magnitude < 0) {
                diff = maxWidth - label.len;
            }

            var emptySpace: []u8 = undefined;
            emptySpace = try allocator.alloc(u8, diff);
            @memset(emptySpace, ' ');

            buf = try allocator.alloc(u8, maxWidth);
            label = try std.fmt.bufPrint(buf, "{0s}{1d:.[2]}", .{ emptySpace, magnitude, precision });
        }

        const w = @as(usize, @intFromFloat(y - min2));
        const h = @as(usize, @min((label.len - default.offset), 0));
        plot[w][h].color = default.labelColor;
        plot[w][h].text = label;

        plot[w][default.offset - 1].text = "┤";
        plot[w][default.offset - 1].color = default.axisColor;
    }

    for (dataCopy) |series| {
        const _nan: f64 = std.math.nan(f64);
        // const color = default.legendColor;

        var y0: usize = 0;
        var y1: usize = 0;

        if (series[0] != _nan) {
            const _y = util.round(series[0] * ratio) - min2;
            y0 = @as(usize, std.math.lossyCast(usize, _y));
            const xDash = rowSize - y0;
            const yDash = default.offset - 1;
            plot[xDash][yDash].text = "┼";
            plot[xDash][yDash].color = default.axisColor;
        }

        const sLen = series.len - 1;
        var x: u8 = 0;
        while (x < sLen) : (x += 1) {
            const d0 = series[x];
            const d1 = series[x + 1];

            if (_nan == d0 and _nan == d1) {
                continue;
            }

            if (_nan == d1 and _nan != d0) {
                const _y = (util.round(d0 * ratio) - min2);
                y0 = @as(usize, @intFromFloat(_y));
                const xDash = rowSize - y0;
                const yDash = default.offset + x;
                plot[xDash][yDash].text = "╴";
                plot[xDash][yDash].color = configs.legendColor;
                continue;
            }

            if (_nan == d0 and _nan != d1) {
                const _y = (util.round(d1 * ratio) - min2);
                y1 = @as(usize, @intFromFloat(_y));
                const xDash = rowSize - y1;
                const yDash = default.offset + x;
                plot[xDash][yDash].text = "╶";
                plot[xDash][yDash].color = configs.legendColor;
                continue;
            }

            const _y0 = (util.round(d0 * ratio) - min2);
            y0 = @as(usize, @intFromFloat(_y0));

            const _y1 = (util.round(d1 * ratio) - min2);
            y1 = @as(usize, @intFromFloat(_y1));

            // std.debug.print("{d} {d} {d} {d} {d} {d} {d} {d} {d}\n", .{ x, x + 1, d0, d1, min2, ratio, y0, y1, rowSize });

            if (y0 == y1) {
                plot[rowSize - y0][x + default.offset].text = "─";
            } else {
                if (y0 > y1) {
                    plot[rowSize - y1][x + default.offset].text = "╰";
                    plot[rowSize - y0][x + default.offset].text = "╮";
                } else {
                    plot[rowSize - y1][x + default.offset].text = "╭";
                    plot[rowSize - y0][x + default.offset].text = "╯";
                }

                const start = @as(u64, @min(y0, y1)) + 1;
                const end = @as(u64, @max(y0, y1));
                var k = start;
                while (k < end) : (k += 1) {
                    plot[rowSize - k][x + default.offset].text = "│";
                }
            }

            const start = @as(u64, @min(y0, y1));
            const end = @as(u64, @max(y0, y1));
            var k = start;
            while (k < end) : (k += 1) {
                plot[rowSize - k][x + default.offset].color = configs.legendColor;
            }
        }
    }

    try out.writeAll(EscapeSequence.reset);

    var graphIndex: i8 = 0;
    for (plot) |cells| {
        var lastCharIndex: usize = 0;
        var k2 = width - 1;
        const empty: []const u8 = " ";
        while (k2 >= 0) : (k2 -= 1) {
            if (std.mem.eql(u8, cells[k2].text, empty) == false) {
                lastCharIndex = k2;
                break;
            }
        }

        var c = colors.Default;
        for (cells) |value| {
            if (std.meta.eql(c, value.color) == false) {
                c = value.color;
            }

            try out.print("\x1b[38;5;{d}m{s}", .{ value.color.color, value.text });
        }

        if (std.meta.eql(c, colors.Default) == true) {
            try out.print("\n", .{});
        }

        graphIndex += 1;
    }
    try out.print("\n", .{});

    // Add caption
    if (std.mem.eql(u8, default.caption, "") == false) {
        try out.print("\x1b[38;5;{d}m{s}", .{ default.captionColor.color, default.caption });
    }

    // Add legends
    if (default.legends.len > 0) {
        const midway: usize = (default.columns / 2) - default.legends.len / 2;
        try out.splatByteAll(' ', midway);
        try out.print("\x1b[38;5;{d}m{s}", .{ default.legendColor.color, default.legends });
    }

    try out.flush();
    // try stdout.flush();
}
