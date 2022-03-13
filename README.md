# createicns
Create an '.icns' file from any image.

![Header](https://user-images.githubusercontent.com/90936861/158078314-54549739-f738-47e3-af5a-7b2d516a66f4.svg)

## Usage
This command line tool makes it incredibly simple to create an '.icns' icon file from an image file.  
Normally, you would have to create 10 different versions of your icon, each with a different size and 
DPI, then run a tool like `iconutil` to create the icon from an '.iconset' file, which you have created 
beforehand using a tool like `sips`, and blah, blah blah...

`createicns` takes care of all the nitty-gritty details for you, allowing you to focus on what's important.

```
createicns <input-path> <output-path>
```

That's it! An '.icns' file will be saved to the output path. If you need to create an iconset file instead 
(to be imported into an IDE, for example), simply add the '-s', or the '--iconset' flag before 'input' 
argument.

```
createicns -s <input-path> <output-path>
```

If you want, you can skip the output altogether. In this case, the '.icns' file will be saved to the same 
directory as the original image file.

— Note that the output path must have the '.icns' file extension (if creating an icon), or the '.iconset'
extension (if creating an iconset).
