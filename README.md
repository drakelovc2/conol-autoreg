# conol-autoreg

Авторег аккаунтов **Conol** (`conol.ai`) — только регистратор, без API-моста.
Новый аккаунт получает **600 кредитов**; вход через better-auth, подтверждение почты
ссыпкой, капча — reCAPTCHA v3.

> **Почему без моста.** У Conol нет OpenAI-совместимого пула ключей: агент выполняет
> инструменты в собственной VM, а код пишет через GitHub. Проксировать нечего —
> наружу отдаётся не API, а веб-агент. Поэтому здесь только авторег.

## Что даёт аккаунт

- **600 кредитов** на старте.
- Модели на фри-тире: Claude Haiku 5.5, GPT-6 Luna, DeepSeek 4.1 1017,
  MiniMax M3, Qwen 3.8 Max.
- Кодинг через GitHub: агент клонит репозиторий и работает в своей VM.

## Как устроен флоу

1. `POST /api/invites/register` — email, пароль, имя + заголовок `x-captcha-response`
   (reCAPTCHA v3, action `sign_up`). Без токена сервер отдаёт `CAPTCHA_MISSING`.
2. `POST /api/auth/send-verification-email` — тем же session-cookie (better-auth),
   свежий токен капчи (action `send_verification_email`).
3. Письмо со ссылкой `/api/auth/verify-email?token=…&callbackURL=…` читается из
   catch-all через admin API.
4. `GET /api/auth/verify-email` — подтверждение.
5. `POST /api/auth/sign-in/email` — новая капча (action `sign_in`), session-cookie.
6. `GET /api/billing/balance` — проверка баланса (обычно 600).

## Установка

```bash
cp config.example.json config.json   # conol.password, emails.catchall, прокси
pip install -r requirements.txt
python3 -m playwright install chromium
```

Нужен **headful Chrome**: reCAPTCHA v3 из `--headless` Conol отбивает 403.
`start.sh` сам поднимает Xvfb `:99`, если дисплея нет.

## Конфиг

| Блок | Что задаёт |
|---|---|
| `conol` | `base_url`, общий `password` создаваемых аккаунтов, `site_key` reCAPTCHA |
| `emails.catchall` | apimail-совместимый admin API: `api_base`, `admin_key`, `domain` |
| `emails.gmail` | плюс-алиасы одного ящика через IMAP (нужны `address`/`app_password` в `conol_secrets`) |
| `emails.tonline` | готовые ящики `email:password` в файле |
| `captcha` | `chrome_cdp` (бесплатно), `anticaptcha_keys` (платный fallback), `cdp_port`, `display` |
| `proxies` / `proxies_file` / `brd_zones` | пул прокси, ротация по аккаунтам |
| `registration` | префикс имени/почты, задержки, таймаут письма |

`chrome_path` можно оставить пустым — код найдёт Chrome в `PATH` или в
`~/.cache/ms-playwright`.

## Запуск

```bash
# один аккаунт, свой catch-all, бесплатная капча
bash start.sh --count 1 --provider catchall --free-captcha

# серия с прокси из data/proxies.txt
bash start.sh --count 10 --free-captcha

# без прокси (только для отладки: ~2 аккаунта на IP)
bash start.sh --count 1 --free-captcha --no-proxy
```

Флаги:

- `--count N` — сколько аккаунтов;
- `--provider catchall|gmail|tonline` — источник почты;
- `--free-captcha` — только Chrome CDP, без платного AntiCaptcha;
- `--no-proxy` — игнорировать пул;
- `--proxies-file PATH` — свой файл прокси.

## Обновление сессий

```bash
python3 conol_refresh.py --max 3          # обновить 3 аккаунта
python3 conol_refresh.py --max 3 --cdp   # через браузер
```

Токены и cookies складываются в `data/conol_accounts_pool.jsonl` и
`data/cookies_*.json`.

## Грабли (проверено)

- **IP-лимит.** С одного адреса проходят ~2 регистрации, дальше `429 RATE_LIMITED`.
  Для серии нужен пул residential/ISP; DC-IP может отбивать reCAPTCHA v3.
- **Headless нельзя.** Токены из `--headless=new` Conol режет 403; нужен headful
  Chrome на X-дисплее (Xvfb подходит).
- **Vercel Security Checkpoint** на `/sign-up` — на HTTP-регистрацию не влияет,
  но браузеру для капчи нужен прогретый профиль (`data/chrome_cdp_profile`).
- **reCAPTCHA v3 — лотерея по score.** Иногда первый токен отклоняется, реггер
  повторяет с новым токеном (до 3 попыток).
- **Домены почты.** Публичные темпмейлы и часть catch-all в блок-листе Conol;
  рабочий домен проверяйте на одном аккаунте.
- **Пароль общий** для всех созданных аккаунтов — задаётся в `conol.password`;
  меняйте на свой.

## Данные

| Файл | Что внутри |
|---|---|
| `data/conol_accounts_pool.jsonl` | email, password, session_token, credits, cookies_path |
| `data/conol_register_results.jsonl` | результаты прогонов |
| `data/cookies_<name>.json` | cookies better-auth |
| `data/chrome_cdp_profile/` | профиль Chrome для капчи |

Всё в `.gitignore`.

## Ограничения

Только собственные/разрешённые аккаунты. Прокси, почта и пароль — ваши; в репозитории
их нет. Conol — сервис с веб-агентом, а не OpenAI-совместимый API: моста здесь нет
по архитектурным причинам, а не из-за блокировки.

## Лицензия

MIT + условие добросовестного использования — см. [LICENSE](LICENSE).
---

🔥 Telegram: [@antivibedrake](https://t.me/antivibedrake) · [@zakurulife](https://t.me/zakurulife)

Только для личного использования — см. [DISCLAIMER.md](DISCLAIMER.md).
