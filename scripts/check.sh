#!/usr/bin/env bash
# 타입 검사 + 테스트. quad 의 scripts/test.sh 를 따릅니다.
#
# 타입 검사기는 luau-lsp 가 아니라 **luau-analyze** 입니다 — 근거는
# .claude/base/typing-limits.md 의 "체커: luau-analyze" 절. 플래그가 필요
# 없습니다: new solver 가 기본이고, strict 여부는 .luaurc 와 각 파일 상단의
# --!strict 가 정합니다.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

# tests 를 넣으면 require 로 src 도 같이 끌려와 같은 파일이 "src/arr.luau" 와
# "./src/arr.luau" 두 경로로 중복 보고됩니다. 정규화 후 중복을 지웁니다.
out=$(luau-analyze src tests 2>&1 | sed "s|^$PWD/||; s|^\./||" | sort -u)
[ -n "$out" ] && printf '%s\n' "$out"

echo
echo "=== 타입 진단 요약 (파일별 TypeError)"
printf '%s\n' "$out" | grep '): TypeError:' | grep -oE '^[^(]+' | sort | uniq -c
echo "총 $(printf '%s\n' "$out" | grep -c '): TypeError:')건"
# ⭐ 총 건수 게이트. [2026-09-22 부터] 기준선은 **0건**입니다 — 재작성이
# 끝나 src-old 가 사라졌으므로 더 이상 "원래 그만큼 났다" 가 없습니다.
#
# 0건을 기준으로 삼는 게 안전한 이유: 이 저장소에서 0건은 원래 경보입니다
# (타입 검사가 통째로 죽어도 0건이 나옵니다). 그걸 아래 **음성 대조군
# 배터리**가 막아 줍니다 — 틀린 코드가 정말 틀리다고 나오는지 따로 세니,
# 0건이 "검사가 죽은 0건" 이 아니라 "정말 깨끗한 0건" 임이 보장됩니다.
# 둘은 같이 있어야 뜻이 있습니다.
total=$(printf '%s\n' "$out" | grep -c '): TypeError:')
if [ "$total" != "0" ]; then
	echo "  → TypeError 가 $total 건 있습니다. 기준선은 0건입니다."
	fail=1
fi

# src 의 린트 경고(LocalShadow·LocalUnused 등)도 0건이 기준선입니다. TypeError 만
# 세면 이름 바꾸기에서 생긴 그림자 변수 같은 경고가 조용히 쌓였습니다(M0 4라운드).
# tests 는 실험적 코드가 많아 제외합니다.
lint=$(printf '%s\n' "$out" | grep -E '^src/[^(]+\([0-9]+,[0-9]+\): [A-Za-z]+: ' | grep -v '): TypeError:')
if [ -n "$lint" ]; then
	echo "  → src 린트 경고가 있습니다(기준선 0건):"
	printf '%s\n' "$lint" | sed 's/^/    /'
	fail=1
fi

# ⭐ 음성 대조군 배터리 — 이 저장소에서 가장 중요한 게이트다.
# 진단 건수가 0 이 되는 것은 "타입이 완벽해졌다" 가 아니라 보통 "타입 검사가
# 죽었다" 는 뜻이다(2026-08-31 에 실제로 0/6 이었다). 스파이크마다 나와야 할
# 에러 개수를 고정해두고, 줄면 NEG 가 조용히 안 잡히기 시작한 것으로 본다.
echo
echo "=== 음성 대조군 배터리 (스파이크별 기대 진단 건수)"
spike_fail=0
spike_n=0
# 셋째 칸(선택)은 **에러가 난 줄 번호 목록**입니다(같은 줄 여러 건은 반복).
# 건수만 세면 한 NEG 가 사라진 자리에 다른 줄의 에러가 새로 생겨 **상쇄**될
# 수 있습니다 — 2026-09-30 리뷰가 실제로 21 → 21 상쇄를 재현했습니다.
# `|| [ -n "$want" ]`: 파일 끝에 개행이 없으면 `read` 가 마지막 줄에서 거짓을
# 돌려 그 스파이크를 **조용히 건너뛰었습니다**(2026-09-30 2라운드 리뷰).
while IFS=$'\t' read -r want path lines || [ -n "$want" ]; do
	# 건너뛰기는 아래 행 수 세기(grep)와 **같은 규칙**이어야 합니다 — 앞에 공백을
	# 둔 주석이나 공백만 있는 줄이 경로 없는 MISSING 으로 떨어졌습니다(3라운드).
	if [[ $want =~ ^[[:space:]]*(#|$) ]]; then
		continue
	fi
	# CRLF 의 \r 과 칸 끝 공백은 눈에 안 보이는 "줄이 다릅니다" 를 만들었습니다.
	want=${want//[[:space:]]/}
	path=${path%"${path##*[![:space:]]}"}
	lines=${lines//[[:space:]]/}
	if [ ! -f "$path" ]; then
		echo "  MISSING  $path"
		spike_fail=1
		continue
	fi
	base=$(basename "$path")
	got_lines=$(luau-analyze "$path" 2>&1 |
		grep -oE "(^|/)${base//./\\.}\([0-9]+,[0-9]+\): TypeError: " |
		sed -E 's/.*\(([0-9]+),.*/\1/' | sort -n | paste -sd, -)
	got=$(if [ -z "$got_lines" ]; then echo 0; else echo "$got_lines" | tr ',' '\n' | wc -l | tr -d ' '; fi)
	spike_n=$((spike_n + 1))
	if [ "$got" != "$want" ]; then
		echo "  FAIL  $path"
		echo "        기대 $want 건, 실측 $got 건 (줄: ${got_lines:-없음})"
		spike_fail=1
	elif [ "$want" != "0" ] && [ -z "$lines" ]; then
		echo "  FAIL  $path"
		echo "        에러 줄 칸이 비었습니다 — 건수만으로는 상쇄를 못 막습니다. 실측 줄: $got_lines"
		spike_fail=1
	elif [ -n "$lines" ] && [ "$lines" != "$got_lines" ]; then
		echo "  FAIL  $path"
		echo "        건수는 같지만 에러 줄이 다릅니다 — NEG 가 사라진 자리를 다른 에러가 메웠을 수 있음"
		echo "        기대 줄: $lines"
		echo "        실측 줄: $got_lines"
		spike_fail=1
	fi
done < scripts/spike-expectations.tsv
# 센 스파이크 수가 데이터 행 수와 같아야 합니다 — 읽기가 조용히 줄을 흘리는 걸 막는 마지막 그물.
spike_rows=$(grep -cvE '^[[:space:]]*(#|$)' scripts/spike-expectations.tsv)
if [ "$spike_n" != "$spike_rows" ]; then
	echo "  FAIL  스파이크를 $spike_n 개 셌는데 데이터 행은 $spike_rows 개입니다"
	spike_fail=1
fi
if [ "$spike_fail" = "0" ]; then
	echo "  스파이크 $spike_n 개 전부 기대치와 일치"
else
	echo "  → 어느 NEG 가 사라졌는지 확인할 것. 기대치를 바꿨다면"
	echo "     scripts/spike-expectations.tsv 도 같이 고칠 것."
	fail=1
fi

# ⭐ require 경로는 정적 검사가 못 잡는다 — @self 대신 ./ 를 쓰면 luau-analyze 는
# 진단 0건으로 통과하고 런타임에서만 크래시한다(quad qa-round5 PS-9, 자체 실측).
# 그래서 모든 모듈을 실제로 require 해본다. init.luau 를 새로 추가할 때 특히 중요.
echo
echo "=== require 게이트 (모든 src 모듈을 런타임에 불러봄)"
# 프로브는 저장소 루트에 둬야 ./src 가 올바르게 해석된다
req_probe=".check-require-probe.luau"
trap 'rm -f "$req_probe"' EXIT
req_fail=0
while IFS= read -r m; do
	[ -s "$m" ] || continue   # 빈 파일은 건너뜀
	# init.luau 는 디렉터리 자신을 가리킨다: src/init.luau → ./src
	rel="${m%.luau}"; rel="${rel%/init}"; path="./$rel"
	printf 'require("%s")\nreturn true\n' "$path" > "$req_probe"
	if ! out=$(luau "$req_probe" 2>&1); then
		echo "  FAIL  $path"
		printf '        %s\n' "$(printf '%s' "$out" | head -1)"
		req_fail=1
	fi
done < <(find src -name "*.luau" | sort)
if [ "$req_fail" = "0" ]; then echo "  모든 모듈 require OK"; else fail=1; fi

# 에러는 `Common.raise` 로만 — 손으로 센 level(`error(msg, 2)`)은 -O2 인라인에서
# 틀립니다. 되던지기는 `Common.rethrow`. 그리고 raise 가 걷다 멈추지
# 않도록 **모든 모듈이 자기 파일을 등록**해야 합니다(빠지면 그 모듈의 줄을 가리킴).
echo
echo "=== 에러 규약 (Common.raise + 모듈 등록)"
err_fail=0
# 파일 전체를 한 번 훑어 왼쪽부터 **주석을 지우고**(문자열 안의 `--`·`--[[` 에 속지 않게),
# 그 텍스트에서 등록 줄을 찾은 뒤(형식 문자 `"s"` 까지 — 3라운드), **문자열 내용을
# 자리표시자로** 바꿔(문자열 안의 `(`·`assert(` 에 속지 않게) 봅니다:
#   - `error(` 는 **`Common.luau` 의 `raise`/`rethrow` 안에서만**. 새 에러는 `Common.raise`,
#     되던지기는 `Common.rethrow` — `error(msg, 0)` 은 둘의 겉모양이 같아 가릴 수 없었습니다
#     (`error(STRICT_ERROR, 0)` 이 위치 없는 새 에러였음 — 2·3라운드).
#   - `assert(` 금지. `error`/`assert` 를 값으로 쓰기 금지(`local e = error`, `(error)(…)`)
#     — 필드 이름(`x.error`, `x:error`, `{ error = … }`, 타입의 `error: T`)은 제외.
# 경계(제가 정함): 실수로 들어온 위반을 잡는 덫이지 **일부러 피해 가는 코드**(`_G.error`,
# `rawget(_G, "error")`, `getfenv`)를 막는 장치가 아닙니다 — 그건 리뷰의 몫입니다.
if ! bad=$(find src -name "*.luau" -print0 | xargs -0 perl -0777 -ne '
	my $f = $ARGV;
	my $isCommon = $f =~ m{(^|/)Common\.luau\z};
	# 문자열 문법: 이스케이프(\z 뒤 공백·개행 포함), 보간 안의 {…} 는 안쪽 문자열까지 재귀
	my $esc = qr/\\z\s*|\\./s;
	my $dq = qr/"(?:$esc|[^"\\\n])*"/;
	my $sq = qr/\x27(?:$esc|[^\x27\\\n])*\x27/;
	# 보간의 {…} 는 깊이 제한 없이 재귀(표 생성자·안쪽 문자열 포함), 리터럴 부분에 개행 없음
	# — 하나를 잘못 읽으면 닫는 백틱이 새 문자열의 시작이 돼 파일 대부분이 검사에서
	# 빠졌습니다(4라운드). 아래 "남은 따옴표" 덫이 그런 어긋남을 실패로 바꿉니다.
	my $long = qr/\[(=*)\[.*?\]\g{-1}\]/s;
	my ($bt, $br);
	$br = qr/\{(?:$dq|$sq|(??{$bt})|$long|[^{}"\x27`]|(??{$br}))*\}/;
	$bt = qr/`(?:$esc|[^`\\{\n]|(??{$br}))*`/;
	# 1) 주석 제거(문자열은 그대로)
	s{ ($dq|$sq|$bt) | --(?:\[(=*)\[.*?\]\2\]|[^\n]*) | ($long) }
	 { defined $1 ? $1 : defined $3 ? $3 : "" }gsex;
	print "$f: registerSource 를 안 부름\n"
		unless $isCommon || $f =~ m{\Asrc/(Types|init)\.luau\z}
		|| /^Common\.registerSource\(debug\.info\(1, "s"\)\)[ \t]*$/m;
	# 2) 문자열 내용을 자리표시자로. 보간 문자열의 {…} 표현식은 **꺼내서 뒤에 붙여** 같은
	#    검사를 받게 합니다 — 통째로 "S" 로 바꾸면 `{if ok then v else error("x")}` 가
	#    사라졌습니다(5라운드). 표현식 안의 문자열도 같은 규칙으로(재귀).
	my @exprs;
	my $placeholder = sub {
		my ($m) = @_;
		if (defined $m && substr($m, 0, 1) eq "`") {
			my $body = substr($m, 1, -1);
			while ($body =~ /\G(?:$esc|[^`\\{\n]|($br))/gc) {
				push @exprs, substr($1, 1, -1) if defined $1;
			}
		}
		return "\"S\"";
	};
	my $strip = sub {
		my ($t) = @_;
		@exprs = ();
		$t =~ s{ ($dq|$sq|$bt) | ($long) }{ $placeholder->($1) }gsex;
		return ($t, @exprs);
	};
	my ($text, @pending) = $strip->($_);
	while (@pending) {
		my ($t, @more) = $strip->(shift @pending);
		$text .= "\n$t";
		push @pending, @more;
	}
	$_ = $text;
	print "$f: 문자열을 못 읽음(남은 따옴표) — 게이트의 문자열 문법을 고칠 것\n"
		if (my $q = $_) =~ s/"S"//gr =~ /["`\x27]/;
	my @calls;
	push @calls, $1 while /(?<![.:\w])error\s*(\((?:[^()]++|(?1))*\))/g;
	if ($isCommon) {
		my %ok = ("(message, level)" => 1, "(message, 0)" => 1, "(value, 0)" => 1);
		print "$f: error$_ — raise/rethrow 밖\n" for grep { !$ok{$_}-- } @calls;
	} else {
		print "$f: error$_ — Common.raise/rethrow 를 쓸 것\n" for @calls;
	}
	# 되던지기는 받은 에러를 다시 던지는 자리에만 — 이름이 맞게 쓰였는지 볼 수 없어(새 에러를
	# `Common.rethrow("X: …")` 로 내면 위치가 안 붙음, 6라운드) **허용 파일**로 가둡니다.
	# 지금은 Fut 뿐입니다. 새 되던지기 자리가 생기면 이 목록에 더하고 리뷰를 받으세요.
	print "$f: Common.rethrow 는 허용 파일(Fut)에서만 — 새 에러는 Common.raise\n"
		if $f !~ m{\Asrc/Fut\.luau\z} && /(?<![.:\w])Common\.rethrow\s*\(/;
	print "$f: assert( 금지\n" while /(?<![.:\w])assert\s*\(/g;
	print "$f: error/assert 를 값으로 씀\n"
		while /(?<![.:\w])(?:error|assert)\b(?!\s*\()(?!\s*=(?!=))(?!\s*:(?!:))/g;
' 2>&1) || [ -n "$bad" ]; then
	echo "  FAIL  에러 규약 위반"
	printf '        %s\n' "$bad"
	err_fail=1
fi
if [ "$err_fail" = "0" ]; then echo "  에러 규약 OK"; else fail=1; fi

echo
echo "=== 포맷 (stylua)"
if command -v stylua >/dev/null 2>&1; then
	if stylua --check src tests >/dev/null 2>&1; then
		echo "  포맷 OK"
	else
		echo "  FAIL  포맷이 어긋납니다. \`stylua src tests\` 로 맞추세요:"
		stylua --check src tests 2>&1 | grep '^Diff in' | sed 's/^/        /'
		fail=1
	fi
else
	echo "  건너뜀 — stylua 가 PATH 에 없습니다 (mise.toml 에 고정돼 있습니다)"
fi

echo
echo "=== luau tests/run.luau"
luau tests/run.luau || fail=1

# -O2 는 로컬 함수를 인라인해 프레임 수가 바뀝니다 — 에러가 "사용자 줄" 을
# 가리키는지가 최적화 수준에 따라 갈렸습니다(2026-10-02, quad 탐사 C). 라이브
# Roblox 는 -O2 가 기본이라 같은 테스트를 그 수준으로도 돌립니다.
echo
echo "=== luau -O2 tests/run.luau"
luau -O2 tests/run.luau >/dev/null || fail=1

exit "$fail"
