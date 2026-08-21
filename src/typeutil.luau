local module = {}

type function MergeInner(ty: type)
    local funcParameters = ty:parameters()
    local tb = types.newtable()

    if funcParameters.head then
        for paramIdx, paramVal in funcParameters.head do
            for tblIdx, tblVal in paramVal:properties() do
                tb:setreadproperty(tblIdx, tblVal.read)
                tb:setwriteproperty(tblIdx, tblVal.write)
            end
        end
    end
    
    return tb
end
export type Merge<T...> = MergeInner<(T...)->()>

export type function SetMetaTable(base: type, metatable: type)
    base:setmetatable(metatable)
    return base
end

export type function SetMetaProp(base: type, key: type, value: type)
    local mt = base:metatable()
    if not mt then
        mt = types.newtable()
        base:setmetatable(mt)
    end
    mt:setproperty(key, value)
    base:setmetatable(mt)
    return base
end

export type function ExtractTagged(base: type, tag: type)
    local tagStr = tag:value()
    local components: {type} = (
        if base:is("union") or base:is("intersection") then
            base:components()
        else
            {base}
    )

    for i, v in components do
        if not v:is("table") then continue end

        local mt = v:metatable()
        if not mt then continue end

        local vtag = mt:readproperty(types.singleton("__tag"))
        if (not vtag) or (not vtag:is("singleton")) then continue end

        if tagStr == vtag:value() then
            return v
        end
    end

    return types.never
end

export type Tagged<T, Tag> = SetMetaProp<T, "__tag", Tag>

return module

-- type t = Tagged<{ a: string }, "test">
-- type t2 = t & { [number]: string } & any
-- type t3 = ExtractTagged<t2, "test">

-- Omit
-- Merge

