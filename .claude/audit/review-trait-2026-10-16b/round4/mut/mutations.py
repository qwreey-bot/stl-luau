# id -> (old, new, 설명) — 기준 a7f4c6a, 파일 src/Trait/init.luau
HEADLOOP = """				for i, p in fhead do
					if i > 1 and isDefGeneric(p) then
						bareGeneric = true
					end
				end
"""
TAIL = """				if fp.tail ~= nil and isDefGeneric(fp.tail) then
					bareGeneric = true
				end
"""
M = {
 "Y01": (TAIL, "", "꼬리 검사 제거(D1 되돌림)"),
 "Y02": (TAIL, TAIL.replace("fp.tail ~= nil and isDefGeneric(fp.tail)", "fp.tail ~= nil"), "꼬리가 있기만 하면(...any 포함) 맨 인자로"),
 "Y03": (TAIL, TAIL.replace("isDefGeneric(fp.tail)", "fp.tail == selfG"), "꼬리는 Self 만"),
 "Y04": (TAIL, TAIL.replace("isDefGeneric(fp.tail)", "not isDefGeneric(fp.tail)"), "꼬리 조건 부정"),
 "Y05": (TAIL, TAIL.replace("bareGeneric = true", "bareGeneric = false"), "꼬리에서 false"),
 "Y06": (HEADLOOP, "", "머리 검사 제거(꼬리만)"),
 "Y07": (HEADLOOP, HEADLOOP.replace("i > 1 and", "i > 2 and"), "둘째 인자 건너뜀"),
 "Y08": (HEADLOOP, HEADLOOP.replace("i > 1 and isDefGeneric(p)", "i > 1"), "둘째부터 아무 인자나"),
 "Y09": (HEADLOOP, HEADLOOP.replace("if i > 1 and isDefGeneric(p) then", "if i > 1 and (isDefGeneric(p) or p:is(\"union\")) then"), "유니온도 셈(D2 일부 되돌림)"),
 "Y10": (HEADLOOP, HEADLOOP.replace("if i > 1 and isDefGeneric(p) then", "if i > 1 and (isDefGeneric(p) or p:is(\"generic\")) then"), "칸 자신의 제네릭(U)도 셈"),
 "Y11": (HEADLOOP + "				-- 가변", HEADLOOP.replace("i > 1 and isDefGeneric(p)", "i == #fhead and isDefGeneric(p)") + "				-- 가변", "마지막 인자만 봄"),
 "Y12": ("				local keepOriginal = not bareGeneric and hasIndexer(fnType, {})", "				local keepOriginal = not bareGeneric and hasIndexer(fnType, {}) and not usesSelf", "Self 를 쓰는 칸은 다시 지음"),
 "Y13": ("						if t == g then\n							return true", "						if t == g and not g:ispack() then\n							return true", "팩은 맨 인자로 안 셈"),
 "Y14": (TAIL, TAIL.replace("isDefGeneric(fp.tail)", "fp.tail:is(\"generic\")"), "꼬리: 아무 제네릭이나"),
}
