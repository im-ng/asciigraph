# asciigraph

Zig module to flush console ascii line graphs ╭┈╯

Crude derivation of the [asciigraph](https://github.com/kroitor/asciichart) implementations in zig

## Installation

Add asciigraph to your build.zig.zon:

```
zig fetch --save https://github.com/im-ng/asciigraph/archive/refs/heads/main.zip
```

## Usage

```zig
const std = @import("std");
const asciigraph = @import("asciigraph");
const configs = asciigraph.options;
const colors = asciigraph.colors;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const c = configs.config{
        .rows = 1,
        .columns = 50,
        .height = 5,
        .offset = 0,
        .legendColor = colors.White,
        .legends = "X Axis",
        .caption = "Y Axis",
    };

    const matrix = try asciigraph.prepareMatrix(c.rows, c.columns, allocator);
    asciigraph.fillRandom(matrix);

    try asciigraph.PlotGraph(allocator, matrix, c);
}
```

#### Output 

```bash
asciigraph/examples on  main [?] via ↯ v0.15.1 
❯ zig build basic
  ┤         ╭╮  ╭╮        ╭─╮      ╭╮                
  ┤ ╭╮     ╭╯│  │╰╮  ╭╮   │ │   ╭╮ ││ ╭╮  ╭─╮   ╭╮ ╭ 
  ┼╮││    ╭╯ │ ╭╯ ╰──╯╰╮  │ │   ││ ││ ││  │ ╰╮╭─╯╰╮│ 
  ┤│││╭─╮╭╯  ╰╮│       │  │ │ ╭╮│╰╮││ ││ ╭╯  ││   ││ 
  ┤╰╯╰╯ ╰╯    ││       │╭─╯ │ │╰╯ ╰╯╰╮│╰╮│   ╰╯   ││ 
  ┤           ╰╯       ╰╯   ╰─╯      ╰╯ ╰╯        ╰╯ 

Y Axis                      X Axis
```

## Examples

This repository contains a number of ready-to-run examples demonstrates the use of the `asciigraph`.


- [x] Basic
- [x] Sine Wave 
- [ ] Rainbow

```
git clone https://github.com/im-ng/asciigraph.git
cd asciigraph/examples
zig build
```

Run one of the sample use command `zig build {sample_name}` from examples folder.

```
zig build basic
zig build sine
```

## Todos

Whatever options shown in [asciigraph](https://github.com/kroitor/asciichart)

## 🤝 Attribution

The idea of this zig module taken from this [asciichart](https://github.com/guptarohit/asciigraph) including the Plot logic.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.