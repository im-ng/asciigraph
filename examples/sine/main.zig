const std = @import("std");
const asciigraph = @import("asciigraph");
const configs = asciigraph.options;
const colors = asciigraph.colors;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const c = configs.config{
        .rows = 1,
        .columns = 100,
        .height = 10,
        .offset = 0,
        .legendColor = colors.White,
        .legends = "X Axis",
        .caption = "Y Axis",
    };

    const graph = try asciigraph.init(.{ .allocator = allocator, .out = stdout, .config = c });

    const m = try graph.prepareMatrix(c.rows, c.columns);
    asciigraph.fillPoints(m);

    try graph.PlotGraph(m);
}
