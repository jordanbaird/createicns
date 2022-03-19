# createicns
Create an '.icns' file from any image.

![Header](https://user-images.githubusercontent.com/90936861/158078314-54549739-f738-47e3-af5a-7b2d516a66f4.svg)

## Usage
This command line tool makes it incredibly simple to create an '.icns' icon file from an image file.
Normally, you would have to create up to 10 different versions of your icon, each with a different 
size and DPI, then run a tool like `iconutil` to create an icon from an '.iconset' file, which you 
will need to have pre-made beforehand using a tool like `sips`.

Blah, blah, blah.

createicns takes care of all those details for you so that you can focus on what's important. To use 
createicns, simply pass an input file and an output destination.

```sh
createicns <input-path> <output-path>
```

> Note that the output path must have the '.icns' file extension (if creating an icon), or the 
'.iconset' extension (if creating an iconset).

That's it! It's that simple. An '.icns' file will be saved to the output path. If you need to create 
an iconset file instead (to be imported into an IDE, for example), simply add either the '-s' flag, 
or the '--iconset' flag before the 'input' argument.

```sh
createicns -s <input-path> <output-path>
```

> Tip: You can skip the output altogether. In this case, the new file will be saved in the same 
directory as the original image file.
