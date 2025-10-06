const std = @import("std");
const asciigraph = @import("asciigraph");
const configs = asciigraph.options;
const colors = asciigraph.colors;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn fillPoints(map: []const []f64, points: []f64) void {
    for (map) |row| {
        for (0..row.len) |index| {
            row[index] = points(index);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const c = configs.config{
        .rows = 1,
        .columns = 50,
        .height = 10,
        .offset = 0,
        .legendColor = colors.Yellow,
        .legends = "X Axis",
        .caption = "Y Axis",
    };

    const graph = try asciigraph.init(.{ .allocator = allocator, .out = stdout, .config = c });

    const matrix = try graph.prepareMatrix(c.rows, c.columns);
    asciigraph.fillRandom(matrix);

    try graph.PlotGraph(matrix);
}
