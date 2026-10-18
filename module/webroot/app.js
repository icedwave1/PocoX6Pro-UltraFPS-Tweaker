/**
 * Poco X6 Pro 5G Ultra FPS Tweaker - WebUI Logic
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
const valFps = document.getElementById("valFps");
const valBigCore = document.getElementById("valBigCore");
const valLittleCore = document.getElementById("valLittleCore");
const valMidCore = document.getElementById("valMidCore");
const valGov = document.getElementById("valGov");

const toggleThermal = document.getElementById("toggleThermal");
const toggle120 = document.getElementById("toggle120");
const toggleGpu = document.getElementById("toggleGpu");
const toggleUclamp = document.getElementById("toggleUclamp");
const toggleIo = document.getElementById("toggleIo");
const toggleMicrofreeze = document.getElementById("toggleMicrofreeze");

const saveConfigBtn = document.getElementById("saveConfigBtn");
const boostGameBtn = document.getElementById("boostGameBtn");
const cleanRamBtn = document.getElementById("cleanRamBtn");
const refreshBtn = document.getElementById("refreshBtn");
const clearLogBtn = document.getElementById("clearLogBtn");
const consoleLog = document.getElementById("consoleLog");
const toastEl = document.getElementById("toast");

// Logging helper
function logMessage(msg) {
  const time = new Date().toLocaleTimeString();
  consoleLog.textContent = `[${time}] ${msg}\n` + consoleLog.textContent;
}

// Toast helper
function showToast(message) {
  if (window.ksu && typeof window.ksu.toast === "function") {
    try {
      window.ksu.toast(message);
    } catch (e) {
      // Fallback
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
              cpu_temp: "42",
              battery_temp: "33",
              freq_little: "2200 MHz",
              freq_mid: "3200 MHz",
              freq_big: "3350 MHz",
              governor: "performance",
              refresh_rate: "120.0 Hz",
              last_log: "EXTREME profile running smoothly"
            }),
            stderr: ""
          });
        } else {
          resolve({ errno: 0, stdout: "Command succeeded (Browser Mock)", stderr: "" });
        }
      }, 150);
    });
  }
}

// Fetch live telemetry & status
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
  toggleThermal.checked = data.thermal_bypass == 1;
  toggle120.checked = data.lock_120hz == 1;
  toggleGpu.checked = data.gpu_boost == 1;
  toggleUclamp.checked = data.uclamp_boost == 1;
  toggleIo.checked = data.io_tweaks == 1;
  toggleMicrofreeze.checked = data.microfreeze_killer == 1;

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
  valFps.textContent = data.refresh_rate || "120 Hz";
  valBigCore.textContent = data.freq_big || "--";
  valLittleCore.textContent = data.freq_little || "--";
  valMidCore.textContent = data.freq_mid || "--";
  valGov.textContent = data.governor || "--";

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
  logMessage(`Сохранение параметров (Профиль: ${profileName})...`);

  const enVal = masterToggle.checked ? 1 : 0;
  const thVal = toggleThermal.checked ? 1 : 0;
  const hzVal = toggle120.checked ? 1 : 0;
  const gpuVal = toggleGpu.checked ? 1 : 0;
  const ucVal = toggleUclamp.checked ? 1 : 0;
  const ioVal = toggleIo.checked ? 1 : 0;
  const mfVal = toggleMicrofreeze.checked ? 1 : 0;

  const configContent = `ENABLED=${enVal}\\nPROFILE=${profileName}\\nTHERMAL_BYPASS=${thVal}\\nLOCK_120HZ=${hzVal}\\nGPU_BOOST=${gpuVal}\\nUCLAMP_BOOST=${ucVal}\\nIO_TWEAKS=${ioVal}\\nMICROFREEZE_KILLER=${mfVal}\\n`;

  // Write config
  await execCommand(`echo -e "${configContent}" > ${MODDIR}/config.ini`);

  // Execute engine
  const res = await execCommand(`sh ${MODDIR}/scripts/apply_profile.sh ${profileName}`);
  if (res.errno === 0) {
    logMessage(`Профиль ${profileName.toUpperCase()} успешно активирован!`);
    showToast(`Профиль ${profileName.toUpperCase()} применен!`);
  } else {
    logMessage(`Ошибка применения: ${res.stderr}`);
    showToast("Ошибка применения твиков!");
  }

  await refreshStatus();
}

// Event Listeners
masterToggle.addEventListener("change", async () => {
  isEnabled = masterToggle.checked;
  if (!isEnabled) {
    logMessage("Отключение твикера, переход в Stock...");
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
      toggle120.checked = true;
      toggleGpu.checked = true;
      toggleUclamp.checked = true;
      toggleIo.checked = true;
      toggleMicrofreeze.checked = true;
    } else if (prof === "stock") {
      toggleThermal.checked = false;
      toggle120.checked = false;
      toggleGpu.checked = false;
      toggleUclamp.checked = false;
      toggleIo.checked = false;
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
  logMessage("Поиск и ускорение текущей игры...");
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
    showToast("Память очищена!");
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

// Initialize on page load
window.addEventListener("DOMContentLoaded", () => {
  logMessage("Интерфейс инициализирован. Загрузка статуса...");
  refreshStatus();
});
