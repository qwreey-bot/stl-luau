--!strict
--[[
	시제품: 기본 구현을 가진 트레이트들 (papers/07).

	- `List`   필수 다섯(위치 프로토콜) → `Each`·`Fold`·`Find`·`IndexOf`·`Contains`·`Count`·`ToTable`
	- `Build`  필수 둘(`New`, `PushBack`) — "같은 종류를 새로 만들어 채우기"
	- `Seq`    `List` 와 `Build` 를 **요구**(requires) → `Map`·`Filter` 가 같은 종류를 돌려줌
	- `Tree`   필수 넷(`Root`·`Left`·`Right`·`Value`) → `IsLeaf`·`Height`·`Size`·세 순회
	  (예전 과제의 `BinaryTree` 인터페이스 — 위치(`Key`)가 노드든 배열 인덱스든 같은 기본 구현)
]]
local Trait2 = require("./Trait2")

local List = Trait2.New("List", {
	required = { "Get", "FirstIndex", "LastIndex", "NextIndex", "PrevIndex" },
	defaults = function(impl, full)
		-- 필수 함수는 upvalue 로 — 원소마다 테이블 조회가 없습니다.
		const get, first, nextIndex = impl.Get, impl.FirstIndex, impl.NextIndex
		return {
			Each = function(self: any, fn: (any, any) -> ())
				local idx = first(self)
				while idx ~= nil do
					fn(get(self, idx), idx)
					idx = nextIndex(self, idx)
				end
			end,
			Fold = function(self: any, init: any, fn: (any, any) -> any): any
				local acc, idx = init, first(self)
				while idx ~= nil do
					acc = fn(acc, get(self, idx))
					idx = nextIndex(self, idx)
				end
				return acc
			end,
			Find = function(self: any, pred: (any) -> boolean): any
				local idx = first(self)
				while idx ~= nil do
					const item = get(self, idx)
					if pred(item) then
						return item
					end
					idx = nextIndex(self, idx)
				end
				return nil
			end,
			IndexOf = function(self: any, item: any): any
				local idx = first(self)
				while idx ~= nil do
					if get(self, idx) == item then
						return idx
					end
					idx = nextIndex(self, idx)
				end
				return nil
			end,
			-- 다른 기본 구현을 부를 땐 `full` 로 — 구현이 IndexOf 를 재정의했으면 그 판을 씁니다.
			Contains = function(self: any, item: any): boolean
				return full.IndexOf(self, item) ~= nil
			end,
			Count = function(self: any): number
				local total, idx = 0, first(self)
				while idx ~= nil do
					total += 1
					idx = nextIndex(self, idx)
				end
				return total
			end,
			ToTable = function(self: any): { any }
				const out = {}
				local count, idx = 0, first(self)
				while idx ~= nil do
					count += 1
					out[count] = get(self, idx)
					idx = nextIndex(self, idx)
				end
				return out
			end,
		}
	end,
})

local Build = Trait2.New("Build", { required = { "New", "PushBack" } })

local Seq = Trait2.New("Seq", {
	required = {},
	requires = { List, Build },
	defaults = function(_impl, _full, deps)
		const list, build = deps[List], deps[Build]
		const get, first, nextIndex = list.Get, list.FirstIndex, list.NextIndex
		const new, push = build.New, build.PushBack
		return {
			Map = function(self: any, fn: (any) -> any): any
				const out = new()
				local idx = first(self)
				while idx ~= nil do
					push(out, fn(get(self, idx)))
					idx = nextIndex(self, idx)
				end
				return out
			end,
			Filter = function(self: any, pred: (any) -> boolean): any
				const out = new()
				local idx = first(self)
				while idx ~= nil do
					const item = get(self, idx)
					if pred(item) then
						push(out, item)
					end
					idx = nextIndex(self, idx)
				end
				return out
			end,
		}
	end,
})

local Tree = Trait2.New("Tree", {
	required = { "Root", "Left", "Right", "Value" },
	defaults = function(impl, full)
		const left, right, value = impl.Left, impl.Right, impl.Value
		local function height(self: any, pos: any): number
			if pos == nil then
				return 0
			end
			return math.max(height(self, left(self, pos)), height(self, right(self, pos))) + 1
		end
		local function preorder(self: any, pos: any, depth: number, fn: (any, any, number) -> ())
			if pos == nil then
				return
			end
			fn(value(self, pos), pos, depth)
			preorder(self, left(self, pos), depth + 1, fn)
			preorder(self, right(self, pos), depth + 1, fn)
		end
		local function inorder(self: any, pos: any, depth: number, fn: (any, any, number) -> ())
			if pos == nil then
				return
			end
			inorder(self, left(self, pos), depth + 1, fn)
			fn(value(self, pos), pos, depth)
			inorder(self, right(self, pos), depth + 1, fn)
		end
		local function postorder(self: any, pos: any, depth: number, fn: (any, any, number) -> ())
			if pos == nil then
				return
			end
			postorder(self, left(self, pos), depth + 1, fn)
			postorder(self, right(self, pos), depth + 1, fn)
			fn(value(self, pos), pos, depth)
		end
		return {
			IsLeaf = function(self: any, pos: any): boolean
				return pos ~= nil and left(self, pos) == nil and right(self, pos) == nil
			end,
			Height = function(self: any): number
				return height(self, impl.Root(self))
			end,
			Preorder = function(self: any, fn: (any, any, number) -> ())
				preorder(self, impl.Root(self), 0, fn)
			end,
			Inorder = function(self: any, fn: (any, any, number) -> ())
				inorder(self, impl.Root(self), 0, fn)
			end,
			Postorder = function(self: any, fn: (any, any, number) -> ())
				postorder(self, impl.Root(self), 0, fn)
			end,
			Size = function(self: any): number
				local total = 0
				full.Preorder(self, function()
					total += 1
				end)
				return total
			end,
		}
	end,
})

return { List = List, Build = Build, Seq = Seq, Tree = Tree }
