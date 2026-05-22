function recover-redis --description 'Recover Redis after AOF corruption in Lovable devenv deps'
    set -l deps_dir ~/work/lovable
    set -l redis_state $deps_dir/.devenv/state/redis
    set -l force 0
    if contains -- --force $argv
        set force 1
    end

    if not test -d $redis_state
        echo "no Redis state dir at $redis_state — is devenv deps initialized?"
        return 1
    end

    # Already healthy → bail unless --force.
    if ss -ltn 2>/dev/null | grep -q ':6379 '
        if test $force -eq 0
            echo "Redis is already listening on :6379 — nothing to recover."
            echo "Pass --force to wipe state anyway."
            return 0
        end
        echo "Redis is up but --force was passed; wiping state."
    end

    echo "wiping Redis AOF + RDB state in $redis_state/appendonlydir"
    rm -rf $redis_state/appendonlydir $redis_state/dump.rdb

    pushd $deps_dir >/dev/null
    direnv exec . process-compose process restart redis
    set -l rc $status
    popd >/dev/null

    if test $rc -ne 0
        echo "process-compose restart failed (status $rc) — is devenv deps running?"
        return 1
    end

    echo -n "waiting for Redis to bind :6379"
    for i in (seq 1 20)
        if ss -ltn 2>/dev/null | grep -q ':6379 '
            echo " — up."
            return 0
        end
        echo -n "."
        sleep 0.5
    end
    echo ""
    echo "Redis didn't bind in 10s. Check: cd $deps_dir; direnv exec . process-compose process get redis"
    return 1
end
