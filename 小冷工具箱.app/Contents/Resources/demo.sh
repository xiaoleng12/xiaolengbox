#!/bin/zsh
# ============================================
#  小冷工具箱 - 示例脚本
#  XiaoLengBox Demo Script
# ============================================
#  这是一个演示脚本，展示如何通过工具箱快速启动常用操作。
#  你可以编辑此脚本，添加自己的常用命令。
# ============================================

echo "🧰 小冷工具箱 - 系统快查"
echo "========================"
echo ""

# 1. 系统信息
echo "📌 系统信息"
echo "  主机名: $(hostname)"
echo "  macOS:  $(sw_vers -productVersion)"
echo "  芯片:   $(uname -m)"
echo ""

# 2. 磁盘使用
echo "💾 磁盘使用"
df -h / | awk 'NR==2 {print "  已用: "$3" / 总计: "$2" ("$5" 使用率)"}'
echo ""

# 3. 内存使用
echo "🧠 内存"
vm_stat | head -10
echo ""

# 4. 网络信息
echo "🌐 网络"
echo "  本机 IP: $(ipconfig getifaddr en0 2>/dev/null || echo '未连接')"
echo "  DNS:     $(scutil --dns 2>/dev/null | awk '/nameserver\[0\]/{print $3; exit}')"
echo ""

# 5. 常用端口检查
echo "🔍 监听端口 (前10)"
lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | head -11
echo ""

echo "✅ 检查完成！"
