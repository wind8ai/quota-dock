#!/bin/sh
# Offline protocol fixture. No credentials or network access.
mode="$1"
[ "$mode" = exit ] && exit 1
while IFS= read -r line; do
    [ "$mode" = timeout ] && continue
    case "$line" in
        *'"id":1'*)
            if [ "$mode" = malformed ]; then printf 'not-json\n'; else
                printf '%s\n' '{"id":1,"result":{"userAgent":"fixture"}}'
            fi ;;
        *'"id":2'*)
            if [ "$mode" = auth ]; then printf '%s\n' '{"id":2,"result":{"account":null}}'; else
                printf '%s\n' '{"id":2,"result":{"account":{"type":"chatgpt","email":"test@example.test","planType":"pro"}}}'
            fi ;;
        *'"id":3'*)
            printf '%s\n' '{"method":"unrelated/notification","params":{}}'
            printf '%s' '{"id":3,"result":{"rateLimitsByLimitId":{"codex":{"primary":'
            printf '%s\n' '{"usedPercent":29,"windowDurationMins":10080,"resetsAt":4102444800}}}}}' ;;
        *'"id":4'*)
            if [ "$mode" = changed ]; then email='other@example.test'; else email='test@example.test'; fi
            printf '{"id":4,"result":{"account":{"type":"chatgpt","email":"%s","planType":"pro"}}}\n' "$email" ;;
    esac
done
