# Research-to-Skill 빠른 시작

이 문서는 `icerain-cmd/book-to-skill` 포크의 **Research-to-Skill** 기능을 Codex와 Claude Code에서 바로 사용하는 최소 절차만 정리한다.

## 1. 설치

```bash
git clone https://github.com/icerain-cmd/book-to-skill.git
cd book-to-skill
python -m pip install -e .
research-to-skill --help
```

Windows에서는 `py -m pip install -e .`를 사용할 수 있다.

## 2. 새 프로젝트

```bash
research-to-skill init "My Research" --dir ./my-research
```

공유 R 드라이브 예시:

```bash
research-to-skill init "Mechanocene Research" --dir R:/research/mechanocene
```

WSL에서는 같은 프로젝트가 `/mnt/r/research/mechanocene`처럼 보일 수 있다.

## 3. 세션 시작

항상 아래 순서로 시작한다.

```bash
git status
research-to-skill preflight --project <PROJECT>
research-to-skill lock status --project <PROJECT>
git log -1 --oneline
```

`HANDOFF.md`가 존재하면 먼저 읽는다.

### Codex 시작 프롬프트

```text
이 Research-to-Skill 프로젝트 작업을 시작해.
먼저 HANDOFF.md, git status, preflight, lock status, 최신 git log를 확인해.
canonical research.json을 단일 진실원천으로 취급하고 기존 claim·concept·graph 의미를 임의 변경하지 마.
```

### Claude Code 시작 프롬프트

```text
이 Research-to-Skill 프로젝트를 이어서 작업해.
HANDOFF.md와 현재 git 상태를 먼저 읽고 preflight와 lock status를 실행해.
이전 에이전트의 완료 사항, 미완료 사항, 수정 금지 사항을 보존해.
canonical research.json과 source evidence를 파생 Markdown보다 우선해.
```

## 4. 자료 추가

파일 하나:

```bash
research-to-skill add paper.pdf --project <PROJECT>
```

여러 파일/폴더:

```bash
research-to-skill add ./papers ./notes --project <PROJECT>
```

구조가 복잡한 문서:

```bash
research-to-skill add paper.pdf --project <PROJECT> --mode technical
```

확인:

```bash
research-to-skill status --project <PROJECT>
research-to-skill list --project <PROJECT>
```

동일 내용은 SHA-256 기준으로 중복 처리된다.

## 5. 의미 구조화

```bash
research-to-skill compile --project <PROJECT>
```

중요: `compile` 자체가 LLM을 호출하는 것은 아니다. `compile-plan.json`을 만든다.

Codex 또는 Claude Code에게:

```text
compile-plan.json에 포함된 source만 의미 구조화해.
기존 concept/claim/argument와 먼저 대조하고 중복을 만들지 마.
author / external / mixed provenance를 근거 없이 변경하지 마.
locator와 source evidence를 확인해.
작업 후 validate를 통과시킨 뒤에만 compile --complete를 실행해.
```

완료 절차:

```bash
research-to-skill validate --project <PROJECT>
research-to-skill compile --project <PROJECT> --complete
```

## 6. 조회

```bash
research-to-skill inspect source source-001 --project <PROJECT>
research-to-skill inspect concept <CONCEPT_ID> --project <PROJECT>
research-to-skill inspect claim claim-001 --project <PROJECT>
```

권장 탐색 순서:

```text
concepts → claims → arguments → papers → source text
```

source text는 직접 근거, locator, 충돌 해결이 필요할 때 내려간다.

## 7. derived artifact가 어긋났을 때

`research.json`이 canonical이다.

```bash
research-to-skill sync-artifacts --project <PROJECT>
research-to-skill validate --project <PROJECT>
```

수동으로 파생 Markdown을 진실원천처럼 사용해 canonical data를 역수정하지 않는다.

## 8. Writer Lock

`add`, `remove`, `compile`, `compile --complete`는 writer lock을 자동 사용한다.

상태:

```bash
research-to-skill lock status --project <PROJECT>
```

stale lock을 발견해도 즉시 제거하지 않는다. 다른 PC나 agent가 실제 작업 중인지 확인한 후 아무 writer도 없을 때만:

```bash
research-to-skill lock break --project <PROJECT> --force
```

## 9. 세션 종료와 HANDOFF

```bash
research-to-skill validate --project <PROJECT>
research-to-skill status --project <PROJECT>
research-to-skill lock status --project <PROJECT>
git diff
git status
research-to-skill handoff --project <PROJECT>
```

생성되는 `<PROJECT>/HANDOFF.md`가 다음 에이전트의 시작점이다.

## 10. 핵심 운영 원칙

- 한 시점에 한 writer만 canonical research data를 수정한다.
- `research.json`을 단일 진실원천으로 취급한다.
- `validate` 실패 상태에서 `compile --complete`하지 않는다.
- provenance와 locator를 source evidence 없이 바꾸지 않는다.
- `--cascade` 삭제는 의존 항목까지 제거하므로 backup/commit 후 사용한다.
- 중요한 변경은 `HANDOFF.md`에 완료 사항, 다음 작업, 되돌리면 안 되는 결정을 남긴다.

## 초단기 치트시트

```bash
# 시작
research-to-skill preflight --project <PROJECT>
research-to-skill lock status --project <PROJECT>

# 자료 추가
research-to-skill add <SOURCE> --project <PROJECT>
research-to-skill compile --project <PROJECT>

# 의미 작업 후
research-to-skill validate --project <PROJECT>
research-to-skill compile --project <PROJECT> --complete

# 종료
research-to-skill validate --project <PROJECT>
research-to-skill handoff --project <PROJECT>
```
