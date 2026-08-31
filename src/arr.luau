local common = require("./common")
local compareTo = common.compareTo

local arr_ifce = {}
local arr_constructor = {}
arr_ifce.__index = arr_ifce

--#region ----------- 생성자 -----------
-- ... 을 받아 해당 내용을 가지는 배열을 생성합니다
function arr_constructor.__call<T>(_, ...: T): Arr<T>
	local result = table.pack(...)
	result.__arr__ = true
	setmetatable(result, arr_ifce)
	return result :: Arr<T>
end
setmetatable(arr_ifce, arr_constructor)
-- length 크기의 배열을 생성합니다
function arr_ifce.sized<T>(length: number, fill: T?): Arr<T>
	local result = table.create(length)
	result.n = length
	result.__arr__ = true
	if fill ~= nil then
		for idx = 1, length do
			result[idx] = fill
		end
	end
	setmetatable(result, arr_ifce)
	return result
end
local arr_sized = arr_ifce.sized
-- number index 를 사용하는 테이블을 배열로 변환합니다
function arr_ifce.from_table<T>(tbl: { [number]: T }): Arr<T>
	(tbl :: Arr<T>).n = table.maxn(tbl);
	(tbl :: any).__arr__ = true
	setmetatable(tbl, arr_ifce)
	return tbl :: any
end
-- 테이블의 내용을 복사한 배열을 생성합니다
function arr_ifce.clone_from_table<T>(tbl: { [number]: T }): Arr<T>
	local length = table.maxn(tbl)
	local result = table.create(length)
	result.n = length
	result.__arr__ = true
	for idx = 1, length do
		result[idx] = tbl[idx]
	end
	setmetatable(result, arr_ifce)
	return result
end
-- 이터레이터로부터 배열을 생성합니다
function arr_ifce.from_iter<T>(iter: any, ...): Arr<T>
	local last_exprs: Arr<any>
	local result = arr_sized(0)
	while true do
		if last_exprs then
			last_exprs = arr_ifce(iter(last_exprs:unpack()))
		else
			last_exprs = arr_ifce(iter(...))
		end
		if last_exprs[1] == nil then
			break
		end
		arr_ifce.push(result, last_exprs)
	end
	return result :: Arr<T>
end
-- length 만큼 함수의 실행 결과로 채워진 배열을 생성합니다. 함수에는 인자로 index 가 주어집니다
function arr_ifce.from_func<T>(length: number, func: (index: number)->T): Arr<T>
	local result = table.create(length)
	result.n = length
	result.__arr__ = true
	for idx = 1, length do
		result[idx] = func(idx)
	end
	setmetatable(result, arr_ifce)
	return result
end
-- function arr.map_from_iter<T>(iter: any, ...): arr<T> end
-- function arr.flatmap_from_iter<T>(iter: any, ...): arr<T> end
--#endregion ----------- 생성자 -----------

--#region ----------- 요소 추가 -----------
function arr_ifce.push_many<T>(self: Arr<T>, ...: T): Arr<T>
	local src = table.pack(...)
	local src_len = src.n
	if src_len == 0 then
		return self
	elseif src_len == 1 then
		local arr_len = self.n + 1
		self[arr_len] = ...
		self.n = arr_len
		return self
	end
	local arr_len = self.n
	self.n = arr_len + src_len
	table.move(src, 1, src_len, arr_len + 1, self)
	return self
end
local arr_push_many = arr_ifce.push_many
function arr_ifce.push_array<T>(self: Arr<T>, source: Arr<T>): Arr<T>
	local src_len = source.n
	local arr_len = self.n
	table.move(source, 1, src_len, arr_len + 1, self)
	self.n = arr_len + src_len
	return self
end
function arr_ifce.push<T>(self: Arr<T>, item: T): Arr<T>
	local arr_len = self.n + 1
	self[arr_len] = item
	self.n = arr_len
	return self
end

function arr_ifce.insert_many<T>(self: Arr<T>, at: number, ...: T): Arr<T>
	arr_ifce.insert_array(self, at, table.pack(...) :: any)
	return self
end
function arr_ifce.insert_array<T>(self: Arr<T>, at: number, source: Arr<T>): Arr<T>
	local src_len = source.n
	if src_len == 0 then
		return self
	end
	local arr_len = self.n
	table.move(self, at, arr_len, at + src_len)
	table.move(source, 1, src_len, at, self)
	self.n = arr_len + src_len
	return self
end
function arr_ifce.insert<T>(self: Arr<T>, at: number, item: T): Arr<T>
	local arr_len = self.n
	table.move(self, at, arr_len, at + 1)
	self[at] = item
	self.n = arr_len + 1
	return self
end

function arr_ifce.unshift_many<T>(self: Arr<T>, ...: T): Arr<T>
	arr_ifce.unshift_array(self, table.pack(...) :: any)
	return self
end
function arr_ifce.unshift_array<T>(self: Arr<T>, source: Arr<T>): Arr<T>
	local src_len = source.n
	local arr_len = self.n
	table.move(self, 1, arr_len, src_len + 1)
	table.move(source, 1, src_len, 1, self)
	self.n = arr_len + src_len
	return self
end
function arr_ifce.unshift<T>(self: Arr<T>, item: T): Arr<T>
	local arr_len = self.n
	table.move(self, 1, arr_len, 2)
	self[1] = item
	self.n = arr_len + 1
	return self
end
--#endregion ----------- 요소 추가 -----------

function arr_ifce.range(arr_len: number, start: number?, last: number?): (number, number)
	return if start == nil then 1 elseif start < 0 then (arr_len + start + 1) else start,
		if last == nil then arr_len elseif last < 0 then (arr_len + last + 1) else last
end
local arr_range = arr_ifce.range

function arr_ifce.is_arr(value: any): boolean
	return type(value) == "table" and rawget(value, "__arr__")
end
local arr_is_arr = arr_ifce.is_arr

function arr_ifce.clear<T>(self: Arr<T>): Arr<T>
	table.clear(self);
	-- table.clear 는 __arr__ 태그까지 지웁니다. 다시 심지 않으면 비운 배열이
	-- is_arr 판별을 통과하지 못합니다
	(self :: any).__arr__ = true
	self.n = 0
	return self
end

function arr_ifce.clone<T>(self: Arr<T>): Arr<T>
	return setmetatable(table.clone(self), arr_ifce) :: any
end

function arr_ifce.unpack<T>(self: Arr<T>): ...T
	return table.unpack(self, 1, self.n) :: T
end
function arr_ifce.pack<T>(...: T): Arr<T>
	return arr_ifce(...)
end

--#region ----------- 순서 변경 -----------
-- 무작위 셔플. rng 는 math.random 과 같은 (min, max) -> number 시그니처를
-- 받습니다 — 테스트에서 결정적인 rng 를 주입할 수 있게 하기 위함입니다.
function arr_ifce.shuffle_inplace<T>(self: Arr<T>, start: number?, last: number?, rng: ((min: number, max: number) -> number)?): Arr<T>
	start, last = arr_range(self.n, start, last)
	local random = rng or math.random
	for idx = last :: number, start :: number + 1, -1 do
		local jdx = random(start :: number, idx)
		self[idx], self[jdx] = self[jdx], self[idx]
	end
	return self
end
local arr_shuffle_inplace = arr_ifce.shuffle_inplace
-- 셔플한 새 배열을 만듭니다 (self 는 그대로)
function arr_ifce.shuffle<T>(self: Arr<T>, start: number?, last: number?, rng: ((min: number, max: number) -> number)?): Arr<T>
	return arr_shuffle_inplace(arr_ifce.clone(self), start, last, rng)
end

-- start~last 범위를 뒤집은 결과를 to (없으면 새 배열) 에 씁니다.
-- to 를 줬을 때 to_start 는 "덮어쓸 시작 위치"이며 기본값은 to 의 끝(이어붙이기)입니다.
function arr_ifce.reverse<T>(self: Arr<T>, start: number?, last: number?, to: Arr<T>?, to_start: number?): Arr<T>
	start, last = arr_range(self.n, start, last)
	local move_len = (last :: number) - (start :: number) + 1
	if move_len < 0 then
		move_len = 0
	end
	local result: Arr<T>
	if to then
		if to_start == nil then
			to_start = to.n + 1
		end
		local write_last = (to_start :: number) + move_len - 1
		if write_last > to.n then
			to.n = write_last
		end
		result = to
	else
		if to_start == nil then
			to_start = 1
		end
		result = arr_sized(move_len)
	end
	for offset = 0, move_len - 1 do
		result[(to_start :: number) + offset] = self[(last :: number) - offset]
	end
	return result
end
-- 자기 자신의 start~last 범위를 뒤집습니다
function arr_ifce.reverse_inplace<T>(self: Arr<T>, start: number?, last: number?): Arr<T>
	start, last = arr_range(self.n, start, last)
	local left, right = start :: number, last :: number
	while left < right do
		self[left], self[right] = self[right], self[left]
		left += 1
		right -= 1
	end
	return self
end
local arr_reverse_inplace = arr_ifce.reverse_inplace

-- start~last 범위를 shift 만큼 회전합니다. **shift 가 양수면 왼쪽으로** 돌립니다
-- (shift = 1 이면 [1,2,3] -> [2,3,1]). 음수는 오른쪽 회전이고, 범위 길이보다
-- 큰 값은 모듈러로 접힙니다. 세 번 뒤집기(reverse) 로 구현합니다.
function arr_ifce.rotate_inplace<T>(self: Arr<T>, shift: number, start: number?, last: number?): Arr<T>
	start, last = arr_range(self.n, start, last)
	local range_len = (last :: number) - (start :: number) + 1
	if range_len <= 1 then
		return self
	end
	local mid = shift % range_len
	if mid == 0 then
		return self
	end
	arr_reverse_inplace(self, start, start :: number + mid - 1)
	arr_reverse_inplace(self, start :: number + mid, last)
	arr_reverse_inplace(self, start, last)
	return self
end
local arr_rotate_inplace = arr_ifce.rotate_inplace
-- 회전한 범위를 to (없으면 새 배열) 에 이어붙입니다
function arr_ifce.rotate<T>(self: Arr<T>, shift: number, start: number?, last: number?, to: Arr<T>?): Arr<T>
	local at = if to then to.n + 1 else 1
	local result = arr_ifce.slice(self, start, last, to)
	return arr_rotate_inplace(result, shift, at, result.n)
end

-- 정렬된 새 배열을 돌려줍니다 (self 는 그대로).
-- table.sort 는 # 연산자로 범위를 잡기 때문에 trailing nil 이 있는 배열에서
-- 잘못된 구간을 정렬합니다. 1..n 을 조밀한 일반 테이블로 옮겨 정렬합니다.
function arr_ifce.sorted<T>(self: Arr<T>, comp: common.Comparator<T>?): Arr<T>
	local arr_len = self.n
	local buffer = table.create(arr_len)
	table.move(self, 1, arr_len, 1, buffer)
	if comp then
		-- table.sort 는 "a 가 b 보다 앞이냐" 를 묻습니다. compareTo 는 반대로
		-- "a 가 b 보다 크냐(> 0)" 를 돌려주므로 인자를 뒤집어 씁니다. boolean
		-- 비교자는 같음을 표현하지 못해서(compareTo 가 false 를 -1 로 접음)
		-- compareTo(a, b) < 0 을 그대로 쓰면 동치인 원소끼리 양방향으로 참이
		-- 되어 정렬이 깨집니다
		table.sort(buffer, function(a, b)
			return compareTo(b, a, comp) > 0
		end)
	else
		table.sort(buffer)
	end
	local result = arr_sized(arr_len)
	table.move(buffer, 1, arr_len, 1, result)
	return result
end
-- sorted 의 제자리 버전
function arr_ifce.sort_inplace<T>(self: Arr<T>, comp: common.Comparator<T>?): Arr<T>
	local arr_len = self.n
	local buffer = table.create(arr_len)
	table.move(self, 1, arr_len, 1, buffer)
	if comp then
		-- table.sort 는 "a 가 b 보다 앞이냐" 를 묻습니다. compareTo 는 반대로
		-- "a 가 b 보다 크냐(> 0)" 를 돌려주므로 인자를 뒤집어 씁니다. boolean
		-- 비교자는 같음을 표현하지 못해서(compareTo 가 false 를 -1 로 접음)
		-- compareTo(a, b) < 0 을 그대로 쓰면 동치인 원소끼리 양방향으로 참이
		-- 되어 정렬이 깨집니다
		table.sort(buffer, function(a, b)
			return compareTo(b, a, comp) > 0
		end)
	else
		table.sort(buffer)
	end
	table.move(buffer, 1, arr_len, 1, self)
	return self
end
--#endregion ----------- 순서 변경 -----------

--#region ----------- 구간 치환/삭제 -----------
-- start~last 구간을 with 의 내용으로 바꾼 새 배열을 만듭니다 (self 는 그대로)
function arr_ifce.replace<T>(self: Arr<T>, start: number, last: number, with: Arr<T>): Arr<T>
	return arr_ifce.replace_inplace(arr_ifce.clone(self), start, last, with)
end
-- start~last 구간을 with 의 내용으로 바꿉니다. 구간이 비어 있으면(start > last)
-- 그 자리에 삽입만 합니다
function arr_ifce.replace_inplace<T>(self: Arr<T>, start: number, last: number, with: Arr<T>): Arr<T>
	local from, until_ = arr_range(self.n, start, last)
	if from <= until_ then
		arr_ifce.erase_inplace(self, from, until_)
	end
	return arr_ifce.insert_array(self, from, with)
end

-- start~last 구간을 제거한 새 배열을 만듭니다 (self 는 그대로)
function arr_ifce.erase<T>(self: Arr<T>, start: number?, last: number?): Arr<T>
	return arr_ifce.erase_inplace(arr_ifce.clone(self), start, last)
end
function arr_ifce.erase_inplace<T>(self: Arr<T>, start: number?, last: number?): Arr<T>
	local len = self.n
	start, last = arr_range(len, start, last)

	-- 뒤집힌(빈) 구간은 아무것도 지우지 않습니다. 가드가 없으면 removed 가
	-- 음수가 되어 배열이 오히려 늘어납니다
	if start > last then
		return self
	end

	if start == 1 and last == len then
		arr_ifce.clear(self)
		return self
	end

	local removed = (last :: number) - (start :: number) + 1
	local after_len = len - removed

	table.move(self, (last :: number) + 1, len, (start :: number))
	for idx = after_len + 1, len do
		self[idx] = nil :: any
	end
	self.n = after_len

	return self
end

--#region stream api implement
type ReduceCallBack<T, U> = 
	((accumulator: U, currentValue: T) -> U)
	& ((accumulator: U, currentValue: T, currentIndex: number) -> U)
	& ((accumulator: U, currentValue: T, currentIndex: number, arr: Arr<T>) -> U)
type CallBack<T, Ret> =
	((element: T, index: number, arr: Arr<T>) -> Ret)
	& ((element: T, index: number) -> Ret)
	& ((element: T) -> Ret)
	& (() -> Ret)
type CallBackVar<T, Ret> =
	((element: T, index: number, arr: Arr<T>) -> ...Ret)
	& ((element: T, index: number) -> ...Ret)
	& ((element: T) -> ...Ret)
	& (() -> ...Ret)
type CallBackWithUserdata<T, Ret, Userdata> =
	((element: T, index: number, arr: Arr<T>, userdata: Userdata) -> Ret)
	& ((element: T, index: number, arr: Arr<T>) -> Ret)
	& ((element: T, index: number) -> Ret)
	& ((element: T) -> Ret)
	& (() -> Ret)

-- 각 배열을 합친 새로운 배열을 만듭니다
function arr_ifce.merge<T>(...: Arr<T>): Arr<T>
	local len = select("#", ...)
	local total = 0
	local result = arr_sized(0)
	for idx = 1, len do
		local item = select(idx, ...)
		local item_len = item.n
		if item_len == 0 then
			continue
		elseif item_len == 1 then
			result[total + 1] = item[1]
		else
			table.move(item, 1, item_len, total + 1, result)
		end
		total += item_len
	end
	result.n = total
	return result
end
-- 각 배열을 자신 배열 뒤에 차례대로 붙입니다
function arr_ifce.merge_inplace<T>(self: Arr<T>, ...: Arr<T>): Arr<T>
	local len = select("#", ...)
	local total = self.n
	for idx = 1, len do
		local item = select(idx, ...)
		local item_len = item.n
		if item_len == 0 then
			continue
		elseif item_len == 1 then
			self[total + 1] = item[1]
		else
			table.move(item, 1, item_len, total + 1, self)
		end
		total += item_len
	end
	self.n = total
	return self
end

-- 각 요소 T를 callback 으로 ...U로 변환한 새로운 배열을 생성합니다, 혹은 to 를 제공하는 경우
-- to 의 가장 뒤에 붙여넣습니다
function arr_ifce.flatmap<T, G>(self: Arr<T>, fn: CallBackVar<T, G>, to: Arr<G>?): Arr<G>
	to = to or arr_sized(0)
	for i = 1, self.n do
		arr_push_many(to, fn(self[i], i, self))
	end
	return to :: Arr<G>
end
-- 현 배열 self의 요소 T를 callback 으로 ...U로 변환하여 설정합니다
-- 새로운 배열이 생성되지 않으며, 현 배열이 arr<G> 로 변환됩니다
function arr_ifce.flatmap_inplace<T, G>(self: Arr<T>, callback: CallBackVar<T, G>): Arr<G>
	local idx = 1
	local old_len = self.n
	local len = old_len
	local last
	local last_len
	local offset = 0 -- should be uninited
	while idx <= len do
		last = table.pack(callback(self[idx], idx, self))
		last_len = last.n
		if last_len == 0 then
			offset += 1
			idx += 1
			continue
		elseif last_len == 1 then
			self[idx - offset] = last[1]
			idx += 1
			continue
		end
		table.move(self, idx + 1, len, idx + last_len - offset)
		table.move(last, 1, last_len, idx - offset, self)
		len += last_len - 1 - offset
		idx += last_len - offset
		offset = 0
	end
	self.n = len
	for i = len + 1, old_len do
		self[i] = nil :: any
	end
	return (self :: any) :: Arr<G>
end

-- 각 요소 T를 callback 으로 U로 변환한 새로운 배열을 생성합니다, 혹은 to 를 제공하는 경우
-- to 의 가장 뒤에 붙여넣습니다
function arr_ifce.map<T, G>(self: Arr<T>, callback: CallBack<T, G>, to: Arr<G>?): Arr<G>
	local offset = if to then to.n else 0
	local arr_len = self.n
	to = to or arr_sized(arr_len)
	for idx = 1, arr_len do
		(to :: Arr<G>)[offset + idx] = callback(self[idx], idx, self)
	end
	return to :: Arr<G>
end
-- 현 배열 self의 요소 T를 callback 으로 U로 변환하여 설정합니다
-- 새로운 배열이 생성되지 않으며, 현 배열이 arr<G> 로 변환됩니다
function arr_ifce.map_inplace<T, G>(self: Arr<T>, callback: CallBack<T, G>): Arr<G>
	local arr_len = self.n
	for idx = 1, arr_len do
		((self :: unknown) :: Arr<G>)[idx] = callback(self[idx], idx, self)
	end
	return (self :: unknown) :: Arr<G>
end

--FIXME: ranged 로 변경
-- 내부 요소를 callback 으로 소모하여 지웁니다
function arr_ifce.consume<T>(self: Arr<T>, callback: CallBack<T, any>): Arr<T>
	for idx = 1, self.n do
		callback(self[idx], idx, self)
	end
	table.clear(self)
	self.n = 0
	return self
end
--FIXME: ranged 로 변경
-- 내부 요소를 callback 을 통해 accumulator 로 변환합니다
function arr_ifce.reduce<T, U>(self: Arr<T>, callback: ReduceCallBack<T, U>, initialValue: U): U
	for idx = 1, self.n do
		initialValue = callback(initialValue, self[idx], idx, self)
	end
	return initialValue
end

--FIXME: ranged 로 변경
-- callback 이 참이 되는 요소만 포함하는 새로운 배열을 생성합니다, 혹은 to 를 제공하는 경우
-- to 의 가장 뒤에 붙여넣습니다
function arr_ifce.filter<T>(self: Arr<T>, callback: CallBack<T, boolean>, to: Arr<T>?): Arr<T>
	to = to or arr_sized(0)
	local to_len = (to :: Arr<T>).n
	local idx = 1
	local len = self.n
	local defer = 0
	local in_range
	while true do
		in_range = idx <= len
		if in_range and callback(self[idx], idx, self) then
			defer += 1
		elseif defer ~= 0 then
			table.move(self, idx - defer, idx - 1, to_len + 1, to)
			to_len += defer
			defer = 0
		end
		if not in_range then
			break
		end
		idx += 1
	end
	(to :: Arr<T>).n = to_len
	return to :: Arr<T>
end
--FIXME: ranged 로 변경 (start/last 인자는 아직 없음)
-- 현 배열 self의 요소중 callback이 참이 되지 않는 요소를 삭제합니다
-- 자기 자신 배열을 반환합니다
function arr_ifce.filter_inplace<T>(self: Arr<T>, callback: CallBack<T, boolean>): Arr<T>
	local len = self.n
	local kept = 0
	local item
	for idx = 1, len do
		item = self[idx]
		if callback(item, idx, self) then
			kept += 1
			-- 앞쪽으로 밀린 게 없으면 자기 자리 그대로라 쓸 필요가 없음
			if kept ~= idx then
				self[kept] = item
			end
		end
	end
	for idx = kept + 1, len do
		self[idx] = nil :: any
	end
	self.n = kept
	return self
end

-- callback 의 결과가 참으로 간주되는 요소가 나오면 결과를 반환합니다
-- 만약 하나도 없다면 nil 을 반환합니다
-- start 와 last 를 지정하지 않으면 배열 전체에서 작동합니다
function arr_ifce.some<T, G>(self: Arr<T>, fn: CallBack<T, G>, start: number?, last: number?): G?
	start, last = arr_range(self.n, start, last)
	local result
	for idx = start :: number, last :: number do
		result = fn(self[idx], idx, self)
		if result then
			return result
		end
	end
	return result
end
-- self의 요소에 대해 callback 의 결과가 참인지 테스트합니다
-- start 와 last 를 지정하지 않으면 배열 전체에서 작동합니다
function arr_ifce.every<T>(self: Arr<T>, fn: CallBack<T, boolean>, start: number?, last: number?): boolean
	start, last = arr_range(self.n, start, last)
	for idx = start :: number, last :: number do
		if not fn(self[idx], idx, self) then
			return false
		end
	end
	return true
end

-- 부분적으로 flat을 적용한 새로운 배열을 생성합니다, 혹은 to 를 제공하는 경우
-- to 의 가장 뒤에 붙여넣습니다. range 에 해당하지 않는 요소는 복사되지 않습니다
function arr_ifce.rangeflat<T>(self: Arr<T | Arr<T>>, start: number?, last: number?, to: Arr<T>?): Arr<T | Arr<T>>
	local arr_len = self.n
	start, last = arr_range(arr_len, start, last)
	to = to or arr_sized(0)
	local to_len = (to :: Arr<T>).n
	local inner
	local inner_len
	-- 연속된 비배열 요소 구간 [run_start, idx-1] 을 모아 한 번에 옮기기 위한 커서
	local run_start = start :: number
	local run_len
	for idx = start :: number, last :: number do
		inner = self[idx]
		if not arr_is_arr(inner) then
			continue
		end
		-- 앞서 밀어둔 비배열 구간을 먼저 flush
		run_len = idx - run_start
		if run_len == 1 then
			(to :: Arr<T>)[to_len + 1] = self[run_start] :: any
			to_len += 1
		elseif run_len > 1 then
			table.move(self, run_start, idx - 1, to_len + 1, to :: Arr<T>)
			to_len += run_len
		end
		-- 중첩 배열을 펼쳐 이어붙임
		inner_len = inner.n
		if inner_len == 1 then
			(to :: Arr<T>)[to_len + 1] = inner[1]
		elseif inner_len > 1 then
			table.move(inner, 1, inner_len, to_len + 1, to :: Arr<T>)
		end
		to_len += inner_len
		run_start = idx + 1
	end
	-- 마지막 비배열 구간 flush
	run_len = last :: number - run_start + 1
	if run_len == 1 then
		(to :: Arr<T>)[to_len + 1] = self[run_start] :: any
		to_len += 1
	elseif run_len > 1 then
		table.move(self, run_start, last :: number, to_len + 1, to :: Arr<T>)
		to_len += run_len
	end
	(to :: Arr<T>).n = to_len
	return to :: Arr<T>
end
--FIXME: ranged 로 다시 작성, 밀린 정도를 리턴에 포함
function arr_ifce.rangeflat_inplace<T>(self: Arr<T | Arr< T >>, start: number?, last: number?): Arr<T | Arr<T>>
	local idx = 1
	local len = self.n
	local inner, inner_len
	while idx <= len do
		inner = self[idx]
		if not arr_is_arr(inner) then
			idx += 1
			continue
		end

		inner_len = inner.n
		if inner_len == 1 then
			self[idx] = inner[1]
			idx += 1
			continue
		elseif inner_len == 0 then
			table.remove(self, idx)
			len -= 1
			continue
		end

		table.move(self, idx + 1, len, idx + inner_len)
		table.move(inner, 1, inner_len, idx, self)

		len += inner_len - 1
		idx += inner_len
	end
	self.n = len
	return self :: Arr<T>
end

function arr_ifce.flat<T>(self: Arr<T | Arr<T>>, to: Arr<T>?): Arr<T>
	return arr_ifce.rangeflat(self, nil, nil, to) :: Arr<T>
end
function arr_ifce.flat_inplace<T>(self: Arr<T | Arr<T>>): Arr<T>
	return arr_ifce.rangeflat_inplace(self) :: Arr<T>
end

function arr_ifce.max<T>(self: Arr<T>, base: T?, comp: common.Comparator<T>?): T?
	local item
	for i = 1, self.n do
		item = self[i]
		if base == nil or compareTo(item, base, comp) > 0 then
			base = item
		end
	end
	return base
end
function arr_ifce.min<T>(self: Arr<T>, base: T?, comp: common.Comparator<T>?): T?
	local item
	for i = 1, self.n do
		item = self[i]
		if base == nil or compareTo(item, base, comp) < 0 then
			base = item
		end
	end
	return base
end

function arr_ifce.sum<T>(self: Arr<T>, base: T?): T
	base = base or 0 :: any
	for i = 1, self.n do
		base += self[i] :: any
	end
	return base :: T
end
function arr_ifce.prod<T>(self: Arr<T>, base: T?): T
	base = base or 1 :: any
	for i = 1, self.n do
		base *= self[i] :: any
	end
	return base :: T
end
--#endregion stream api implement

function arr_ifce.fill<T>(self: Arr<T>, item: T, start: number?, last: number?): Arr<T>
	if item == nil then
		return self
	end
	local arr_len = self.n
	start = start or 1
	last = last or arr_len
	for idx = start :: number, last :: number do
		self[idx] = item
	end
	if last > arr_len then
		self.n = last :: number
	end
	return self
end
-- fill_by_func

local function arr_iter<T>(self: Arr<T>, idx: number): (number?, T?)
	idx += 1
	if self.n :: number >= idx then
		return idx, self[idx]
	end
	return nil, nil
end
function arr_ifce.iter<T>(self: Arr<T>): ((self: Arr<T>, idx: number) -> (number?, T?), Arr<T>, number)
	return arr_iter, self, 0
end
arr_ifce.__iter = arr_ifce.iter

function arr_ifce.len(self: Arr<any>): number
	return self.n
end
function arr_ifce.empty(self: Arr<any>): boolean
	return self.n == 0
end
function arr_ifce.each<T, Userdata>(self: Arr<T>, fn: CallBackWithUserdata<T, Userdata?, Userdata?>, base: Userdata?): Userdata?
	local done
	for i = 1, self.n do
		base, done = fn(self[i], i, self, base)
		if done then
			break
		end
	end
	return base
end
function arr_ifce.join<T>(self: Arr<T>, delimiter: string?): string
	return table.concat(self, delimiter, 1, self.n)
end
function arr_ifce.count<T>(self: Arr<T>, fn: CallBack<T, any>): number
	local count = 0
	for i = 1, self.n do
		if fn(self[i], i, self) then
			count += 1
		end
	end
	return count
end
function arr_ifce.find<T>(self: Arr<T>, fn: CallBack<T, any>): (T?, number?)
	local item
	for i = 1, self.n do
		item = self[i]
		if fn(item, i, self) then
			return item, i
		end
	end
	return nil, nil
end

function arr_ifce.slice<T>(self: Arr<T>, start: number?, last: number?, to: Arr<T>?, to_start: number?): Arr<T>
	start, last = arr_range(self.n, start, last)
	local move_len = last :: number - start :: number + 1
	if to then
		local to_len = to.n
		if to_start == nil then
			to_start = to_len + 1
		end
		to.n = to_len + move_len
		if to_len >= to_start then
			table.move(to, to_len - to_start + 1, to_len, to_start + move_len)
		end
	else
		if to_start == nil then
			to_start = 1
		end
		to = arr_sized(move_len)
	end
	if move_len == 0 then
	elseif move_len == 1 then
		(to :: Arr<T>)[to_start :: number] = self[start :: any]
	else
		table.move(self, start :: number, last :: number, to_start :: number, to :: Arr<T>)
	end
	return to :: Arr<T>
end
function arr_ifce.slice_inplace<T>(self: Arr<T>, start: number?, last: number?): Arr<T>
	-- Empty: arr length is 0
	local arr_len = self.n
	if arr_len == 0 then
		return self
	end

	-- Empty: start and last across
	start, last = arr_range(arr_len, start, last)
	if start > last then
		return arr_ifce.clear(self)
	end

	-- No action required
	if start == 1 and last == arr_len then
		return self
	end

	-- Move elements to front
	if start ~= 1 then
		table.move(self, start :: number, last :: number, 1)
	end

	-- Remove tailing
	for idx = last :: number - start :: number + 2, arr_len do
		self[idx] = nil :: any
	end

	-- Update length
	self.n = last :: number - start :: number + 1
	return self
end

function arr_ifce.equal<T>(self: Arr<T>, to: Arr<T>): boolean
	local arr_len = self.n
	if arr_len ~= to.n then
		return false
	end
	for idx = 1, arr_len do
		if self[idx] ~= to[idx] then
			return false
		end
	end
	return true
end
arr_ifce.__eq = arr_ifce.equal

-- stylua: ignore start
export type ArrInterface = typeof(arr_ifce)
export type Arr<T> = {
	n: number,
	[number]: T,
} & ArrInterface
local Arr = (arr_ifce :: unknown) :: (<T>(...T|any) -> (Arr<T>)) & Arr<any>

return Arr
-- stylua: ignore end
