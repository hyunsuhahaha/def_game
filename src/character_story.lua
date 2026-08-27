-- 캐릭터 도입부 스토리 데이터. 실제 서사는 작가(사용자)가 직접 채워 넣는다 — 여기서는
-- 스토리 뷰어가 동작할 수 있는 자리만 마련해둔다. pages가 비어 있으면 뷰어는 "스토리
-- 준비 중" 한 페이지만 보여주고 정상적으로 넘어간다(강제 표시/다시보기 흐름이 깨지지 않게).
local Story = {}

-- pages 형식: {{text = "..."}, {text = "..."}, ...} — 페이지 하나가 화면 한 장.
Story.byJob = {
    physical = {title = "생계형 나무꾼", pages = {}},
    fire = {title = "흡연자", pages = {}},
    toxic = {title = "비건 단체 회장", pages = {}},
    developer = {title = "부동산 개발업자", pages = {}},
    miner = {title = "코인 채굴꾼", pages = {}},
    philosopher = {title = "차라투스트라는 이렇게 말했다", pages = {}},
}

function Story.pagesFor(jobId)
    local entry = Story.byJob[jobId]
    if not entry or #entry.pages == 0 then
        return {{text = "(스토리 준비 중)"}}
    end
    return entry.pages
end

function Story.titleFor(jobId)
    local entry = Story.byJob[jobId]
    return entry and entry.title or jobId
end

return Story
