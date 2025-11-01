function piantor_monitor --description "Manage Piantor USB auto-detection"
    set -l cmd $argv[1]
    
    switch $cmd
        case start
            echo "🚀 Starting Piantor USB monitor..."
            launchctl load ~/Library/LaunchAgents/com.piantor.usb.monitor.plist 2>/dev/null
            if test $status -eq 0
                echo "✅ Monitor started - Kanata will auto-restart when Piantor is plugged in"
                echo "📝 Logs: tail -f /tmp/piantor-monitor.log"
            else
                echo "Monitor may already be running. Check status with: piantor_monitor status"
            end
            
        case stop
            echo "🛑 Stopping Piantor USB monitor..."
            launchctl unload ~/Library/LaunchAgents/com.piantor.usb.monitor.plist 2>/dev/null
            echo "Monitor stopped"
            
        case restart
            echo "🔄 Restarting Piantor USB monitor..."
            launchctl unload ~/Library/LaunchAgents/com.piantor.usb.monitor.plist 2>/dev/null
            sleep 1
            launchctl load ~/Library/LaunchAgents/com.piantor.usb.monitor.plist 2>/dev/null
            echo "✅ Monitor restarted"
            
        case status
            if launchctl list | grep -q com.piantor.usb.monitor
                echo "✅ Piantor USB monitor is RUNNING"
                echo "📝 Recent activity:"
                tail -5 /tmp/piantor-monitor.log 2>/dev/null || echo "No logs yet"
            else
                echo "❌ Piantor USB monitor is NOT running"
                echo "Start with: piantor_monitor start"
            end
            
        case logs
            echo "📝 Piantor USB monitor logs (Ctrl+C to exit):"
            tail -f /tmp/piantor-monitor.log
            
        case test
            echo "🧪 Testing Piantor detection..."
            echo "Unplug and replug your Piantor to test"
            tail -f /tmp/piantor-monitor.log | while read line
                echo $line
                if echo $line | grep -q "Kanata restarted"
                    echo "✅ Test successful! Monitor is working"
                    break
                end
            end
            
        case '*'
            echo "Usage: piantor_monitor [start|stop|restart|status|logs|test]"
            echo ""
            echo "Commands:"
            echo "  start   - Start the USB monitor daemon"
            echo "  stop    - Stop the USB monitor daemon"
            echo "  restart - Restart the USB monitor daemon"
            echo "  status  - Check if monitor is running"
            echo "  logs    - Watch the monitor logs"
            echo "  test    - Test by unplugging/replugging Piantor"
    end
end