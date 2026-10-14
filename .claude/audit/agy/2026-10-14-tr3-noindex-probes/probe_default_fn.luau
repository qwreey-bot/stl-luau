--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }

local function defaultFull<F>(build: (ops: any) -> F): F return nil :: any end
local function defaultImpl<F>(build: (ops: any) -> F): F? return nil :: any end

-- How does stackDef receive defaultFn so that the return type reflects it?
-- Can we overload stackDef?
type StackDef = 
	((defaultFn: typeof(defaultFull)) -> (<Self, T>() -> {
		Push: (Self, T) -> Self,
		IsEmpty: (Self) -> boolean,
	})) &
	((defaultFn: typeof(defaultImpl)) -> (<Self, T>() -> {
		Push: (Self, T) -> Self,
		IsEmpty: ((Self) -> boolean)?,
	}))

