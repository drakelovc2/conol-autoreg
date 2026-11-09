#!/usr/bin/env bash
# conol-autoreg — запуск регистратора.
#   bash start.sh --count 1 --provider catchall --free-captcha
#   bash start.sh --count 10 --free-captcha --no-proxy
#
# Скрипт сам поднимает Xvfb (headful Chrome нужен для reCAPTCHA v3) и
# выставляет DISPLAY. Аргументы уходят в conol_register.py.
set -u

cd "$(dirname "$0")" || exit 1
unset PYTHONHOME PYTHONPATH LD_LIBRARY_PATH 2>/dev/null
mkdir -p data

if [ ! -f config.json ]; then
  echo "[!] нет config.json — скопируй config.example.json и заполни:"
  echo "    cp config.example.json config.json"
  exit 1
fi

DISPLAY_NUM="${CONOL_CHROME_DISPLAY:-:99}"

if ! command -v xdpyinfo >/dev/null 2>&1 || ! xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
  XVFB_BIN="$(command -v Xvfb || true)"
  [ -n "$XVFB_BIN" ] || XVFB_BIN="$HOME/.local/bin/Xvfb"
  if [ -x "$XVFB_BIN" ]; then
    echo "[start] поднимаю Xvfb $DISPLAY_NUM"
    setsid nohup "$XVFB_BIN" "$DISPLAY_NUM" -screen 0 1280x900x24 -nolisten tcp \
      >> data/xvfb.log 2>&1 &
    sleep 1
  else
    echo "[start] Xvfb не найден — Chrome пойдёт headless, conol может отбить капчу 403" >&2
  fi
fi

export DISPLAY="$DISPLAY_NUM"
export CONOL_CHROME_DISPLAY="$DISPLAY_NUM"
export CONOL_CHROME_HEADLESS=0

exec env -u PYTHONHOME -u PYTHONPATH -u LD_LIBRARY_PATH \
  python3 -X utf8 conol_register.py "$@"