#!/system/bin/sh
# Flush I/O buffers, Drop caches & Compact Memory for instantaneous stutter fix

echo "[RAM Cleaner] Flushing dirty pages to storage..."
sync

echo "[RAM Cleaner] Dropping pagecache, dentries and inodes..."
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null

echo "[RAM Cleaner] Compacting memory pages..."
echo 1 > /proc/sys/vm/compact_memory 2>/dev/null

echo "Memory cleaned successfully!"
exit 0
