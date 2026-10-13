--!strict
--[[
	Node 의 타입 둘 — 폴더 안의 도구 파일들이 같이 쓰는 말단(아무 도구도 require 하지 않음).
	설명은 `src/Node/init.luau` 머리.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

-- 고칠 수 있는 노드.
export type Node<T> = { value: T, [number]: Node<T>? }
-- 읽기만 하는 노드. `Node<T>` 는 그대로 이 자리에 들어갑니다.
export type NodeRead<T> = { read value: T, read [number]: NodeRead<T>? }

return {}
