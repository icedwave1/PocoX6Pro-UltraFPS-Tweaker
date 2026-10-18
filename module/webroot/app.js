/**
 * Poco X6 Pro 5G Ultra FPS Tweaker - WebUI Logic v2.5
 * Designed for KernelSU WebUI Bridge
 */

// Module directory on Android
const MODDIR = "/data/adb/modules/duchamp_tweaker";

// State
let currentProfile = "extreme";
let isEnabled = true;

// DOM Elements
const masterToggle = document.getElementById("masterToggle");
const statusDot = document.getElementById("statusDot");
const statusText = document.getElementById("statusText");
const profileButtons = document.querySelectorAll(".profile-btn");

const valCpuTemp = document.getElementById("valCpuTemp");
const valBatTemp = document.getElementById("valBatTemp");
const valBatCur = document.getElementById("valBatCur");
const valFps = document.getElementById("valFps");
const valGov = document.getElementById("valGov");
const valRam = document.getElementById("valRam");
const valZram = document.getElementById("valZram");
const valTcp = document.getElementById("valTcp");

// 8 Cores
const coreEls = [
  document.getElementById("c0"),
  document.getElementById("c1"),
  document.getElementById("c2"),
  document.getElementById("c3"),
  document.getElementById("c4"),
  document.getElementById("c5"),
  document.getElementById("c6"),
  document.getElementById("c7")
];

// Switches
const toggleThermal = document.getElementById("toggleThermal");
const toggleGpu = document.getElementById("toggleGpu");
const toggleUclamp = document.getElementById("toggleUclamp");
const toggleDram = document.getElementById("toggleDram");
const toggle120 = document.getElementById("toggle120");
const toggleNetwork = document.getElementById("toggleNetwork");
const toggleTouch = document.getElementById("toggleTouch");
const toggleIo = document.getElementById("toggleIo");
const toggleAudio = document.getElementById("toggleAudio");
const toggleMicrofreeze = document.getElementById("toggleMicrofreeze");

// Buttons
const saveConfigBtn = document.getElementById("saveConfigBtn");
const boostGameBtn = document.getElementById("boostGameBtn");
const cleanRamBtn = document.getElementById("cleanRamBtn");
const networkFlushBtn = document.getElementById("networkFlushBtn");
const refreshBtn = document.getElementById("refreshBtn");
const clearLogBtn = document.getElementById("clearLogBtn");
const consoleLog = document.getElementById("consoleLog");
const toastEl = document.getElementById("toast");

function logMessage(msg) {
  const time = new Date().toLocaleTimeString();
  consoleLog.textContent = `[${time}] ${msg}\n` + consoleLog.textContent;
}

function showToast(message) {
  if (window.ksu && typeof window.ksu.toast === "function") {
    try {
      window.ksu.toast(message);
    } catch (e) {
      // Ignore
    }
  }
  toastEl.textContent = message;
  toastEl.classList.add("show");
  setTimeout(() => {
    toastEl.classList.remove("show");
  }, 2500);
}

// KernelSU exec Promise Bridge
function execCommand(cmd) {
  if (window.ksu && typeof window.ksu.exec === "function") {
    return new Promise((resolve) => {
      const cbName = "exec_cb_" + Date.now() + "_" + Math.floor(Math.random() * 10000);
      window[cbName] = (errno, stdout, stderr) => {
        delete window[cbName];
        resolve({ errno, stdout: stdout || "", stderr: stderr || "" });
      };
      try {
        window.ksu.exec(cmd, "{}", cbName);
      } catch (err) {
        delete window[cbName];
        resolve({ errno: -1, stdout: "", stderr: String(err) });
      }
    });
  } else {
    // Development / Browser simulation
    console.warn("[KernelSU Bridge Mock] Executing:", cmd);
    return new Promise((resolve) => {
      setTimeout(() => {
        if (cmd.includes("get_status.sh")) {
          resolve({
            errno: 0,
            stdout: JSON.stringify({
              enabled: 1,
              profile: currentProfile,
              thermal_bypass: 1,
              lock_120hz: 1,
              gpu_boost: 1,
              uclamp_boost: 1,
              io_tweaks: 1,
              microfreeze_killer: 1,
              network_boost: 1,
              touch_boost: 1,
              audio_latency: 1,
              dram_boost: 1,
              cpu_temp: "41",
              battery_temp: "32",
              battery_current: "-420 mA",
              freqs: [2200, 2200, 2200, 2200, 3200, 3200, 3200, 3350],
              governor: "performance",
              refresh_rate: "120.0 Hz",
              tcp_congestion: "bbr",
              mem_total: "11520 MB",
              mem_avail: "7430 MB",
              swap_total: "6144 MB",
              swap_free: "5890 MB",
              last_log: "Poco X6 Pro 5G Ultra FPS Engine v2.5 running smoothly"
            }),
            stderr: ""
          });
        } else {
          resolve({ errno: 0, stdout: "Command succeeded (Browser Mock)", stderr: "" });
        }
      }, 120);
    });
  }
}

async function refreshStatus() {
  const res = await execCommand(`sh ${MODDIR}/scripts/get_status.sh`);
  if (res.errno === 0 && res.stdout) {
    try {
      const data = JSON.parse(res.stdout.trim());
      updateUIFromData(data);
    } catch (e) {
      logMessage("JSON parse error: " + e.message);
    }
  }
}

function updateUIFromData(data) {
  // Master Switch & Profile
  isEnabled = !!data.enabled;
  masterToggle.checked = isEnabled;
  currentProfile = data.profile || "extreme";

  updateStatusBadge();

  // Granular switches
  if (toggleThermal) toggleThermal.checked = data.thermal_bypass == 1;
  if (toggleGpu) toggleGpu.checked = data.gpu_boost == 1;
  if (toggleUclamp) toggleUclamp.checked = data.uclamp_boost == 1;
  if (toggleDram) toggleDram.checked = data.dram_boost == 1;
  if (toggle120) toggle120.checked = data.lock_120hz == 1;
  if (toggleNetwork) toggleNetwork.checked = data.network_boost == 1;
  if (toggleTouch) toggleTouch.checked = data.touch_boost == 1;
  if (toggleIo) toggleIo.checked = data.io_tweaks == 1;
  if (toggleAudio) toggleAudio.checked = data.audio_latency == 1;
  if (toggleMicrofreeze) toggleMicrofreeze.checked = data.microfreeze_killer == 1;

  // Telemetry values
  valCpuTemp.textContent = (data.cpu_temp !== "N/A" ? data.cpu_temp + "°C" : "--");
  if (parseInt(data.cpu_temp) > 65) {
    valCpuTemp.style.color = "var(--danger)";
  } else if (parseInt(data.cpu_temp) > 50) {
    valCpuTemp.style.color = "var(--warning)";
  } else {
    valCpuTemp.style.color = "var(--success)";
  }

  valBatTemp.textContent = (data.battery_temp !== "N/A" ? data.battery_temp + "°C" : "--");
  valBatCur.textContent = data.battery_current || "-- mA";
  valFps.textContent = data.refresh_rate || "120 Hz";
  valGov.textContent = data.governor || "schedutil";
  valRam.textContent = data.mem_avail ? `${data.mem_avail} / ${data.mem_total}` : "--";
  valZram.textContent = data.swap_free ? `${data.swap_free} Free` : "--";
  valTcp.textContent = (data.tcp_congestion || "BBR").toUpperCase();

  // 8 CPU Cores
  if (Array.isArray(data.freqs)) {
    data.freqs.forEach((freq, idx) => {
      if (coreEls[idx]) {
        coreEls[idx].textContent = freq > 0 ? `${freq}` : "--";
      }
    });
  }

  // Active Profile Button
  profileButtons.forEach((btn) => {
    if (btn.dataset.profile === currentProfile) {
      btn.classList.add("active");
    } else {
      btn.classList.remove("active");
    }
  });
}

function updateStatusBadge() {
  if (!isEnabled) {
    statusDot.className = "status-dot";
    statusText.textContent = "ВЫКЛЮЧЕН";
    statusText.style.color = "var(--text-muted)";
  } else {
    statusDot.className = "status-dot active";
    statusText.textContent = currentProfile.toUpperCase();
    statusText.style.color = "var(--accent-cyan)";
  }
}

// Save config to file and apply
async function saveAndApply(profileName = currentProfile) {
  logMessage(`Сохранение конфигурации (Профиль: ${profileName})...`);

  const enVal = masterToggle.checked ? 1 : 0;
  const thVal = toggleThermal.checked ? 1 : 0;
  const gpuVal = toggleGpu.checked ? 1 : 0;
  const ucVal = toggleUclamp.checked ? 1 : 0;
  const dramVal = toggleDram.checked ? 1 : 0;
  const hzVal = toggle120.checked ? 1 : 0;
  const netVal = toggleNetwork.checked ? 1 : 0;
  const touchVal = toggleTouch.checked ? 1 : 0;
  const ioVal = toggleIo.checked ? 1 : 0;
  const audioVal = toggleAudio.checked ? 1 : 0;
  const mfVal = toggleMicrofreeze.checked ? 1 : 0;

  const configContent = `ENABLED=${enVal}\\nPROFILE=${profileName}\\nTHERMAL_BYPASS=${thVal}\\nLOCK_120HZ=${hzVal}\\nGPU_BOOST=${gpuVal}\\nUCLAMP_BOOST=${ucVal}\\nIO_TWEAKS=${ioVal}\\nMICROFREEZE_KILLER=${mfVal}\\nNETWORK_BOOST=${netVal}\\nTOUCH_BOOST=${touchVal}\\nAUDIO_LATENCY=${audioVal}\\nDRAM_BOOST=${dramVal}\\n`;

  // Write config
  await execCommand(`echo -e "${configContent}" > ${MODDIR}/config.ini`);

  // Execute engine
  const res = await execCommand(`sh ${MODDIR}/scripts/apply_profile.sh ${profileName}`);
  if (res.errno === 0) {
    logMessage(`Профиль ${profileName.toUpperCase()} успешно применен!`);
    showToast(`Профиль ${profileName.toUpperCase()} активирован!`);
  } else {
    logMessage(`Ошибка: ${res.stderr || "Неизвестная ошибка"}`);
    showToast("Ошибка применения твиков!");
  }

  await refreshStatus();
}

// Event Listeners
masterToggle.addEventListener("change", async () => {
  isEnabled = masterToggle.checked;
  if (!isEnabled) {
    logMessage("Отключение твикера, возврат к Stock AOSP...");
    await saveAndApply("stock");
  } else {
    logMessage("Включение твикера...");
    await saveAndApply(currentProfile || "extreme");
  }
});

profileButtons.forEach((btn) => {
  btn.addEventListener("click", async () => {
    const prof = btn.dataset.profile;
    currentProfile = prof;
    profileButtons.forEach((b) => b.classList.remove("active"));
    btn.classList.add("active");

    if (prof === "extreme") {
      toggleThermal.checked = true;
      toggleGpu.checked = true;
      toggleUclamp.checked = true;
      toggleDram.checked = true;
      toggle120.checked = true;
      toggleNetwork.checked = true;
      toggleTouch.checked = true;
      toggleIo.checked = true;
      toggleAudio.checked = true;
      toggleMicrofreeze.checked = true;
    } else if (prof === "esports") {
      toggleThermal.checked = true;
      toggleGpu.checked = true;
      toggleUclamp.checked = true;
      toggleDram.checked = true;
      toggle120.checked = true;
      toggleNetwork.checked = true;
      toggleTouch.checked = true;
      toggleIo.checked = true;
      toggleAudio.checked = true;
      toggleMicrofreeze.checked = true;
    } else if (prof === "balanced") {
      toggleThermal.checked = false;
      toggleGpu.checked = true;
      toggleUclamp.checked = true;
      toggleDram.checked = false;
      toggle120.checked = true;
      toggleNetwork.checked = true;
      toggleTouch.checked = true;
      toggleIo.checked = true;
      toggleAudio.checked = false;
      toggleMicrofreeze.checked = false;
    } else if (prof === "battery") {
      toggleThermal.checked = false;
      toggleGpu.checked = false;
      toggleUclamp.checked = false;
      toggleDram.checked = false;
      toggle120.checked = false;
      toggleNetwork.checked = false;
      toggleTouch.checked = false;
      toggleIo.checked = false;
      toggleAudio.checked = false;
      toggleMicrofreeze.checked = false;
    } else if (prof === "stock") {
      toggleThermal.checked = false;
      toggleGpu.checked = false;
      toggleUclamp.checked = false;
      toggleDram.checked = false;
      toggle120.checked = false;
      toggleNetwork.checked = false;
      toggleTouch.checked = false;
      toggleIo.checked = false;
      toggleAudio.checked = false;
      toggleMicrofreeze.checked = false;
    }

    if (!masterToggle.checked) {
      masterToggle.checked = true;
    }

    await saveAndApply(prof);
  });
});

saveConfigBtn.addEventListener("click", async () => {
  await saveAndApply(currentProfile);
});

// Quick Action: Boost focused game
boostGameBtn.addEventListener("click", async () => {
  logMessage("Определение активной игры...");
  const res = await execCommand(`sh ${MODDIR}/scripts/boost_game.sh`);
  if (res.stdout) {
    logMessage(res.stdout.trim());
    showToast("Игра ускорена (PID Realtime)!");
  }
  if (res.stderr) {
    logMessage("Info: " + res.stderr.trim());
  }
});

// Quick Action: Clean RAM
cleanRamBtn.addEventListener("click", async () => {
  logMessage("Сброс кэшей памяти (drop_caches & compact)...");
  const res = await execCommand(`sh ${MODDIR}/scripts/drop_caches.sh`);
  if (res.stdout) {
    logMessage(res.stdout.trim());
    showToast("RAM очищена!");
  }
  await refreshStatus();
});

// Quick Action: Flush DNS & Network
networkFlushBtn.addEventListener("click", async () => {
  logMessage("Сброс сетевых буферов & Lock Wi-Fi Low Latency...");
  const res = await execCommand(`sh ${MODDIR}/scripts/network_flush.sh`);
  if (res.stdout) {
    logMessage(res.stdout.trim());
    showToast("Пинг и сеть оптимизированы!");
  }
  await refreshStatus();
});

refreshBtn.addEventListener("click", () => {
  refreshStatus();
  showToast("Телеметрия обновлена");
});

clearLogBtn.addEventListener("click", () => {
  consoleLog.textContent = "";
});

// Auto-refresh interval (every 3 seconds)
setInterval(refreshStatus, 3000);

window.addEventListener("DOMContentLoaded", () => {
  logMessage("Интерфейс v2.5 инициализирован. Загрузка статуса...");
  refreshStatus();
});
