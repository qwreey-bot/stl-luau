local typeutil = require "./typeutil"

local tuple_ifce = {}
local tuple_meta = { __index = tuple_ifce }
local tuple_constructor = {}

--#region tuple type builder
-- selene: allow(undefined_variable) — `types` 는 type function 블록 안에서만
-- 주입되는 특수 전역이라 selene 이 정의되지 않은 변수로 오탐합니다.
type function TupleBuilderInner(ty: type)
    local tb = types.newtable()
    local funcParams = ty:parameters()
    local funcParamsHead = funcParams.head
    if not funcParamsHead then return types.never end
    local tupData = {}

    local index = 1
    for _, tupset in funcParamsHead do
        local tupsetParams = tupset:parameters()
        local tupsetParamsHead = tupsetParams.head
        if not tupsetParamsHead then continue end

        for _, element in tupsetParamsHead do
            tb:setproperty(
                types.singleton("_" .. tostring(index)),
                element
            )
            table.insert(tupData, element)
            index += 1
        end
    end
    tb:setproperty(
        types.singleton("n", index - 1),
        types.number
    )

    local mt = types.newtable({
        [types.singleton("__tuple")] = types.newfunction({ head = tupData });
    })
    tb:setmetatable(mt)

    return tb
end
type TupleBuilder<T> = typeutil.Tagged<TupleBuilderInner<T>, "tuple-data">



-- type function TupleExtract(ty: type)
--     local mt = ty:metatable()
--     if not mt then return types.never end

--     return mt:readproperty(types.singleton("__tuple")) or types.never
-- end



-- selene: allow(undefined_variable) — `types` 는 type function 블록 안에서만
-- 주입되는 특수 전역이라 selene 이 정의되지 않은 변수로 오탐합니다.
type function TuplePush(ty: type, item: type)
    local func
    for i, tyv in ty:components() do
        func = tyv:readproperty(types.singleton("__tuple__"))
        if func and func.tag == "function" then break end
    end

    return func

    -- local tb = types.newtable()

    -- local func = ty:readproperty(types.singleton("__tuple__"))
    -- if not func then return types.never end

    -- local funcParams = ty:parameters()
    -- local funcParamsHead = funcParams.head
    -- local funcParamsLen = if funcParamsHead then #funcParamsHead else 0
    -- funcParamsHead[funcParamsLen + 1] = item

    -- ty:setproperty(
    --     types.singleton("_" .. tostring(funcParamsLen + 1)),
    --     item
    -- )
    -- ty:setproperty(
    --     types.singleton("n", funcParamsLen + 1),
    --     types.number
    -- )
    -- ty:setreadproperty(
    --     types.singleton("__tuple__"),
    --     types.newfunction({
    --         head = funcParamsHead
    --     })
    -- )

    -- return ty
end
--#endregion tuple type builder

--#region functions
function tuple_ifce.pack<Self, T...>(self: Self, ...: T...): Tuple<T...> & Self
    local inst = {}
    for idx = 1, select("#", ...) do
        inst["_" .. idx] = select(idx, ...)
    end
    setmetatable(inst, tuple_meta)
    return inst
end
local tuple_pack = tuple_ifce.pack
--#endregion functions

--#region constructor
function tuple_constructor.__call<T...>(_, ...: T...): Tuple<T...>
    return tuple_pack(...)
end
--#endregion constructor

--TODO: impl unpack here

-- function tuple_ifce.pushed<U, T...>(self: Tuple<T...>, item: U): TuplePush<Self, U> 
-- end
-- function tuple_ifce.pushed<U, Self>(self: Self, item: U): TuplePush<Self, U>
    
-- end

-- TODO: push, unshift, insert, erase
-- TODO: wrap_return

-- stylua: ignore start
export type TupleInterface = typeof(tuple_ifce)
export type Tuple<T...> = TupleBuilder<((T...)->())->()>

local t2 = tuple_ifce:pack(1, 2, 33)

local Tuple = (
    setmetatable(table.clone(tuple_ifce), tuple_constructor) :: unknown
) :: typeutil.SetMetaProp<{}, "__call", <T...>(T...)->(TupleBuilder<((T...)->())->()>)>


local t1 = Tuple(true, false)

-- return Tuple
return {}
-- stylua: ignore end
