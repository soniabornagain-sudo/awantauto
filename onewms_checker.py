import asyncio
import os
import re
import requests
from datetime import datetime
from typing import Optional
from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeoutError
from dotenv import load_dotenv

load_dotenv()

LOGIN_URL = "https://onewms.co.kr/login"
ACCOUNT   = os.getenv("ONEWMS_ACCOUNT", "awant")
USERNAME  = os.getenv("ONEWMS_USERNAME", "soykim314")
PASSWORD  = os.getenv("ONEWMS_PASSWORD", "soykim314")

ENV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")


def _get_token() -> str:
    load_dotenv(override=True)
    return os.getenv("KAKAO_ACCESS_TOKEN", "")


def _refresh_access_token() -> Optional[str]:
    """refresh_token으로 새 access_token을 발급받고 .env를 업데이트한다."""
    refresh_token  = os.getenv("KAKAO_REFRESH_TOKEN", "")
    rest_api_key   = os.getenv("KAKAO_REST_API_KEY", "")
    client_secret  = os.getenv("KAKAO_CLIENT_SECRET", "")

    if not (refresh_token and rest_api_key):
        print("[ERROR] KAKAO_REFRESH_TOKEN 또는 KAKAO_REST_API_KEY가 없습니다.")
        return None

    payload = {
        "grant_type":    "refresh_token",
        "client_id":     rest_api_key,
        "refresh_token": refresh_token,
    }
    if client_secret:
        payload["client_secret"] = client_secret

    try:
        resp = requests.post(
            "https://kauth.kakao.com/oauth/token",
            data=payload, timeout=10
        )
        data = resp.json()
        if "access_token" not in data:
            print(f"[ERROR] 토큰 갱신 실패: {data}")
            return None

        new_access  = data["access_token"]
        new_refresh = data.get("refresh_token", refresh_token)  # 새 refresh_token이 오면 교체

        # .env 파일 업데이트
        with open(ENV_PATH, "r") as f:
            env_text = f.read()

        env_text = re.sub(r"KAKAO_ACCESS_TOKEN=.*", f"KAKAO_ACCESS_TOKEN={new_access}", env_text)
        env_text = re.sub(r"KAKAO_REFRESH_TOKEN=.*", f"KAKAO_REFRESH_TOKEN={new_refresh}", env_text)

        with open(ENV_PATH, "w") as f:
            f.write(env_text)

        # 현재 프로세스 환경변수도 갱신
        os.environ["KAKAO_ACCESS_TOKEN"]  = new_access
        os.environ["KAKAO_REFRESH_TOKEN"] = new_refresh
        print("[OK] 카카오 액세스 토큰 자동 갱신 완료")
        return new_access

    except Exception as e:
        print(f"[ERROR] 토큰 갱신 요청 예외: {e}")
        return None


def send_kakao_message(message: str) -> bool:
    token = _get_token()
    if not token:
        print("[ERROR] KAKAO_ACCESS_TOKEN이 설정되지 않았습니다.")
        return False

    def _post(access_token: str):
        return requests.post(
            "https://kapi.kakao.com/v2/api/talk/memo/default/send",
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/x-www-form-urlencoded",
            },
            data={
                "template_object": (
                    f'{{"object_type":"text","text":"{message}",'
                    f'"link":{{"web_url":"https://onewms.co.kr",'
                    f'"mobile_web_url":"https://onewms.co.kr"}}}}'
                )
            },
            timeout=10,
        )

    try:
        resp = _post(token)
        data = resp.json()

        # 401 → 토큰 만료 → refresh 후 재시도
        if resp.status_code == 401 or data.get("code") == -401:
            print("[WARN] 액세스 토큰 만료 – 자동 갱신 시도...")
            new_token = _refresh_access_token()
            if not new_token:
                return False
            resp = _post(new_token)
            data = resp.json()

        if resp.status_code == 200 and data.get("result_code") == 0:
            print(f"[OK] 카카오톡 전송 성공: {message}")
            return True
        else:
            print(f"[ERROR] 카카오톡 전송 실패: {resp.status_code} {data}")
            return False

    except Exception as e:
        print(f"[ERROR] 카카오톡 요청 예외: {e}")
        return False


async def run():
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{now}] OneWMS 발주 자동화 시작")

    completed = False

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        )
        page = await context.new_page()

        # 브라우저 기본 alert/confirm 다이얼로그 자동 수락 (확인 버튼)
        page.on("dialog", lambda d: asyncio.ensure_future(d.accept()))

        # ── 1. 로그인 ────────────────────────────────────────────────
        print("[1] 로그인 중...")
        await page.goto(LOGIN_URL, wait_until="networkidle", timeout=30000)

        account_sel = "input[name='account'], input[placeholder*='계정'], input[placeholder*='회사']"
        try:
            await page.wait_for_selector(account_sel, timeout=5000)
            await page.fill(account_sel, ACCOUNT)
        except PlaywrightTimeoutError:
            print("[WARN] 계정 필드를 찾지 못했습니다 – 건너뜁니다.")

        await page.fill("input[name='userId'], input[placeholder*='아이디']", USERNAME)
        await page.fill("input[name='password'], input[type='password']", PASSWORD)
        await page.click("button[type='submit'], input[type='submit'], button:has-text('로그인')")
        await page.wait_for_load_state("networkidle", timeout=20000)
        print("[1] 로그인 완료")

        # ── 2. 주문배송관리 → 발주 ──────────────────────────────────
        print("[2] 주문배송관리 → 발주 클릭 중...")
        await page.click("text=주문배송관리")
        await page.wait_for_timeout(800)
        balju_link = page.locator("a[class*='depth-8']").filter(
            has_text=re.compile(r'^발주$')
        ).first
        await balju_link.wait_for(state="visible", timeout=10000)
        await balju_link.click()
        await page.wait_for_load_state("networkidle", timeout=20000)
        print("[2] 발주 페이지 이동 완료")

        # ── 3. 다음 버튼 3번 클릭 (20초 간격) ───────────────────────
        print("[3] 다음 버튼 3회 클릭 중...")
        next_btn = page.locator("button.btn-primary").filter(
            has_text=re.compile(r'^다')
        ).first

        for i in range(1, 4):
            await next_btn.wait_for(state="visible", timeout=10000)
            await next_btn.click()
            print(f"    다음 클릭 {i}/3 – 20초 대기 중...")
            await page.wait_for_timeout(20000)

        print("[3] 다음 버튼 3회 완료")

        # ── 4. '발주가 완료되었습니다.' 팝업 처리 ───────────────────
        print("[4] 완료 팝업 대기 중...")

        # Bootstrap 모달 방식: 텍스트에 '완료' 포함된 모달의 확인 버튼
        try:
            confirm_btn = page.locator(
                ".modal.show button"
            ).filter(has_text=re.compile(r'^확인$'))
            await confirm_btn.wait_for(state="visible", timeout=15000)
            await confirm_btn.click()
            print("[4] 모달 확인 버튼 클릭 완료")
            completed = True
        except PlaywrightTimeoutError:
            # 브라우저 기본 alert이었다면 이미 page.on("dialog")로 처리됨
            print("[4] 모달 없음 – 브라우저 다이얼로그로 처리됨")
            completed = True

        await browser.close()

    # ── 5. 카카오톡 알림 ─────────────────────────────────────────────
    if completed:
        send_kakao_message("발주 완료되었습니다 ✅")


if __name__ == "__main__":
    asyncio.run(run())
