# 기준 2cd46e6, src/Trait/init.luau — 새 반환 세기 줄
HEAD = """				for _, r in fr2.head or {} do
					if isDefGeneric(r) then
						bareGeneric = true
					end
				end
"""
TAIL = """				if fr2.tail ~= nil and isDefGeneric(fr2.tail) then
					bareGeneric = true
				end
				local keepOriginal"""
M = {
 "R01": (HEAD, "", "반환 머리 검사 제거(①되돌림)"),
 "R02": (TAIL, "				local keepOriginal", "반환 꼬리 검사 제거"),
 "R03": (HEAD, HEAD.replace("isDefGeneric(r)", "r == selfG"), "반환 머리는 Self 만"),
 "R04": (HEAD, HEAD.replace("isDefGeneric(r)", "isDefGeneric(r) and r ~= selfG"), "반환 머리에서 Self 제외(리뷰어 처방)"),
 "R05": (HEAD, HEAD.replace("isDefGeneric(r)", "isDefGeneric(r) or r:is(\"union\")"), "반환 유니온 갈래도 셈(T?)"),
 "R06": (HEAD, HEAD.replace("for _, r in fr2.head or {} do", "for ri, r in fr2.head or {} do").replace("if isDefGeneric(r) then", "if ri == 1 and isDefGeneric(r) then"), "첫 반환만 봄"),
 "R07": (TAIL, TAIL.replace("fr2.tail ~= nil and isDefGeneric(fr2.tail)", "fr2.tail ~= nil"), "반환 꼬리가 있기만 하면(...any 포함)"),
 "R08": (HEAD, HEAD.replace("isDefGeneric(r)", "r:is(\"generic\")"), "반환: 아무 제네릭이나(칸 자신의 U 포함)"),
 "R09": (HEAD, HEAD.replace("bareGeneric = true", "bareGeneric = false"), "반환 머리에서 false"),
 "R10": (HEAD, HEAD.replace("for _, r in fr2.head or {} do", "for _, r in fhead do"), "반환 대신 인자를 다시 봄(복붙 실수)"),
 "R11": (HEAD, HEAD.replace("isDefGeneric(r)", "not isDefGeneric(r)"), "반환 조건 부정"),
}
