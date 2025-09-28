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

    const m = try asciigraph.prepareMatrix(c.rows, c.columns, allocator);
    asciigraph.fillPoints(m);

    try asciigraph.PlotGraph(allocator, stdout, m, c);
}
