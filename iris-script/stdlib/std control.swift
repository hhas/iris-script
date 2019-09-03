//
//  std control.swift
//
// control flow

// TO DO: implement Icon-like evaluation, where there is only `test` + `action` parameters, and `didNothing` ('fail') is returned when test is false; that result can then be captured by an `else` operator, or coerced to `nothing` otherwise (advantage of this approach is more granular, composable code; e.g. `else` could also be applied to a `repeatWhile()` command to execute alternative branch if zero iterations are performed)

// note: while primitive functions can use Thunks for lazily evaluated arguments, it's cheaper just to pass the command's arguments as-is plus the command's environment and evaluate directly

// TO DO: where a handler function evals a value, the handler signature's returnType should propagate up to action.nativeEval(); alternatively, function might encapsulate action in a Value which is returned to the wrapper to force

func ifTest(condition: Bool, action: Value, commandEnv: Scope) throws -> Value {
    let result = try condition ? action.eval(in: commandEnv, as: asAnything) : nullAction
    print("`if` expr returned:", result, type(of: result))
    return result
}
func elseTest(left action: Value, right alternativeAction: Value, commandEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    print("`else` evaluating left action operand:", action)
    let result = try action.eval(in: commandEnv, as: MayDoNothing(asValue)) // TO DO: coercion needs to allow nullAction result to pass thru // TO DO: as with other flow control handlers, we really need to pass the final return type coercion up to the location where evaluation is performed
    print("action returned: \(result)")
    return result is NullAction ? try alternativeAction.eval(in: commandEnv, as: asAnything) : result
}

func repeatTimes(count: Int, action: Value, commandEnv: Scope) throws -> Value {
    var count = count
    var result: Value = nullAction
    while count > 0 {
        result = try action.eval(in: commandEnv, as: asAnything)
        count -= 1
    }
    return result
}


func whileRepeat(condition: Value, action: Value, commandEnv: Scope) throws -> Value {
    var result: Value = nullAction // TO DO: returning `nullAction` (implemented as subclass of NoValue?) will allow composition with infix `else` operator (ditto for `if`, etc); need to figure out precise semantics for this (as will NullCoercionErrors, the extent to which such a value can propagate must be strictly limited, with the value converting to noValue if not caught and handled immediately; one option is to define an `AsDidNothing(TYPE)` coercion which can unbox/coerce the nothing as a special case, e.g. returning a 2-case enum/returning nullAction rather than coercing it to noValue [which asAnything/asOptional/asDefault should do])
    while try asBool.unbox(value: condition, in: commandEnv) {
        result = try action.eval(in: commandEnv, as: asAnything)
    }
    return result
}

func repeatWhile(action: Value, condition: Value, commandEnv: Scope) throws -> Value {
    var result: Value = nullAction // TO DO: ditto
    repeat {
        result = try action.eval(in: commandEnv, as: asAnything)
    } while try asBool.unbox(value: condition, in: commandEnv)
    return result
}

