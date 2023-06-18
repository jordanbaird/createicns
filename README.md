# CreateICNS

Create 'icns' and 'iconset' files from standard images.

![Header](https://github.com/jordanbaird/createicns/assets/90936861/baa03f04-285a-4781-baf8-32cfe36cf382)

## Install
### Homebrew

```sh
brew tap jordanbaird/createicns
brew install createicns
```

## Usage
**CreateICNS** is a command line tool that makes it incredibly easy to create 'icns' and 'iconset' files from almost any image format. Normally, you would need to make up to 10 different versions of your icon, each with a different size and DPI, then run a tool like `sips` to create an 'iconset' file to pass into a tool like `iconutil` to create the final 'icns' file.

CreateICNS takes care of all those details for you so that you can focus on what's important. Just pass an input file and optional output destination:

```sh
createicns <input-path> [<output-path>]
```

To create an 'iconset' file (to be imported into an IDE, for example), use the `--type` option:

```sh
createicns --type iconset <input-path> [<output-path>]
```

> Tip: If you choose not to provide an output path, the new file will be saved to the same directory as the input.

To see the full list of command line options, use the `--help` option:

```sh
createicns --help
```

## License
CreateICNS is available under the [MIT license](LICENSE).
