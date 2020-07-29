//
//  std control.swift
//
// control flow

// TO DO: implement Icon-like evaluation, where there is only `test` + `action` parameters, and `didNothing` ('fail') is returned when test is false; that result can then be captured by an `else` operator, or coerced to `nothing` otherwise (advantage of this approach is more granular, composable code; e.g. `else` could also be applied to a `repeatWhile()` command to execute alternative branch if zero iterations are performed)

// note: while primitive functions can use Thunks for lazily evaluated arguments, it's cheaper just to pass the command's arguments as-is plus the command's environment and evaluate directly

// TO DO: where a handler function evals a value, the handler signature's returnType should propagate up to action.nativeEval(); alternatively, function might encapsulate action in a Value which is returned to the wrapper to force


// TO DO: these need return type coercion

func ifTest(condition: Bool, action: Value, alternativeAction: Value, commandEnv: Scope) throws -> Value {
    let result = try asAnything.coerce(condition ? action : alternativeAction, in: commandEnv)
    //print("`if` expr returned:", result, type(of: result))
    return result
}

func repeatTimes(count: Int, action: Value, commandEnv: Scope) throws -> Value {
    var count = count
    var result: Value = nullValue
    while count > 0 {
        result = try asAnything.coerce(action, in: commandEnv)
        count -= 1
    }
    return result
}


func whileRepeat(condition: Value, action: Value, commandEnv: Scope) throws -> Value {
    var result: Value = nullValue
    while try asBool.coerce(condition, in: commandEnv) {
        result = try asAnything.coerce(action, in: commandEnv)
    }
    return result
}

func repeatWhile(action: Value, condition: Value, commandEnv: Scope) throws -> Value {
    var result: Value = nullValue
    repeat {
        result = try asAnything.coerce(action, in: commandEnv)
    } while try asBool.coerce(condition, in: commandEnv)
    return result
}

