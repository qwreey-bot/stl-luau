--!strict
-- probe12: Test default method return type in the SAME module and across modules

export type function FullOf(defTable: type): type
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read :: type
		local fnProp = entry:readproperty(types.singleton("fn")) :: type
		props[name] = { read = fnProp }
	end
	return types.newtable(props)
end

type Req<F> = { read required: true, read fn: F }
type Def<F> = { read required: false, read fn: F }

type ProbeDef<Self, T> = {
	Get: Req<(Self) -> T>,
	Twice: Def<(Self) -> T>,
}

-- 구체 인스턴스화
type Arr<T> = { [number]: T }

-- 같은 모듈에서 ProbeOf 사용:
type ProbeFull<Self, T> = FullOf<ProbeDef<Self, T>>

local function useProbe(p: ProbeFull<Arr<number>, number>, a: Arr<number>)
	-- Twice 의 반환값은 number 여야 함.
	-- string 변수에 대입하면 반드시 NEG 에러가 나야 함!
	local NEG_sameRet: string = p.Twice(a)
	return NEG_sameRet
end

local canary: string = 1
