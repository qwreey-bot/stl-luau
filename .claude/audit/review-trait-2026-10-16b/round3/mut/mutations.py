# id -> (file, old, new, 설명) — 기준: b2b514f
F = "src/Trait/init.luau"
LOOP_OLD = '''				for i, p in fhead do
					if i > 1 then
						if isDefGeneric(p) then
							bareGeneric = true
						elseif p:is("union") or p:is("intersection") then
							for _, c in p:components() do
								if isDefGeneric(c) then
									bareGeneric = true
								end
							end
						end
					end
				end
'''
M = {
 "X01": (F, "				for i, p in fhead do\n					if i > 1 then\n						if isDefGeneric(p)", "				for i, p in fhead do\n					if i >= 1 then\n						if isDefGeneric(p)", "첫 인자(주체)도 봄 → 모든 칸 다시 지음"),
 "X02": (F, LOOP_OLD, "", "bareGeneric 검사 통째 제거(c8cae64 로 되돌림)"),
 "X03": (F, '''						elseif p:is("union") or p:is("intersection") then
							for _, c in p:components() do
								if isDefGeneric(c) then
									bareGeneric = true
								end
							end
''', "", "유니온·교집합 갈래 제거"),
 "X04": (F, "				const function isDefGeneric(t: type): boolean\n					for _, g in defGenerics do\n						if t == g then",
            "				const function isDefGeneric(t: type): boolean\n					for gi, g in defGenerics do\n						if gi > 1 and t == g then", "Self 는 맨 제네릭으로 안 셈"),
 "X05": (F, "				const function isDefGeneric(t: type): boolean\n					for _, g in defGenerics do\n						if t == g then",
            "				const function isDefGeneric(t: type): boolean\n					for gi, g in defGenerics do\n						if gi == 1 and t == g then", "Self 만 셈"),
 "X06": (F, "				local keepOriginal = not bareGeneric and hasIndexer(fnType, {})", "				local keepOriginal = not bareGeneric", "hasIndexer 조건 뺌(모든 칸 유지)"),
 "X07": (F, "				local keepOriginal = not bareGeneric and hasIndexer(fnType, {})", "				local keepOriginal = bareGeneric or hasIndexer(fnType, {})", "부정 뒤집음"),
 "X08": (F, "				for i, p in fhead do\n					if i > 1 then\n						if isDefGeneric(p)", "				for i, p in fhead do\n					if i > 2 then\n						if isDefGeneric(p)", "둘째 인자를 건너뜀"),
 "X09": (F, '''							for _, c in p:components() do
								if isDefGeneric(c) then''', '''							for _, c in { p:components()[1] } do
								if isDefGeneric(c) then''', "유니온의 첫 갈래만"),
 "X10": (F, "						if t == g then\n							return true\n						end\n					end\n					return false\n				end\n				for i, p in fhead",
            "						if t:is(\"generic\") then\n							return true\n						end\n					end\n					return false\n				end\n				for i, p in fhead", "아무 제네릭이나(칸 자신의 U 포함)"),
 "X11": (F, "				local keepOriginal = not bareGeneric and hasIndexer(fnType, {})", "				local keepOriginal = false", "항상 다시 지음(79c2d6d 로)"),
 "X12": (F, "									bareGeneric = true\n								end\n							end\n						end", "									bareGeneric = false\n								end\n							end\n						end", "유니온에서 찾으면 false"),
}
