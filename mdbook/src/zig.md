## 지그

https://zenn.dev/topics/zig?order=latest

``` zig
u8            : one u8 value
?u8           : one optional u8 value
[2]u8         : array of 2 u8 values
[2:0]u8       : zero-terminated array of 2 u8 values
[2]*u8        : array of 2 u8 pointers
*u8           : pointer to one u8 value
*?u8          : pointer to one optional u8 value
?*u8          : optional pointer to u8 value
*const u8     : pointer to immutable u8 value
*const ?u8    : pointer to immutable optional u8 value
?*const u8    : optional pointer to immutable u8 value
*[2]u8        : pointer to array of 2 u8 values      
*[2:0]u8      : pointer to zero-terminated array of 2 u8 values      
*const [2]u8  : pointer to immutable array of 2 u8 values      
[]u8          : slice(pointer + runtime len) of u8 values
[]?u8         : slice(pointer + runtime len) of optional u8 values
?[]u8         : optional slice(pointer + runtime len) of u8 values
[]*u8         : slice(pointer + runtime len) of pointers to u8 values      
[]*const u8   : slice(pointer + runtime len) of pointers to immutable u8 values      
[*]u8         : pointer(unknown len) to of u8
[*:0]u8       : pointer(unknown len) to but zero-terminated of u8 values
*[]const u8   : pointer to slice of immutable u8 values      
*[]*const ?u8 : pointer to slice of pointers to immutable optional u8 values  

var x: i32 = 4;
var ptr: *i32 = &x;
ptr.* = 15;
```




const assert = std.debug.assert;

Normal Operator	Wrapping Operator
+	+%
-	-%
*	*%
+=	+%=
-=	-%=
*=	*%=

``` zig
[2]u8  -> *[2]u8    : by using address operator (&)
[2]u8  -> []u8      : by using slice operator [..]
*[2]u8 -> []u8      : automatic coercion from pointer to fixed size array to slice
[]u8   -> [*]u8     : by using .ptr
any    -> ?any      : automatic coercion from non-optional to optional
any    -> const any : automatic coercion from non-const to const
```


모던한 c와 c++의 중간쯤? 되는 언어같다.

"필요할 때만 명시적으로 작성하고, 나머지는 생략해도 이해되게 만들자."
Zig는 &T라는 타입이 없습니다. 대신, 함수 인자를 받을 때 포인터 타입 *T 또는 *const T로 명시합니다.
&는 오직 "주소 취득" 연산자 → x: *T와 &x는 확실하게 대응됨

## 흐음

- null 이 있다.
- bool 이 있다.
- 뭐 c/cpp와는 달리 header안 만들어도 됨.
- @intFromBool - bool을 int로 캐스팅
- @cImport
  - ffi는 다루기 쉽지만. 그래도 ffi인지라 메뉴얼 살펴보기됨. 특히 c string 다룰때.
  - https://github.com/ziglang/zig/issues/20630
- @import
  - razy이기에 import time이 있는 python과 달리 circluar import가 가능.
  - 다만 구조체 포인트가 아닌 구조체 자체를 맴버로 circular import를 하면 크기를 추정할 수 없기에 depends on itself가 나타남

### 오오

- go fmt처럼 zig fmt도 있네
- c헤더 생성 : export fn + -femit-h + zig build-lib
- exception 없는건 맘에듬


### 별로

- 상속이 없다 - 치명적인거 같은데..
- string interpolation 없다
- interface가 없다
  - https://zig.news/yglcode/code-study-interface-idiomspatterns-in-zig-standard-libraries-4lkj
- private가 없네
- 함수 오버로딩 없다
- 가변인자(Variadic Arguments) 도 없다.
  - c ffi를 위한 extern으로 된 c함수만 됨.
- const Hello = struct { A: u8, B: u8 } 컴마로 나누는거 꼴받네, `;` 세미콜론으로 왜 안해.
- 에러 스트링 안되네?
  - https://github.com/ziglang/zig/issues/2647
  - @panic은 있다. https://ziglang.org/documentation/master/#panic
  - https://dev.to/mustafif/a-little-panic-in-zig-5bo2
  - https://dev.to/chrischtel/error-handling-in-zig-a-fresh-approach-to-reliability-19o2
- 타입이 뒤에 있으니 검색할때 불편하네
  - x = struct
  - x: SomeStruct
- std format 류가 쓰는 포맷문자열이 컴파일 타임만 지원
  - https://github.com/ziglang/zig/issues/17832
- 좀 껄끄러운 syntax
  - ex) switch 구문에 컴마(,)나 화살표 (=>)
## x

opaque : 전방 선언용  // const SomeType = opaque {};
anytype : 함수가 컴파일 타임에 호출 시점에 타입을 결정하도록 하는 제네릭(generic) 역할을 해요.



## 에러

https://zig.guide/language-basics/errors/


## 문자열

https://ziglang.org/documentation/master/#Multiline-String-Literals
`\\`


```
    var buffer: [2048]u8 = undefined;
    const line: []u8 = try stdin.readUntilDelimiter(&buffer, '\n');

    const result = try allocator.alloc(u8, line.len + 1);
    @memcpy(result[0..line.len], line);
    result[line.len] = 0;
    return result[0..line.len :0] // “슬라이스 끝에 0(null terminator)이 이미 존재한다고 가정하고, 그 정보를 타입에 반영하겠다.”
```

```
    c
    "                                                    \
      number : /-?[0-9]+/ ;                              \
      symbol : \"list\" | \"head\" | \"tail\" | \"eval\" \
             | \"join\" | '+' | '-' | '*' | '/' ;        \
      sexpr  : '(' <expr>* ')' ;                         \
      qexpr  : '{' <expr>* '}' ;                         \
      expr   : <number> | <symbol> | <sexpr> | <qexpr> ; \
      lispy  : /^/ <expr>* /$/ ;                         \
    ",

    zig
    const lang =
        \\ number : /-?[0-9]+/ ;
        \\ symbol : "list" | "head" | "tail"
        \\        | "join" | "eval" | '+' | '-' | '*' | '/' ;
        \\ sexpr  : '(' <expr>* ')' ;
        \\ qexpr  : '{' <expr>* '}' ;
        \\ expr   : <number> | <symbol> | <sexpr> | <qexpr> ;
        \\ lispy  : /^/ <expr>* /$/ ;
    ;
```

https://zig.guide/standard-library/formatting


``` zig
const msg = try std.fmt.allocPrint(
    _ALLOCATOR,
    "{d} + {d} = {d}",
    .{ 9, 10, 19 },
);
defer _ALLOCATOR.free(msg);
```

``` zig
var buffer: [100]u8 = undefined;
const name = "Zig";
const msg = try std.fmt.bufPrint(&buffer, "Hello, {s}", .{name});
```


| 기능                 | C++                            | Zig 대응                |
| -------------------- | ------------------------------ | ----------------------- |
| `char * const`       | 포인터 고정, 내용 수정 가능    | ❌ 직접 불가 (우회 필요) |
| `const char *`       | 포인터 수정 가능, 내용은 const | `[]const u8`            |
| `const char * const` | 포인터도, 내용도 const         | `const x: []const u8`   |


``` zig
const std = @import("std");

pub fn main() !void {
    var buffer1: [100]u8 = undefined;
    var buffer2: [100]u8 = undefined;

    var msg: []u8 = undefined;
    msg = try std.fmt.bufPrint(&buffer1, "Hello, {s}", .{"bob"});
    msg = try std.fmt.bufPrint(&buffer2, "Hello, {s}", .{"bob"});
    buffer1 = buffer2; // << 여기 부분을 막고싶은데

    std.debug.print("{s}\n", .{msg});
}
```

## c문자열

[*c]u8

https://gencmurat.com/en/posts/zig-strings/

## 뭐지
error: expected type '[]const u8', found '[*c]u8'
    const parsed = std.fmt.parseInt(i64, t.contents, 10)

const slice = std.mem.span(t.contents);
const parsed = std.fmt.parseInt(i64, slice, 10) catch {
    return lval_err("invalid number", allocator);
};

👉 @intCast(usize, value) 를 사용해서 c_int를 usize로 변환하세요:
zig
Copy
Edit


## 출력

https://github.com/ziglang/zig/issues/17186

const stdout = std.io.getStdOut().writer(); 전역(컴파일타임)으로하면 Windows에서 찾지못함. 런타임에 설정해야함.

## 디버그
const std = @import("std");

if (std.builtin.mode == .Debug) {
    std.debug.print("Debug build message\n", .{});
}

std.debug.print는 Release 빌드에서도 출력이 됩니다


	std.debug.print // stderr
  const stdout = std.io.getStdOut().writer();
  stdout.print // stdout

std.log.info
pub const log_level: std.log.Level = .info;
pub const default_level: Level = switch (builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe => .info,
    .ReleaseFast, .ReleaseSmall => .err,
};

@hasDecl(root, "log_level")
이건 컴파일 타임 내장 함수입니다.

root는 @import("root")와 동일한 의미이며, 현재 애플리케이션의 루트 파일(보통 main.zig)을 가리킵니다
pub const level: Level = if (@hasDecl(root, "log_level"))
    root.log_level
else
    default_level;

https://stackoverflow.com/a/72609022



## 할당
allocator.create(T)의 반환 타입은 *T

|                                       | 함수                                             |
| ------------------------------------- | ------------------------------------------------ |
| 생성 /소멸 (초기화 O)                 | `allocator.create(T)` / `allocator.destroy(ptr)` |
| 원시 메모리 블록 할당/해제 (초기화 X) | `allocator.alloc(u8, n)` / `allocator.free(ptr)` |



const ret = allocator.create(Lenv) catch unreachable;
ret.* = .{.A = 1}; // 디폴트 생성자 호출

## 배열

v.Cell = std.ArrayList(*Lval).init(allocator);
v.Cell.deinit();

## 슬라이스
x[n..m]
Slicing includes the first element (n), but excludes the last element (m).

## 이상하네


타입이 붙었다 때였나

const stdin = std.io.getStdIn().reader();

@TypeOf(...)	
const Reader = @TypeOf(std.io.getStdIn().reader());
const stdin: Reader = std.io.getStdIn().reader();

제네릭 타입 인자로 함수 포인터(function pointer)를 넘기는 것도 가능해

## 출력

const print = @import("std").debug.print;
print("Hello, world!\n", .{}); // another comment

const stdout = std.io.getStdOut().writer();
try stdout.print("Lispy Version 0.0.0.0.1\n", .{});


## ffi
@import // 모듈 불러오기
@cImport / @cInclude // C 라이브러리 가져오기
        exe.addIncludePath(.{ .cwd_relative = "/usr/include/" });
        exe.linkSystemLibrary("edit");



exe.addIncludePath(.{ .cwd_relative = "src/origin_source" });
exe.addCSourceFile(.{ .file = b.path("src/origin_source/mpc.c") });
exe.linkLibC(); // To solve ( error: 'stdlib.h' file not found )



// https://en.cppreference.com/w/c/memory/free.html
// typedef void (*Callback)(void* user_data);
const Callback = *const fn (?*anyopaque) callconv(.C) void;

*const fn // 함수 포인터 (*const는 "상수 포인터)
fn (?*anyopaque) // void*
callconv(.C) // C calling convention을 따른다
void // 반환값


## vscode

| 설정                 | 입력 지원 | 출력 위치            | 새 창 여부 |
| -------------------- | --------- | -------------------- | ---------- |
| `internalConsole`    | ❌         | 디버그 콘솔 (출력만) | X          |
| `integratedTerminal` | ✅         | VSCode 내 터미널     | X          |
| `externalTerminal`   | ✅         | OS 외부 터미널 창    | O          |



## u8 문자열


[]const u8	문자열 슬라이스 (zig는 char가 없음 u8로 처리) ( pointer + length)
[:0]const u8 // https://ziglang.org/documentation/master/#Sentinel-Terminated-Slices

[*]u8 = 길이 미상의 u8 배열 포인터 (null 종료 여부는 명시 안 됨)
[*:0]u8 = 0(null)으로 종료되는 u8 배열 (equivalent to const char * in C) // https://ziglang.org/documentation/master/#Sentinel-Terminated-Pointers

const new_msg: []u8 = try allocator.dupe(u8, msg);
const new_msg: [:0]u8 = try allocator.dupeZ(u8, msg); // dupeZ (Duplicate null-terminated)

const hello: [:0]const u8 = "Hello";
const ptr: [*:0]const u8 = hello.ptr;



## division  @divTrunc, @divFloor, or @divExact

src\main.zig:172:18: error: division with 'i64' and 'i64': signed integers must use @divTrunc, @divFloor, or @divExact
        return x / y;
               ~~^~~
@divTrunc(-7, 3) == -2
@divTrunc(7, 3) == 2

@divFloor(-7, 3) == -3
@divFloor(7, 3) == 2

@divExact(6, 3) == 2   // OK
@divExact(7, 3)        // 런타임 오류 (7은 3으로 정확히 나눠지지 않음)


## format

format https://zig.guide/standard-library/formatting-specifiers/

const stdout = std.io.getStdOut().writer();
try stdout.print("{d}\n", .{x});

## stdin

var buffer: [2048]u8 = undefined;
const n: usize = try std.io.getStdIn().read(&buffer);
var end = n;
if (end > 0 and buffer[end - 1] == '\n') {
    end -= 1;
}
const result = try allocator.alloc(u8, end + 1);
std.mem.copyForwards(u8, result[0..end], buffer[0..end]);
result[end] = 0; // null terminator
return result[0..end :0];

const stdin = std.io.getStdIn();
var buffer: [2048]u8 = undefined;
const line: []u8 = try stdin.readUntilDelimiter(&buffer, '\n');
const result = try allocator.alloc(u8, line.len + 1);
std.mem.copyForwards(u8, result[0..line.len], line); //     @memcpy(result[0..line.len], line);
result[line.len] = 0;
return result[0..line.len :0];


https://www.openmymind.net/Zigs-memcpy-copyForwards-and-copyBackwards/

## 타입

- ?T
  - nullable
  - 포인터 타입이라도 반환시 ?안해주면 null을 쓸 수 없다(컴파일 에러)
- !T
  - 이 함수가 오류를 반환할 수 있음을 뜻함
- `*T`
  - 일반 포인터
- `?*T`
  - nullable 포인터
- [*c]T
  - c 포인터 C-style 포인터 배열	길이 없는 배열 (null 종결)
- .?
  - optional 값을 강제로 해제(unwrap) 하는 문법입니다.
  - 만약 null이라면 런타임 에러가 발생함.

if (x) |value| {
}

## ArrayList

https://ziglang.org/documentation/master/std/#std.array_list.ArrayList

## 에러 try !

Zig에서는 try를 쓰는 함수는 무조건 그 함수의 반환 타입에 !를 붙여야 해. 그래야 에러가 전파될 수 있거든.

근데 dotnet의 try패턴이 없고 저런 함수들이 있음. 에러 반환할 수 있을거 같은데 그냥 T임..

        /// Remove the element at index `i`, shift elements after index
        /// `i` forward, and return the removed element.
        /// Invalidates element pointers to end of list.
        /// This operation is O(N).
        /// This preserves item order. Use `swapRemove` if order preservation is not important.
        /// Asserts that the index is in bounds.
        /// Asserts that the list is not empty.
        pub fn orderedRemove(self: *Self, i: usize) T {
            const old_item = self.items[i];
            self.replaceRangeAssumeCapacity(i, 1, &.{});
            return old_item;
        }


## defer

- defer
  - Zig에서 defer a.dispose();는 해당 시점의 a 값에 대해 dispose를 예약합니다.
  - 즉, 그 이후에 a에 다른 값을 할당해도, **defer는 원래 있었던 값의 dispose()**를 호출합니다.
  - 컨벤션으로 const 사용후 defer하거나 var사용하면 defer 사용 못하게 막아야 할듯.
defer // errdefer
defer   : 어떻게 종료되든 항상 정리가 필요한 리소스에 사용합니다.
errdefer: 오류가 발생하는 경우에만 리소스를 정리해야 할 때 사용합니다.

errdefer는 와 유사 defer하지만, 오류로 인해 범위가 종료될 때만 실행됩니다.
https://gencmurat.com/en/posts/defer-and-errdefer-in-zig/

- 스코프를 조정할 수 있는 dotnet 의 using + IDisposable interface 방식이 더 맘에 든다.

``` zig
const std = @import("std");

const Thing = struct {
    id: i32,
    fn dispose(self: *Thing) void {
        std.debug.print("Disposing {}\n", .{self.id});
    }
};

pub fn main() void {
    var a = Thing{ .id = 1 };
    defer a.dispose(); // 여기서 a는 id = 1인 Thing

    a = Thing{ .id = 2 }; // 새로운 Thing을 a에 덮어씀

std.debug.print("{}", .{a});
}
```


https://zig.guide/standard-library/allocators/
https://www.openmymind.net/learning_zig/heap_memory/

http://ithare.com/testing-memory-allocators-ptmalloc2-tcmalloc-hoard-jemalloc-while-trying-to-simulate-real-world-loads/
[신비한 malloc 사전](https://hackmd.io/@sanxiyn/SkMgA04mo)


| Allocator 종류                            | 설명                                    | 특징 및 용도                                                      |
| ----------------------------------------- | --------------------------------------- | ----------------------------------------------------------------- |
| **std.heap.c\_allocator**                 | C `malloc`/`free` 기반 기본 할당자      | 시스템 기본 메모리 할당, 범용적                                   |
| **std.heap.page\_allocator**              | 메모리 페이지 단위 할당자               | 페이지 단위 메모리 관리, 큰 블록 할당에 적합                      |
| **std.heap.general\_purpose\_allocator**  | jemalloc 스타일 범용 할당자             | 중간 \~ 큰 크기 메모리 효율적 관리, 쓰레드 안전 아님              |
|                                           |                                         |                                                                   |
| **std.heap.FixedBufferAllocator**         | 고정 버퍼 내에서 할당, 할당 해제 불가   | 빠른 할당, 메모리 풀 용도                                         |
| **std.heap.ArenaAllocator**               | Arena(풀) 방식 할당자                   | 빠른 할당 및 해제, 전체 아레나 해제만 가능                        |
| **std.heap.DebugAllocator**               | 디버깅용 래퍼 할당자                    | 메모리 할당/해제 추적, 오버플로우 검사                            |
| **std.heap.BuddyAllocator**               | Buddy 메모리 할당자                     | 단편화 감소, 큰 메모리 관리에 적합                                |
| **std.heap.GeneralPurposeAllocator(.{})** | jemalloc 스타일 범용 할당자 (Zig 0.11+) | 성능과 단편화 균형 맞춤 범용 할당자                               |
| **std.testing.allocator**                 | 테스트용 임시 할당자                    | 테스트 중 메모리 할당 관리, 쉽게 리셋 가능, 메모리 누수 검출 도움 |

## 키워드

result.error는 안되고 result.@"error"


## 기타

VS Code in the browser
coder.com
https://github.com/coder/code-server

https://medium.com/codex/solving-the-crazy-zig-literal-strings-f2f692ae500b

## struct

@This()는 현재 선언 중인 구조체(struct), 유니언(union), 또는 enum 타입 자체를 참조할 때 사용하는 **내장 함수(builtin function

## 
// build.zig
    if (target.result.os.tag != .windows) {
        exe.linkLibC();
        exe.addIncludePath(.{ .cwd_relative = "/usr/include/" });
        exe.linkSystemLibrary("edit");
    }

// main.zig
const c_libedit = if (!is_windows) @cImport({
    // https://salsa.debian.org/debian/libedit/-/blob/master/src/editline/readline.h
    @cInclude("editline/readline.h");
}) else struct {};

const input: [*:0]u8 = c_libedit.readline("lispy> ");
_ = c_libedit.add_history(input);
defer std.c.free(input);



---

zig
ide - ZigBrains https://plugins.jetbrains.com/plugin/22456-zigbrains
설치 https://ziglang.org/learn/getting-started/

zig
build.zig - https://ziglang.org/learn/build-system/
build.zig.zon
 - https://zig.news/edyu/zig-package-manager-wtf-is-zon-558e
 - https://zig.news/edyu/zig-package-manager-wtf-is-zon-2-0110-update-1jo3

타겟설정 Target
최적화 / Optimization
실행가능 Executable
  root_source_file 
  root_module
모듈 Module


zig build-exe main.zig -femit-docs  // file emit
zig build
zig build run


const std = @import("std");
https://ziglang.org/documentation/master/std/

const builtin = @import("builtin");
https://ziglang.org/documentation/master/#Compile-Variables



릴리즈모드 4개 https://zig.guide/build-system/build-modes/
https://github.com/zigtools/zls
https://ludwigabap.bearblog.dev/2024-collection-of-zig-resources/

macro대신 그냥 compiletime이라는 키워드


[The Road to Zig 1.0 - Andrew Kelley](https://www.youtube.com/watch?v=Gv2I7qTux7g)

Search Ziglang Packages
https://zigistry.dev/


Mach - Zig game engine & graphics toolkit
https://machengine.org/
https://ziglang.org/learn/getting-started/
  https://zigtools.org/zls/editors/jetbrains/


https://mitchellh.com/zig
https://matklad.github.io/2023/02/10/how-a-zig-ide-could-work.html



https://www.openmymind.net/learning_zig/
  - https://faultnote.github.io/posts/learning-zig/
https://www.youtube.com/@dudethebuilder/videos




    // { // doc
    //     const install_docs = b.addInstallDirectory(.{
    //         .source_dir = exe.getEmittedDocs(),
    //         .install_dir = .prefix,
    //         .install_subdir = "docs",
    //     });

    //     const docs_step = b.step("docs", "Install docs into zig-out/docs");
    //     docs_step.dependOn(&install_docs.step);
    // }

## 비교

strstr
    if (std.mem.indexOf(u8, std.mem.span(t.tag), "number") != null) {


strcmp == 0
    if (std.mem.eql(u8, std.mem.span(t.tag), ">")) {
    std.mem.orderZ(u8, t.tag, t.tag) == .eq
