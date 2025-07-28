const std = @import("std");
const module_builtin = @import("builtin");

const c_libedit = if (module_builtin.os.tag != .windows) @cImport({
    // https://salsa.debian.org/debian/libedit/-/blob/master/src/editline/readline.h
    @cInclude("editline/readline.h");
}) else struct {};

const c_mpc = @cImport({
    @cInclude("mpc.h");
});

const assert = std.debug.assert;

fn readLine(prompt: [:0]const u8) [*c]u8 {
    if (module_builtin.os.tag != .windows) {
        const input: [*c]u8 = c_libedit.readline(prompt);
        return input;
    }

    std.debug.print("{s}", .{prompt});

    const stdin = std.io.getStdIn().reader();

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

fn zstr_Equal(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn zstr_Contains(a: []const u8, b: []const u8) bool {
    return std.mem.indexOf(u8, a, b) != null;
}

fn cstr_Equal(a: [*:0]const u8, b: [:0]const u8) bool {
    return std.mem.orderZ(u8, a, b) == .eq;
}

fn cstr_Contains(a: [*:0]const u8, b: [:0]const u8) bool {
    return std.mem.indexOf(u8, std.mem.span(a), b) != null;
}

fn LASSERT(v: *Lval, condition: bool, comptime fmt: []const u8, args_fmt: anytype) ?*Lval {
    if (condition) {
        return null;
    }

    const err = lval_err_format(fmt, args_fmt);
    v.Dispose();
    return err;
}

fn LASSERT_TYPE(func: []const u8, v: *Lval, index: usize, expect: E_LVAL) ?*Lval {
    return LASSERT(v, v.Cell.items[index].Type == expect, "Function '{s}' passed incorrect type for argument {d}. Got {s}, Expected {s}.", .{ func, index, v.Cell.items[index].Type.Name(), expect.Name() });
}

fn LASSERT_NUM(func: []const u8, v: *Lval, num: usize) ?*Lval {
    return LASSERT(v, v.Cell.items.len == num, "Function '{s}' passed incorrect number of arguments. Got {d}, Expected {d}.", .{ func, v.Cell.items.len, num });
}

fn LASSERT_NOT_EMPTY(func: []const u8, v: *Lval, index: usize) ?*Lval {
    return LASSERT(v, v.Cell.items[index].Cell.items.len != 0, "Function '{s}' passed {{}} for argument {d}.", .{ func, index });
}

// ===================================================

const E_LVAL = enum(i32) {
    ERR = 0,
    NUM,
    SYM,
    SEXPR,
    QEXPR,
    FUN,

    fn Name(t: E_LVAL) []const u8 {
        switch (t) {
            .FUN => return "Function",
            .NUM => return "Number",
            .ERR => return "Error",
            .SYM => return "Symbol",
            .SEXPR => return "S-Expression",
            .QEXPR => return "Q-Expression",
            // else => return "Unknown",
        }
    }
};

const Lval = struct {
    Type: E_LVAL = E_LVAL.ERR,
    Num: i64 = 0,
    Err: []const u8 = undefined,
    Sym: []const u8 = undefined,
    Cell: std.ArrayList(*Lval) = undefined,
    Fun: *const lbuiltin,

    pub fn Dispose(v: *Lval) void {
        const allocator = std.heap.page_allocator;

        switch (v.Type) {
            .NUM => {},
            .ERR => {
                allocator.free(v.Err);
            },
            .SYM => {
                allocator.free(v.Sym);
            },
            .SEXPR => {},
            .QEXPR => {},
            .FUN => {},
        }

        for (v.Cell.items) |item| {
            item.Dispose();
        }
        v.Cell.deinit();
        allocator.destroy(v);
    }

    pub fn Clone(v: *Lval) *Lval {
        const allocator = std.heap.page_allocator;

        const x: *Lval = allocator.create(Lval) catch unreachable;
        x.Type = v.Type;

        switch (v.Type) {
            .NUM => {
                x.Num = v.Num;
            },
            .ERR => {
                x.Err = allocator.dupe(u8, v.Err) catch unreachable;
            },
            .SYM => {
                x.Sym = allocator.dupe(u8, v.Sym) catch unreachable;
            },
            .SEXPR, .QEXPR => {},
            .FUN => {
                x.Fun = v.Fun;
            },
        }
        x.Cell = std.ArrayList(*Lval).init(allocator);
        for (v.Cell.items) |item| {
            const copied = item.Clone();
            x.Cell.append(copied) catch unreachable;
        }
        return x;
    }

    pub fn Print(val: *const Lval) void {
        switch (val.Type) {
            .NUM => {
                std.debug.print("{d}", .{val.Num});
            },
            .ERR => {
                std.debug.print("Error: {s}", .{val.Err});
            },
            .SYM => {
                std.debug.print("{s}", .{val.Sym});
            },
            .SEXPR => {
                val.lval_expr_print('(', ')');
            },
            .QEXPR => {
                val.lval_expr_print('{', '}');
            },
            .FUN => {
                std.debug.print("<function>", .{});
            },
        }
    }

    pub fn Println(val: *const Lval) void {
        val.Print();
        std.debug.print("\n", .{});
    }

    fn lval_expr_print(val: *const Lval, open: u8, close: u8) void {
        std.debug.print("{c}", .{open});
        for (val.Cell.items, 0..) |item, i| {
            item.Print();
            if (i != val.Cell.items.len - 1) {
                std.debug.print(" ", .{});
            }
        }
        std.debug.print("{c}", .{close});
    }

    fn Add(v: *Lval, x: *Lval) *Lval {
        assert(v.Type == .SEXPR or v.Type == .QEXPR);

        v.Cell.append(x) catch unreachable;
        return v;
    }

    fn Pop(v: *Lval, i: usize) *Lval {
        assert(v.Type == .SEXPR or v.Type == .QEXPR);

        const ret = v.Cell.orderedRemove(i);
        return ret;
    }

    fn Take(v: *Lval, i: usize) *Lval {
        assert(v.Type == .SEXPR or v.Type == .QEXPR);

        const x = Pop(v, i);
        v.Dispose();
        return x;
    }

    fn Join(x: *Lval, y: *Lval) *Lval {
        assert(x.Type == .SEXPR or x.Type == .QEXPR);

        var ret: *Lval = x;
        while (y.Cell.items.len > 0) {
            ret = ret.Join(y.Pop(0));
        }
        y.Dispose();
        return ret;
    }
};

fn lval_num(x: i64) *Lval {
    const allocator = std.heap.page_allocator;
    const v = allocator.create(Lval) catch unreachable;
    v.Type = .NUM;
    v.Cell = std.ArrayList(*Lval).init(allocator);
    v.Num = x;
    return v;
}

fn lval_err(msg: []const u8) *Lval {
    const allocator = std.heap.page_allocator;
    const v = allocator.create(Lval) catch unreachable;
    v.Type = .ERR;
    v.Cell = std.ArrayList(*Lval).init(allocator);
    v.Err = allocator.dupe(u8, msg) catch unreachable;
    return v;
}

fn lval_err_format(comptime fmt: []const u8, args_fmt: anytype) *Lval {
    const allocator = std.heap.page_allocator;
    const v = allocator.create(Lval) catch unreachable;
    v.Type = .ERR;
    v.Cell = std.ArrayList(*Lval).init(allocator);
    const formatted = std.fmt.allocPrint(allocator, fmt, args_fmt) catch unreachable;
    v.Err = formatted;
    return v;
}

fn lval_sym(msg: []const u8) *Lval {
    const allocator = std.heap.page_allocator;
    const v = allocator.create(Lval) catch undefined;
    v.Type = .SYM;
    v.Cell = std.ArrayList(*Lval).init(allocator);

    v.Sym = allocator.dupe(u8, msg) catch unreachable;
    return v;
}

fn lval_sexpr() *Lval {
    const allocator = std.heap.page_allocator;
    const v = allocator.create(Lval) catch unreachable;
    v.Type = .SEXPR;
    v.Cell = std.ArrayList(*Lval).init(allocator);
    return v;
}

fn lval_qexpr() *Lval {
    const allocator = std.heap.page_allocator;
    const v = allocator.create(Lval) catch unreachable;
    v.Type = .QEXPR;
    v.Cell = std.ArrayList(*Lval).init(allocator);
    return v;
}

fn lval_fun(func: *const lbuiltin) *Lval {
    const allocator = std.heap.page_allocator;
    const v = allocator.create(Lval) catch unreachable;
    v.Type = .FUN;
    v.Cell = std.ArrayList(*Lval).init(allocator);
    v.Fun = func;
    return v;
}

// ===================================================
const lbuiltin = fn (env: *Lenv, val: *Lval) *Lval;

const Lenv = struct {
    Syms: std.ArrayList([]const u8) = undefined,
    Vals: std.ArrayList(*Lval) = undefined,

    pub fn Init() *Lenv {
        const allocator = std.heap.page_allocator;
        const ret = allocator.create(Lenv) catch unreachable;
        ret.Syms = std.ArrayList([]const u8).init(allocator);
        ret.Vals = std.ArrayList(*Lval).init(allocator);
        return ret;
    }

    pub fn Dispose(e: *Lenv) void {
        const allocator = std.heap.page_allocator;

        for (e.Syms.items) |item| {
            allocator.free(item);
        }
        e.Syms.deinit();

        for (e.Vals.items) |item| {
            item.Dispose();
        }
        e.Vals.deinit();

        allocator.destroy(e);
    }

    fn Get(e: *Lenv, k: *Lval) *Lval {
        for (0.., e.Syms.items) |i, sym| {
            if (std.mem.eql(u8, sym, k.Sym)) {
                const val = e.Vals.items[i];
                const copied = val.Clone();
                return copied;
            }
        }

        return lval_err("unbound symbol!");
    }

    fn Put(e: *Lenv, k: *Lval, v: *Lval) void {
        const allocator = std.heap.page_allocator;

        const newVal = v.Clone();

        for (0.., e.Syms.items) |i, sym| {
            // override
            if (zstr_Equal(sym, k.Sym)) {
                const oldVal = e.Vals.items[i];
                oldVal.Dispose();
                e.Vals.items[i] = newVal;
                return;
            }
        }

        const newSym = allocator.dupe(u8, k.Sym) catch unreachable;
        e.Vals.append(newVal) catch unreachable;
        e.Syms.append(newSym) catch unreachable;
    }

    fn Eval(e: *Lenv, v: *Lval) *Lval {
        if (v.Type == .SYM) {
            const x = e.Get(v);
            v.Dispose();
            return x;
        }

        if (v.Type == .SEXPR) {
            return e.EvalSexpr(v);
        }
        return v;
    }

    fn EvalSexpr(e: *Lenv, v: *Lval) *Lval {
        for (0.., v.Cell.items) |i, item| {
            const evaled = e.Eval(item);
            v.Cell.items[i] = evaled;
        }

        for (0.., v.Cell.items) |i, item| {
            if (item.Type == .ERR) {
                return v.Take(i);
            }
        }

        if (v.Cell.items.len == 0) {
            return v;
        }

        if (v.Cell.items.len == 1) {
            return v.Take(0);
        }

        const first = v.Pop(0);
        defer first.Dispose();

        if (first.Type != .FUN) {
            v.Dispose();
            return lval_err_format("S-Expression starts with incorrect type. Got {s}, Expected {s}.", .{ first.Type.Name(), E_LVAL.FUN.Name() });
        }

        const result = first.Fun(e, v);
        return result;
    }

    fn lenv_add_builtin(e: *Lenv, name: []const u8, func: lbuiltin) void {
        const k = lval_sym(name);
        const v = lval_fun(func);
        e.Put(k, v);
        k.Dispose();
        v.Dispose();
    }
};

// ===================================================

fn lval_read_num(t: *c_mpc.mpc_ast_t) *Lval {
    const slice = std.mem.span(t.contents);

    const parsed = std.fmt.parseInt(i64, slice, 10) catch {
        return lval_err("invalid number");
    };

    return lval_num(parsed);
}

fn lval_read(t: *c_mpc.mpc_ast_t) *Lval {
    if (cstr_Contains(t.tag, "number")) {
        return lval_read_num(t);
    }
    if (cstr_Contains(t.tag, "symbol")) {
        return lval_sym(std.mem.span(t.contents));
    }

    var x: *Lval = undefined;
    if (cstr_Equal(t.tag, ">")) {
        x = lval_sexpr();
    } else if (cstr_Contains(t.tag, "sexpr")) {
        x = lval_sexpr();
    } else if (cstr_Contains(t.tag, "qexpr")) {
        x = lval_qexpr();
    }

    for (0..@intCast(t.children_num), t.children) |_, child| {
        if (cstr_Equal(child.*.contents, "(")) {
            continue;
        }
        if (cstr_Equal(child.*.contents, ")")) {
            continue;
        }
        if (cstr_Equal(child.*.contents, "{")) {
            continue;
        }
        if (cstr_Equal(child.*.contents, "}")) {
            continue;
        }
        if (cstr_Equal(child.*.tag, "regex")) {
            continue;
        }

        const child_val = lval_read(child);
        x = x.Add(child_val);
    }

    return x;
}

// ===================================================

fn builtin_list(_: *Lenv, a: *Lval) *Lval {
    a.Type = .QEXPR;
    return a;
}

fn builtin_head(_: *Lenv, a: *Lval) *Lval {
    if (LASSERT_NUM("head", a, 1)) |err| {
        return err;
    }
    if (LASSERT_TYPE("head", a, 0, .QEXPR)) |err| {
        return err;
    }
    if (LASSERT_NOT_EMPTY("head", a, 0)) |err| {
        return err;
    }

    const v = a.Take(0);
    while (v.Cell.items.len > 1) {
        v.Pop(1).Dispose();
    }
    return v;
}

fn builtin_tail(_: *Lenv, a: *Lval) *Lval {
    if (LASSERT_NUM("tail", a, 1)) |err| {
        return err;
    }
    if (LASSERT_TYPE("tail", a, 0, .QEXPR)) |err| {
        return err;
    }
    if (LASSERT_NOT_EMPTY("tail", a, 0)) |err| {
        return err;
    }

    const v = a.Take(0);
    v.Pop(0).Dispose();
    return v;
}

fn builtin_join(_: *Lenv, a: *Lval) *Lval {
    for (0..a.Cell.items.len) |i| {
        if (LASSERT_TYPE("join", a, i, .QEXPR)) |err| {
            return err;
        }
    }

    var x = a.Pop(0);
    while (a.Cell.items.len > 0) {
        x = x.Join(a.Pop(0));
    }
    a.Dispose();
    return x;
}

fn builtin_eval(e: *Lenv, a: *Lval) *Lval {
    if (LASSERT_NUM("eval", a, 1)) |err| {
        return err;
    }

    if (LASSERT_TYPE("eval", a, 0, .QEXPR)) |err| {
        return err;
    }

    const x = a.Take(0);
    x.Type = .SEXPR;
    return e.Eval(x);
}

fn builtin_op(_: *Lenv, a: *Lval, op: []const u8) *Lval {
    for (0..a.Cell.items.len) |i| {
        if (LASSERT_TYPE(op, a, i, .NUM)) |err| {
            return err;
        }
    }

    const x = a.Pop(0);
    if (zstr_Equal(op, "-") and a.Cell.items.len == 0) {
        x.Num = -x.Num;
    }

    while (a.Cell.items.len > 0) {
        const y = a.Pop(0);
        defer y.Dispose();

        if (zstr_Equal(op, "+")) {
            x.Num += y.Num;
        } else if (zstr_Equal(op, "-")) {
            x.Num -= y.Num;
        } else if (zstr_Equal(op, "*")) {
            x.Num *= y.Num;
        } else if (zstr_Equal(op, "/")) {
            if (y.Num == 0) {
                return lval_err("Division By Zero.");
            } else {
                x.Num = @divTrunc(x.Num, y.Num);
            }
        }
    }
    a.Dispose();
    return x;
}

fn builtin_def(e: *Lenv, a: *Lval) *Lval {
    if (LASSERT_TYPE("def", a, 0, .QEXPR)) |err| {
        return err;
    }

    const syms = a.Cell.items[0];

    for (syms.Cell.items) |item| {
        if (LASSERT(a, item.Type == .SYM, "Function 'def' cannot define non-symbol. Got {s}, Expected {s}.", .{ item.Type.Name(), E_LVAL.SYM.Name() })) |err| {
            return err;
        }
    }

    if (LASSERT(a, syms.Cell.items.len == a.Cell.items.len - 1, "Function 'def' passed too many arguments for symbols. Got {d}, Expected {d}.", .{ syms.Cell.items.len, a.Cell.items.len - 1 })) |err| {
        return err;
    }

    for (0.., syms.Cell.items) |i, item| {
        e.Put(item, a.Cell.items[i + 1]);
    }

    a.Dispose();
    return lval_sexpr();
}

fn builtin_add(env: *Lenv, a: *Lval) *Lval {
    return builtin_op(env, a, "+");
}

fn builtin_sub(env: *Lenv, a: *Lval) *Lval {
    return builtin_op(env, a, "-");
}

fn builtin_mul(env: *Lenv, a: *Lval) *Lval {
    return builtin_op(env, a, "*");
}

fn builtin_div(env: *Lenv, a: *Lval) *Lval {
    return builtin_op(env, a, "/");
}

fn lenv_add_builtins(e: *Lenv) void {
    e.lenv_add_builtin("def", builtin_def);

    e.lenv_add_builtin("list", builtin_list);
    e.lenv_add_builtin("head", builtin_head);
    e.lenv_add_builtin("tail", builtin_tail);
    e.lenv_add_builtin("eval", builtin_eval);
    e.lenv_add_builtin("join", builtin_join);

    e.lenv_add_builtin("+", builtin_add);
    e.lenv_add_builtin("-", builtin_sub);
    e.lenv_add_builtin("*", builtin_mul);
    e.lenv_add_builtin("/", builtin_div);
}

// ===================================================

pub fn main() void {
    const Number = c_mpc.mpc_new("number");
    const Symbol = c_mpc.mpc_new("symbol");
    const Sexpr = c_mpc.mpc_new("sexpr");
    const Qexpr = c_mpc.mpc_new("qexpr");
    const Expr = c_mpc.mpc_new("expr");
    const Lispy = c_mpc.mpc_new("lispy");
    defer c_mpc.mpc_cleanup(6, Number, Symbol, Sexpr, Qexpr, Expr, Lispy);

    const lang =
        \\ number : /-?[0-9]+/ ;
        \\ symbol : /[a-zA-Z0-9_+\-*\/\\=<>!&]+/ ;
        \\ sexpr  : '(' <expr>* ')' ;
        \\ qexpr  : '{' <expr>* '}' ;
        \\ expr   : <number> | <symbol> | <sexpr> | <qexpr> ;
        \\ lispy  : /^/ <expr>* /$/ ;
    ;

    if (c_mpc.mpca_lang(c_mpc.MPCA_LANG_DEFAULT, lang, Number, Symbol, Sexpr, Qexpr, Expr, Lispy) != 0) {
        std.debug.print("Failed to define grammar\n", .{});
        return;
    }

    std.debug.print("Lispy Version 0.0.0.0.2\n", .{});
    std.debug.print("Press Ctrl+c to Exit\n\n", .{});

    const env = Lenv.Init();
    lenv_add_builtins(env);

    while (true) {
        const input: [*c]u8 = readLine("lispy> ");
        defer std.c.free(input);

        var result: c_mpc.mpc_result_t = undefined;
        if (c_mpc.mpc_parse("<stdin>", input, Lispy, &result) != 0) {
            const output: *c_mpc.mpc_ast_t = @ptrCast(@alignCast(result.output));
            defer c_mpc.mpc_ast_delete(output);

            c_mpc.mpc_ast_print(output);

            const r: *Lval = lval_read(output);
            const e: *Lval = env.Eval(r);
            e.Println();
            e.Dispose();
        } else {
            c_mpc.mpc_err_print(result.@"error");
            c_mpc.mpc_err_delete(result.@"error");
        }
    }
}
