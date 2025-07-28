const std = @import("std");
const module_builtin = @import("builtin");

const c_libedit = if (module_builtin.os.tag != .windows) @cImport({
    // https://salsa.debian.org/debian/libedit/-/blob/master/src/editline/readline.h
    @cInclude("editline/readline.h");
}) else struct {};

const c_mpc = @cImport({
    @cInclude("mpc.h");
});

fn readLine(prompt: [:0]const u8) [*c]u8 {
    if (module_builtin.os.tag != .windows) {
        const input: [*c]u8 = c_libedit.readline(prompt);
        return input;
    }

    std.debug.print("{s}", .{prompt});

    var stdin = std.io.getStdIn().reader();

    var buffer: [1024]u8 = undefined;
    const line = (stdin.readUntilDelimiterOrEof(&buffer, '\n') catch unreachable).?;

    const len = line.len;
    const total_len = len + 1; // +1 for null terminator

    const mem = std.c.malloc(total_len).?;
    const out: [*c]u8 = @ptrCast(mem);

    @memcpy(out[0..len], line);
    out[len] = 0; // null terminator

    return out;
}

fn addHistory(input: [*c]u8) void {
    if (module_builtin.os.tag != .windows) {
        _ = c_libedit.add_history(input);
    }
}

// ===================================================

// 오류 타입 열거형
const E_LERR = enum {
    DIV_ZERO,
    BAD_OP,
    BAD_NUM,
};

// lval 타입 열거형
const E_LVAL = enum {
    NUM,
    ERR,
};

// 값 타입 정의
const Lval = struct {
    Type: E_LVAL,
    Num: i64,
    Err: E_LERR,
};

// 숫자 생성기
fn lval_num(x: i64) Lval {
    return Lval{ .Type = E_LVAL.NUM, .Num = x, .Err = undefined };
}

// 에러 생성기
fn lval_err(e: E_LERR) Lval {
    return Lval{ .Type = E_LVAL.ERR, .Num = undefined, .Err = e };
}

// 값 출력
fn lval_print(val: Lval) void {
    switch (val.Type) {
        .NUM => {
            std.debug.print("{d}", .{val.Num});
        },
        .ERR => {
            switch (val.Err) {
                .DIV_ZERO => {
                    std.debug.print("Error: Division By Zero!", .{});
                },
                .BAD_OP => {
                    std.debug.print("Error: Invalid Operator!", .{});
                },
                .BAD_NUM => {
                    std.debug.print("Error: Invalid Number!", .{});
                },
            }
        },
    }
}

// 개행 포함 출력
fn lval_println(val: Lval) void {
    lval_print(val);
    std.debug.print("\n", .{});
}

// 연산자 평가
fn eval_op(x: Lval, op: [*:0]const u8, y: Lval) Lval {
    if (x.Type == E_LVAL.ERR) {
        return x;
    }
    if (y.Type == E_LVAL.ERR) {
        return y;
    }

    const xs = x.Num;
    const ys = y.Num;

    if (std.mem.eql(u8, std.mem.span(op), "+")) {
        return lval_num(xs + ys);
    }
    if (std.mem.eql(u8, std.mem.span(op), "-")) {
        return lval_num(xs - ys);
    }
    if (std.mem.eql(u8, std.mem.span(op), "*")) {
        return lval_num(xs * ys);
    }
    if (std.mem.eql(u8, std.mem.span(op), "/")) {
        if (ys == 0) {
            return lval_err(.DIV_ZERO);
        }
        return lval_num(@divTrunc(xs, ys));
    }
    return lval_err(.BAD_OP);
}

// AST 평가
pub fn eval(t: *c_mpc.mpc_ast_t) Lval {
    if (std.mem.indexOf(u8, std.mem.span(t.tag), "number") != null) {
        const buf = std.mem.span(t.contents);
        const result = std.fmt.parseInt(i64, buf, 10) catch {
            return lval_err(.BAD_NUM);
        };
        return lval_num(result);
    }

    const op = t.children[1].*.contents;
    var x = eval(t.children[2]);

    var i: usize = 3;
    while (i < t.children_num and
        std.mem.indexOf(u8, std.mem.span(t.children[i].*.tag), "expr") != null)
    {
        const right = eval(t.children[i]);
        x = eval_op(x, op, right);
        i += 1;
    }

    return x;
}

pub fn main() void {
    const Number = c_mpc.mpc_new("number");
    const Operator = c_mpc.mpc_new("operator");
    const Expr = c_mpc.mpc_new("expr");
    const Lispy = c_mpc.mpc_new("lispy");
    defer c_mpc.mpc_cleanup(4, Number, Operator, Expr, Lispy);

    const lang =
        \\ number   : /-?[0-9]+/ ;
        \\ operator : '+' | '-' | '*' | '/' ;
        \\ expr     : <number> | '(' <operator> <expr>+ ')' ;
        \\ lispy    : /^/ <operator> <expr>+ /$/ ;
    ;

    if (c_mpc.mpca_lang(c_mpc.MPCA_LANG_DEFAULT, lang, Number, Operator, Expr, Lispy) != 0) {
        std.debug.print("Failed to define grammar\n", .{});
        return;
    }

    std.debug.print("Lispy Version 0.0.0.0.2\n", .{});
    std.debug.print("Press Ctrl+c to Exit\n\n", .{});

    while (true) {
        const input = readLine("lispy> ");
        defer std.c.free(input);

        // Prepare result struct
        var result: c_mpc.mpc_result_t = undefined;

        if (c_mpc.mpc_parse("<stdin>", input, Lispy, &result) != 0) {
            const output: *c_mpc.mpc_ast_t = @ptrCast(@alignCast(result.output));
            defer c_mpc.mpc_ast_delete(output);

            const x = eval(output);
            lval_println(x);
        } else {
            c_mpc.mpc_err_print(result.@"error");
            c_mpc.mpc_err_delete(result.@"error");
        }
    }
}
