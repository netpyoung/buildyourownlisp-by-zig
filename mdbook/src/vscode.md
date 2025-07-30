# VS Code

- [VSCode 연동 및 작업 흐름](https://zig.news/pm/zig-multi-project-workflow-in-vs-code-with-dynamic-debugbuild-and-one-tasksjson-to-rule-them-all-ka7) 

### .vscode/

#### .vscode/extensions.json

- [ziglang.vscode-zig](https://marketplace.visualstudio.com/items?itemName=ziglang.vscode-zig)
  - <https://zigtools.org/zls/editors/vscode/>
- Window라면
  - [ms-vscode.cpptools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)
- Linux 혹은 macOs
  - [vadimcn.vscode-lldb](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb)
    - <https://github.com/vadimcn/codelldb/wiki/Windows>
- [ms-vscode-remote.vscode-remote-extensionpack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

``` json
{{#include ../../.vscode/extensions.json}}
```

#### .vscode/launch.json

``` json
{{#include ../../.vscode/launch.json}}
```

| launch.json - "console" | 입력 지원 | 출력 위치            | 새 창 여부 |
| ----------------------- | --------- | -------------------- | ---------- |
| `internalConsole`       | ❌         | 디버그 콘솔 (출력만) | X          |
| `integratedTerminal`    | ✅         | VSCode 내 터미널     | X          |
| `externalTerminal`      | ✅         | OS 외부 터미널 창    | O          |

#### .vscode/settings.json

``` json
{{#include ../../.vscode/settings.json}}
```

#### .vscode/tasks.json

``` json
{{#include ../../.vscode/tasks.json}}
```
