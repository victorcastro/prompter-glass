# PrompterGlass

A native macOS teleprompter with a transparent floating window that stays on top of any app — meant for reading your script right next to the webcam during recordings and video calls.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)

## Project status

**WIP — early development.** The project is just getting started: no release, no installer, no signed binary. The only way to use it today is to build it from source in Xcode. Structure and internal APIs will change without notice.

## Requirements

- macOS 26.5 or later (current deployment target)
- Xcode with the macOS 26 SDK
- Swift 5

## Build and run

```bash
git clone https://github.com/VictorCastroDev/PrompterGlass.git
cd PrompterGlass
open PrompterGlass.xcodeproj
```

In Xcode: select the `PrompterGlass` scheme and hit Run (`⌘R`).

## Contributing

Open to collaboration. Issues and pull requests are welcome — bug reports, feature ideas, or code. If you plan to tackle something big, open an issue first to discuss the approach.

## License

MIT. See [LICENSE](LICENSE).
