# Omarchy Voyager Disco

Change the color of your ZSA keyboard from Omarchy's bar!

<img width="810" height="1138" alt="Pasted image" src="https://github.com/user-attachments/assets/e4d0a1ff-b6ef-46e2-90bb-3a7b9d539a0a" />

https://github.com/user-attachments/assets/63f318f0-53b6-4b68-9dd1-204557c7f51f

## Requirements

- Omarchy 4 with `omarchy-shell` (bar widgets / Quickshell)
- [`voyager-disco`](https://github.com/monorkin/voyager-disco) on your `PATH` (`yay -S voyager-disco` on Arch)

## Installation

```sh
omarchy plugin add https://github.com/monorkin/omarchy-voyager-disco.git --enable
omarchy bar plugin add monorkin.voyager-disco
```

## Settings

| Key      | Type   | Default | Description                                            |
|----------|--------|---------|--------------------------------------------------------|
| `device` | string | `""`    | Comma-separated keyboard serials to target (empty = all) |

Set it from the bar's widget settings UI, or:

```sh
omarchy bar plugin set monorkin.voyager-disco device ABC123
```

## IPC

The widget registers a `monorkin.voyager-disco` IPC target:

```sh
omarchy-shell monorkin.voyager-disco toggle
omarchy-shell monorkin.voyager-disco setColor ff00aa
omarchy-shell monorkin.voyager-disco matchTheme
omarchy-shell monorkin.voyager-disco reset
```

## License

MIT - see [LICENSE](LICENSE) for details.
