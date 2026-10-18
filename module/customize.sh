#!/system/bin/sh
# Poco X6 Pro 5G Ultra FPS Tweaker v2.5 - Installer

ui_print "****************************************************"
ui_print "*   Poco X6 Pro 5G (duchamp) Ultra FPS Tweaker    *"
ui_print "*            Hardcore Gaming Edition v2.5          *"
ui_print "*           ROM: Pixel Experience / AOSP           *"
ui_print "*          SoC: MediaTek Dimensity 8300-U          *"
ui_print "****************************************************"

if [ "$ARCH" != "arm64" ]; then
  abort "! Unsupported architecture: $ARCH (Requires ARM64)"
fi

ui_print "- Installing module files..."

# Set permissions
set_perm_recursive "$MODPATH/scripts" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644

# Initialize default configuration if not exists
if [ ! -f "$MODPATH/config.ini" ]; then
  ui_print "- Generating initial v2.5 configuration..."
  cat << 'EOF' > "$MODPATH/config.ini"
ENABLED=1
PROFILE=extreme
THERMAL_BYPASS=1
LOCK_120HZ=1
GPU_BOOST=1
UCLAMP_BOOST=1
IO_TWEAKS=1
MICROFREEZE_KILLER=1
NETWORK_BOOST=1
TOUCH_BOOST=1
AUDIO_LATENCY=1
DRAM_BOOST=1
EOF
  set_perm "$MODPATH/config.ini" 0 0 0644
fi

# Enable hot install support for KernelSU
export MODULE_HOT_INSTALL_REQUEST=true
export MODULE_HOT_RUN_SCRIPT="service.sh"

ui_print "- WebUI and Background Engine ready!"
ui_print "- Open KernelSU Manager -> Modules -> WebUI to configure!"
ui_print "****************************************************"
