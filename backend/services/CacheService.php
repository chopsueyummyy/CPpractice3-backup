<?php

class CacheService {
    private static $redis = null;
    private static $redisAttempted = false;
    private static $cacheDir = __DIR__ . '/../cache';

    /**
     * Get instance of Redis connection if available
     */
    private static function getRedis() {
        if (self::$redisAttempted) {
            return self::$redis;
        }
        self::$redisAttempted = true;

        if (class_exists('Redis')) {
            try {
                $host = getenv('REDIS_HOST') ?: 'redis';
                $port = (int)(getenv('REDIS_PORT') ?: 6379);
                $r = new Redis();
                if (@$r->connect($host, $port, 1.5)) {
                    self::$redis = $r;
                    return self::$redis;
                }
            } catch (Throwable $e) {
                // Fail silently and fallback to file cache
                self::$redis = null;
            }
        }
        return null;
    }

    /**
     * Ensure local file cache directory exists
     */
    private static function ensureCacheDir() {
        if (!is_dir(self::$cacheDir)) {
            @mkdir(self::$cacheDir, 0755, true);
        }
    }

    /**
     * Get a cached item by key
     */
    public static function get($key) {
        $redis = self::getRedis();
        if ($redis) {
            try {
                $val = $redis->get("riasec:" . $key);
                if ($val !== false) {
                    return json_decode($val, true);
                }
                return null;
            } catch (Throwable $e) {
                // Fallback to file cache
            }
        }

        // File-based fallback
        self::ensureCacheDir();
        $file = self::$cacheDir . '/' . md5($key) . '.json';
        if (file_exists($file)) {
            $data = @json_decode(file_get_contents($file), true);
            if (is_array($data) && isset($data['expires_at'])) {
                if (time() < $data['expires_at']) {
                    return $data['payload'];
                } else {
                    @unlink($file);
                }
            }
        }
        return null;
    }

    /**
     * Store an item in the cache
     */
    public static function set($key, $value, $ttlSeconds = 300) {
        $redis = self::getRedis();
        if ($redis) {
            try {
                return $redis->setex("riasec:" . $key, $ttlSeconds, json_encode($value));
            } catch (Throwable $e) {
                // Fallback to file cache
            }
        }

        // File-based fallback
        self::ensureCacheDir();
        $file = self::$cacheDir . '/' . md5($key) . '.json';
        $data = [
            'expires_at' => time() + $ttlSeconds,
            'payload' => $value
        ];
        return @file_put_contents($file, json_encode($data)) !== false;
    }

    /**
     * Get an item from cache, or execute callback and cache the result
     */
    public static function remember($key, $ttlSeconds, callable $callback) {
        $cached = self::get($key);
        if ($cached !== null) {
            return $cached;
        }

        $fresh = $callback();
        if ($fresh !== null) {
            self::set($key, $fresh, $ttlSeconds);
        }
        return $fresh;
    }

    /**
     * Remove an item from cache
     */
    public static function forget($key) {
        $redis = self::getRedis();
        if ($redis) {
            try {
                $redis->del("riasec:" . $key);
            } catch (Throwable $e) {}
        }

        self::ensureCacheDir();
        $file = self::$cacheDir . '/' . md5($key) . '.json';
        if (file_exists($file)) {
            @unlink($file);
        }
    }

    /**
     * Flush all riasec keys
     */
    public static function flush() {
        $redis = self::getRedis();
        if ($redis) {
            try {
                $keys = $redis->keys("riasec:*");
                if ($keys) {
                    $redis->del($keys);
                }
            } catch (Throwable $e) {}
        }

        self::ensureCacheDir();
        $files = glob(self::$cacheDir . '/*.json');
        if ($files) {
            foreach ($files as $f) {
                @unlink($f);
            }
        }
    }
}
?>
