--!strict
-- 생성자가 여러 개인 제네릭 컨테이너를 어떻게 조직하는가?
-- quad 의 Tag 는 setmetatable({Merged=...},{__call=...}) 콜러블 네임스페이스지만
-- Tag 는 **비제네릭**이다. Arr 은 제네릭이라 같은 수법이 되는지 확인한다.
type Data<T> = { n: number, [number]: T }

--#region 안 1: 평평한 형제 이름 (stl.Arr, stl.ArrSized)
local function Arr1<T>(...: T): Data<T>
	return nil :: any
end
local function ArrSized1<T>(len: number, fill: T): Data<T>
	return nil :: any
end
type Stl1 = { Arr: typeof(Arr1), ArrSized: typeof(ArrSized1) }
local s1 = (nil :: any) :: Stl1
local a1 = s1.Arr(1, 2, 3)
local a1s = s1.ArrSized(3, 0)
local neg1a: string = a1[1] -- 에러여야 함
local neg1b: string = a1s[1] -- 에러여야 함
local neg1c = s1.Arrr -- 오타, 에러여야 함
--#endregion

--#region 안 2: 콜러블 네임스페이스 (stl.Arr(...) + stl.Arr.Sized(...))
local function ArrSized2<T>(len: number, fill: T): Data<T>
	return nil :: any
end
type ArrNs = setmetatable<{ Sized: typeof(ArrSized2) }, { __call: <T>(self: any, ...T) -> Data<T> }>
local s2 = (nil :: any) :: { Arr: ArrNs }
local a2 = s2.Arr(1, 2, 3) -- __call 경유
local a2s = s2.Arr.Sized(3, 0) -- 정적 필드 경유
local neg2a: string = a2[1] -- 에러여야 함 (__call 이 T 를 지키면)
local neg2b: string = a2s[1] -- 에러여야 함 (정적 필드가 T 를 지키면)
local neg2c = s2.Arr.Sizedd -- 오타, 에러여야 함
--#endregion

--#region 안 3: 순수 네임스페이스 테이블 (stl.Arr.Of(...), stl.Arr.Sized(...))
local function ArrOf3<T>(...: T): Data<T>
	return nil :: any
end
local function ArrSized3<T>(len: number, fill: T): Data<T>
	return nil :: any
end
type Stl3 = { Arr: { Of: typeof(ArrOf3), Sized: typeof(ArrSized3) } }
local s3 = (nil :: any) :: Stl3
local a3 = s3.Arr.Of(1, 2, 3)
local a3s = s3.Arr.Sized(3, 0)
local neg3a: string = a3[1] -- 에러여야 함
local neg3b: string = a3s[1] -- 에러여야 함
local neg3c = s3.Arr.Off -- 오타, 에러여야 함
--#endregion

local canary: string = 42
return { a1, a1s, neg1a, neg1b, neg1c, a2, a2s, neg2a, neg2b, neg2c, a3, a3s, neg3a, neg3b, neg3c, canary }
