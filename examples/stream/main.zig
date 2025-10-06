const std = @import("std");
const asciigraph = @import("asciigraph");
const configs = asciigraph.options;
const colors = asciigraph.colors;
var array: []f64 = undefined;
var window: [][]f64 = undefined; // sliding window :)

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn fillStartPoints(allocator: std.mem.Allocator, size: usize) ![]f64 {
    var a: []f64 = undefined;
    a = try allocator.alloc(f64, size);
    for (0..a.len) |index| {
        a[index] = 0.00;
    }
    return a;
}

fn slidePoints(allocator: std.mem.Allocator, points: []const f64, latest: f64) ![][]f64 {
    var matrix: [][]f64 = undefined;
    matrix = try allocator.alloc([]f64, 1);

    for (matrix) |*row| {
        row.* = try allocator.alloc(f64, points.len);
        var index: usize = 1;
        while (index < points.len) : (index += 1) {
            row.*[index - 1] = points[index];
        }
        row.*[points.len - 1] = latest;
    }

    return matrix;
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    var buffer: [100]u8 = undefined;
    var stdin: std.fs.File = std.fs.File.stdin();
    var stdin_reader: std.fs.File.Reader = stdin.reader(&buffer);
    const sink: *std.Io.Reader = &stdin_reader.interface;

    var allocating_writer = std.Io.Writer.Allocating.init(arena);
    defer allocating_writer.deinit();

    const c = configs.config{
        .rows = 1,
        .columns = 50,
        .height = 10,
        .offset = 0,
        .legendColor = colors.White,
        .legends = "X Axis",
        .caption = "Y Axis",
    };

    const graph = try asciigraph.init(.{ .allocator = arena, .out = stdout, .config = c });

    array = try fillStartPoints(arena, c.columns);

    window = try arena.alloc([]f64, array.len);
    window = try slidePoints(arena, array, 0);

    while (sink.streamDelimiter(&allocating_writer.writer, '\n')) |_| {
        const lastLine = allocating_writer.written();
        allocating_writer.clearRetainingCapacity();
        stdin_reader.interface.toss(1);

        const point = std.fmt.parseFloat(f64, lastLine) catch |err| {
            std.debug.print("unable to argument '{s}': {s}\n", .{
                lastLine, @errorName(err),
            });
            std.process.exit(1);
        };

        window = try slidePoints(arena, window[0][0..], point);
        try graph.PlotGraph(window);
    } else |err| {
        switch (err) {
            error.EndOfStream => {
                std.debug.print("stream ended \n", .{});
            },
            else => {
                std.process.exit(0);
            },
        }
    }
}
