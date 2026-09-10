/* ============================================================
   shared.js — MyBahaya Shared Interactions
   ============================================================ */

'use strict';

/* ── Top Settings Menu ── */
function initSettingsMenu() {
  const settingsBtn = document.getElementById('settings-btn');
  const settingsMenu = document.getElementById('settings-menu');
  if (!settingsBtn || !settingsMenu) return;

  settingsBtn.addEventListener('click', (event) => {
    event.stopPropagation();
    const isOpen = settingsMenu.classList.toggle('open');
    settingsBtn.classList.toggle('active', isOpen);
    settingsBtn.setAttribute('aria-expanded', isOpen);
  });

  document.addEventListener('click', (e) => {
    if (!settingsBtn.contains(e.target) && !settingsMenu.contains(e.target)) {
      settingsMenu.classList.remove('open');
      settingsBtn.classList.remove('active');
      settingsBtn.setAttribute('aria-expanded', 'false');
    }
  });

  const logoutBtn = settingsMenu.querySelector('.settings-logout');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      if (confirm('Are you sure you want to log out?')) {
        if (typeof firebase !== 'undefined') {
          firebase.auth().signOut().then(() => {
            window.location.replace('login.html');
          });
        } else {
          window.location.replace('login.html');
        }
      }
    });
  }

  const accountBtn = settingsMenu.querySelector('.settings-account');
  if (accountBtn) {
    accountBtn.addEventListener('click', (event) => {
      event.preventDefault();
      settingsMenu.classList.remove('open');
      settingsBtn.classList.remove('active');
      settingsBtn.setAttribute('aria-expanded', 'false');

      const user = window.currentUser;
      const organization = window.currentUserOrg;
      const modal = document.createElement('div');
      modal.className = 'account-modal-backdrop';
      modal.innerHTML = `
        <section class="account-modal" role="dialog" aria-modal="true" aria-labelledby="account-modal-title">
          <button class="account-modal-close" type="button" aria-label="Close account dialog">&times;</button>
          <h2 id="account-modal-title">Account</h2>
          <div class="account-detail"><span>Email</span><strong>${user?.email || 'Unavailable'}</strong></div>
          <div class="account-detail"><span>Role</span><strong>${window.currentUserRole || 'User'}</strong></div>
          ${organization?.name ? `<div class="account-detail"><span>Organization</span><strong>${organization.name}</strong></div>` : ''}
        </section>`;
      document.body.appendChild(modal);

      const closeModal = () => modal.remove();
      modal.querySelector('.account-modal-close').addEventListener('click', closeModal);
      modal.addEventListener('click', event => { if (event.target === modal) closeModal(); });
    });
  }

  // Sound settings in settings menu
  let soundMenuBtn = settingsMenu.querySelector('.settings-sound');
  if (!soundMenuBtn) {
    soundMenuBtn = document.createElement('button');
    soundMenuBtn.type = 'button';
    soundMenuBtn.className = 'settings-sound';
    soundMenuBtn.setAttribute('role', 'menuitem');
    if (logoutBtn) {
      settingsMenu.insertBefore(soundMenuBtn, logoutBtn);
    } else {
      settingsMenu.appendChild(soundMenuBtn);
    }
  }

  function updateSoundMenuUI() {
    const isMuted = localStorage.getItem('mybahaya_sound_muted') === 'true';
    const repeats = localStorage.getItem('mybahaya_sound_repeats') || '3';
    if (soundMenuBtn) {
      if (isMuted) {
        soundMenuBtn.innerHTML = `<ion-icon name="volume-mute-outline"></ion-icon> Sound: Muted`;
      } else {
        soundMenuBtn.innerHTML = `<ion-icon name="volume-high-outline"></ion-icon> Sound: ${repeats}x Chime`;
      }
    }
    const navBtn = document.getElementById('sound-toggle-btn');
    if (navBtn) {
      navBtn.innerHTML = `<ion-icon name="${isMuted ? 'volume-mute-outline' : 'volume-high-outline'}"></ion-icon>`;
      navBtn.title = isMuted ? 'Alert sound: Muted (Click to enable)' : `Alert sound: Active (${repeats}x chime) (Click to test)`;
    }
  }

  updateSoundMenuUI();

  soundMenuBtn.addEventListener('click', (e) => {
    e.preventDefault();
    if (typeof window.unlockAudio === 'function') window.unlockAudio();
    const isMuted = localStorage.getItem('mybahaya_sound_muted') === 'true';
    let repeats = parseInt(localStorage.getItem('mybahaya_sound_repeats') || '3', 10);

    // Cycle through: 3x -> 2x -> 1x -> Muted -> 3x
    if (isMuted) {
      localStorage.setItem('mybahaya_sound_muted', 'false');
      localStorage.setItem('mybahaya_sound_repeats', '3');
      showToast('🔊 Alert sound enabled (3x chime)', 'success');
      if (typeof window.playAlertSound === 'function') window.playAlertSound(3);
    } else if (repeats === 3) {
      localStorage.setItem('mybahaya_sound_repeats', '2');
      showToast('🔊 Alert sound set to 2x chime', 'info');
      if (typeof window.playAlertSound === 'function') window.playAlertSound(2);
    } else if (repeats === 2) {
      localStorage.setItem('mybahaya_sound_repeats', '1');
      showToast('🔊 Alert sound set to 1x chime', 'info');
      if (typeof window.playAlertSound === 'function') window.playAlertSound(1);
    } else {
      localStorage.setItem('mybahaya_sound_muted', 'true');
      showToast('🔇 Alert sound muted', 'info');
    }
    updateSoundMenuUI();
  });

  // Test Real-Time Alert simulation button in settings menu
  let testSimBtn = settingsMenu.querySelector('.settings-sim-report');
  if (!testSimBtn) {
    testSimBtn = document.createElement('button');
    testSimBtn.type = 'button';
    testSimBtn.className = 'settings-sim-report';
    testSimBtn.setAttribute('role', 'menuitem');
    testSimBtn.innerHTML = `<ion-icon name="notifications-outline"></ion-icon> Test Real-Time Alert`;
    if (logoutBtn) {
      settingsMenu.insertBefore(testSimBtn, logoutBtn);
    } else {
      settingsMenu.appendChild(testSimBtn);
    }
    testSimBtn.addEventListener('click', (e) => {
      e.preventDefault();
      settingsMenu.classList.remove('open');
      settingsBtn.classList.remove('active');
      settingsBtn.setAttribute('aria-expanded', 'false');
      if (typeof window.unlockAudio === 'function') window.unlockAudio();
      showToast('🚨 [TEST] New Assault report received in real time!', 'info', 5000);
      if (typeof window.playAlertSound === 'function') window.playAlertSound(3);
    });
  }

}

/* ── Mark Active Nav Link ── */
function initNav() {
  const currentFile = location.pathname.split('/').pop() || 'home.html';
  document.querySelectorAll('.nav-links a').forEach(link => {
    const href = link.getAttribute('href');
    if (href === currentFile) {
      link.classList.add('active');
    }
  });
}

/* ── Fade-in observer ── */
function initFadeIn() {
  const els = document.querySelectorAll('.fade-in');
  if (!els.length) return;
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.style.visibility = 'visible'; obs.unobserve(e.target); } });
  }, { threshold: 0.1 });
  els.forEach(el => { el.style.visibility = 'hidden'; obs.observe(el); });
}

/* ── Toast Notifications ── */
function showToast(message, type = 'success', duration = 3500) {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    document.body.appendChild(container);
  }

  const icons = { success: 'checkmark-circle-outline', error: 'alert-circle-outline', info: 'information-circle-outline' };
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<ion-icon name="${icons[type] || icons.info}"></ion-icon><span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(8px)';
    toast.style.transition = 'opacity 0.2s, transform 0.2s';
    setTimeout(() => toast.remove(), 220);
  }, duration);
}

// Expose globally so page scripts can call it
window.showToast = showToast;

/* ============================================================
   REAL-TIME ALERT AUDIO MANAGER (Multi-Tier Resilient Player)
   ============================================================ */
let audioCtx = null;
let audioBuffer = null;
let isAudioUnlocked = false;
let isCurrentlyPlaying = false;
let persistentAudioEl = null;

function getAudioContext() {
  if (!audioCtx && (window.AudioContext || window.webkitAudioContext)) {
    const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
    audioCtx = new AudioCtxClass();
  }
  return audioCtx;
}

// Get or create persistent DOM audio element (reused across plays to keep permission blessed)
function getPersistentAudioElement() {
  if (!persistentAudioEl) {
    persistentAudioEl = document.getElementById('mybahaya-persistent-audio');
    if (!persistentAudioEl) {
      persistentAudioEl = document.createElement('audio');
      persistentAudioEl.id = 'mybahaya-persistent-audio';
      persistentAudioEl.src = 'assets/sounds/chime-sounds.mp3';
      persistentAudioEl.preload = 'auto';
      persistentAudioEl.style.display = 'none';
      document.body.appendChild(persistentAudioEl);
    }
  }
  return persistentAudioEl;
}

// Safely decode audio data supporting both Promise & callback signatures
function decodeAudioDataSafe(ctx, arrayBuffer) {
  return new Promise((resolve, reject) => {
    try {
      const copy = arrayBuffer.slice(0);
      const res = ctx.decodeAudioData(copy, (decoded) => {
        resolve(decoded);
      }, (err) => {
        reject(err);
      });
      if (res && typeof res.then === 'function') {
        res.then(resolve).catch(reject);
      }
    } catch (err) {
      reject(err);
    }
  });
}

// Preload audio buffer and persistent audio element
async function preloadAlertAudio() {
  const el = getPersistentAudioElement();
  if (el) el.load();

  try {
    const ctx = getAudioContext();
    if (!ctx) return;
    const response = await fetch('assets/sounds/chime-sounds.mp3');
    if (!response.ok) return;
    const arrayBuffer = await response.arrayBuffer();
    audioBuffer = await decodeAudioDataSafe(ctx, arrayBuffer);
    console.log('[MyBahaya Audio] Audio buffer preloaded successfully');
  } catch (err) {
    console.warn('[MyBahaya Audio] Buffer preload failed, DOM audio will be used:', err);
  }
}

// Unlock audio on first user gesture anywhere
async function unlockAudio() {
  const ctx = getAudioContext();
  if (ctx && ctx.state !== 'running') {
    try {
      await ctx.resume();
    } catch (e) {}
  }

  // Also bless the persistent DOM audio element with a silent warm-up
  const el = getPersistentAudioElement();
  if (el) {
    try {
      const origVol = el.volume;
      el.volume = 0.001;
      const p = el.play();
      if (p !== undefined) {
        p.then(() => {
          el.pause();
          el.currentTime = 0;
          el.volume = origVol || 1.0;
        }).catch(() => {});
      }
    } catch (_) {}
  }

  isAudioUnlocked = true;
  hideUnlockBanner();
}

// Register unlock on any user gestures
['click', 'keydown', 'touchstart', 'pointerdown'].forEach(event => {
  document.addEventListener(event, () => unlockAudio(), { capture: true });
});

// Synthesizer emergency chime using Web Audio oscillators (guaranteed zero external dependencies)
function playSynthBeep() {
  return new Promise(async resolve => {
    try {
      const ctx = getAudioContext();
      if (!ctx) return resolve();
      if (ctx.state !== 'running') {
        try { await ctx.resume(); } catch (_) {}
      }

      const now = ctx.currentTime;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, now); // A5 note
      osc.frequency.exponentialRampToValueAtTime(1174.66, now + 0.15); // D6 note

      gain.gain.setValueAtTime(0.5, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.55);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.55);

      setTimeout(resolve, 550);
    } catch (_) {
      resolve();
    }
  });
}

// Show visual unlock banner if autoplay is blocked or before initial interaction
function showAutoplayNotice(isBlockedAlert = false) {
  let banner = document.getElementById('mybahaya-audio-unlock-banner');
  if (!banner) {
    banner = document.createElement('div');
    banner.id = 'mybahaya-audio-unlock-banner';
    banner.className = 'audio-unlock-banner';
    banner.innerHTML = `
      <div class="audio-unlock-content">
        <ion-icon name="volume-high-outline"></ion-icon>
        <span><strong>Real-time Alert:</strong> Click here to enable audio alerts</span>
        <button type="button" class="btn-unlock-audio">Enable Sound</button>
      </div>`;
    banner.addEventListener('click', async () => {
      await unlockAudio();
      playAlertSound(1);
      showToast('🔊 Real-time audio alerts are now active!', 'success');
    });
    document.body.appendChild(banner);
  }
  banner.classList.add('visible');
  if (isBlockedAlert) {
    banner.classList.add('alert-pulse');
  }
}

function hideUnlockBanner() {
  const banner = document.getElementById('mybahaya-audio-unlock-banner');
  if (banner) {
    banner.classList.remove('visible', 'alert-pulse');
  }
}

// Play a single chime with 3 fallback tiers
async function playSingleChime() {
  const ctx = getAudioContext();

  // Tier 1: Web Audio Buffer Source (zero lag, volume amplified)
  if (ctx) {
    if (ctx.state === 'suspended') {
      try { await ctx.resume(); } catch (_) {}
    }
    if (ctx.state === 'running' && audioBuffer) {
      return new Promise(resolve => {
        try {
          const source = ctx.createBufferSource();
          source.buffer = audioBuffer;
          const gainNode = ctx.createGain();
          gainNode.gain.value = 1.5;
          source.connect(gainNode);
          gainNode.connect(ctx.destination);
          source.onended = () => resolve();
          source.start(0);
          setTimeout(resolve, 2000);
          return;
        } catch (err) {
          console.warn('[MyBahaya Audio] WebAudio buffer play error:', err);
        }
      });
    }
  }

  // Tier 2: Persistent Blessed DOM Audio Element
  const el = getPersistentAudioElement();
  if (el) {
    try {
      el.currentTime = 0;
      el.volume = 1.0;
      const playPromise = el.play();
      if (playPromise !== undefined) {
        await playPromise;
        return new Promise(resolve => {
          el.onended = () => resolve();
          setTimeout(resolve, 1800);
        });
      }
    } catch (err) {
      console.warn('[MyBahaya Audio] DOM audio play blocked by browser:', err);
    }
  }

  // Tier 3: Web Audio Oscillator Synthesizer
  if (ctx) {
    if (ctx.state === 'suspended') {
      try { await ctx.resume(); } catch (_) {}
    }
    if (ctx.state === 'running') {
      return playSynthBeep();
    }
  }

  // If all failed because browser blocked autoplay (no gesture yet):
  showAutoplayNotice(true);
}

/**
 * Play alert sound repeating `times` times (defaults to saved setting or 3)
 */
async function playAlertSound(times) {
  const isMuted = localStorage.getItem('mybahaya_sound_muted') === 'true';
  if (isMuted) {
    console.log('[MyBahaya Audio] Sound is muted in settings, skipping.');
    return;
  }

  let count = typeof times === 'number' ? times : parseInt(localStorage.getItem('mybahaya_sound_repeats') || '3', 10);
  if (isNaN(count) || count < 1) count = 3;

  if (isCurrentlyPlaying) return;
  isCurrentlyPlaying = true;

  console.log(`[MyBahaya Audio] 🔔 Playing alert sound ${count}x...`);

  const btn = document.getElementById('sound-toggle-btn');
  if (btn) btn.classList.add('playing');

  try {
    for (let i = 0; i < count; i++) {
      if (localStorage.getItem('mybahaya_sound_muted') === 'true') break;
      await playSingleChime();
      if (i < count - 1) {
        await new Promise(r => setTimeout(r, 220)); // Pause between chimes
      }
    }
  } catch (e) {
    console.error('[MyBahaya Audio] Error during playback loop:', e);
  } finally {
    isCurrentlyPlaying = false;
    if (btn) btn.classList.remove('playing');
  }
}

function initSoundNavButton() {
  const navRight = document.querySelector('.navbar-right');
  if (!navRight || document.getElementById('sound-toggle-btn')) return;

  const btn = document.createElement('button');
  btn.id = 'sound-toggle-btn';
  btn.className = 'avatar-btn sound-toggle-btn';
  btn.type = 'button';
  btn.setAttribute('aria-label', 'Alert sound test and toggle');

  const isMuted = localStorage.getItem('mybahaya_sound_muted') === 'true';
  const repeats = localStorage.getItem('mybahaya_sound_repeats') || '3';
  btn.title = isMuted ? 'Alert sound: Muted (Click to enable)' : `Alert sound: Active (${repeats}x chime) (Click to test)`;
  btn.innerHTML = `<ion-icon name="${isMuted ? 'volume-mute-outline' : 'volume-high-outline'}"></ion-icon>`;

  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    unlockAudio();
    const currentlyMuted = localStorage.getItem('mybahaya_sound_muted') === 'true';
    if (currentlyMuted) {
      localStorage.setItem('mybahaya_sound_muted', 'false');
      showToast('🔊 Alert sound enabled', 'success');
      btn.innerHTML = `<ion-icon name="volume-high-outline"></ion-icon>`;
      playAlertSound(3);
    } else {
      const rep = parseInt(localStorage.getItem('mybahaya_sound_repeats') || '3', 10);
      showToast(`🔔 Testing alert sound (${rep}x chime)`, 'info');
      playAlertSound(rep);
    }
  });

  navRight.insertBefore(btn, navRight.firstChild);
}

// Expose globally
window.playAlertSound = playAlertSound;
window.unlockAudio = unlockAudio;

/* ── Init on DOM ready ── */
document.addEventListener('DOMContentLoaded', () => {
  initSettingsMenu();
  initNav();
  initFadeIn();
  initSoundNavButton();
  preloadAlertAudio();

  // If user has not interacted yet, show subtle unlock banner
  setTimeout(() => {
    if (!isAudioUnlocked && !(navigator.userActivation && navigator.userActivation.hasBeenActive)) {
      showAutoplayNotice(false);
    }
  }, 1000);
});


// Unopened reports tracker
const OPENED_REPORTS_KEY = 'mybahaya_opened_reports';

/**
 * 1. Reads the list of opened report IDs from localStorage.
 * Using a Set gives us O(1) lookup time when checking reports.
 */
function getOpenedReportIds() {
  try {
    const raw = localStorage.getItem(OPENED_REPORTS_KEY);
    return new Set(raw ? JSON.parse(raw) : []);
  } catch (e) {
    return new Set();
  }
}

/**
 * 2. Checks if a specific report ID has already been opened.
 */
function isReportOpened(reportId) {
  if (!reportId) return true;
  return getOpenedReportIds().has(String(reportId));
}

/**
 * 3. Marks a report ID as opened in localStorage and updates the badge.
 */
function markReportAsOpened(reportId, currentReportsList) {
  if (!reportId) return;
  const opened = getOpenedReportIds();
  const idStr = String(reportId);
  if (!opened.has(idStr)) {
    opened.add(idStr);
    try {
      localStorage.setItem(OPENED_REPORTS_KEY, JSON.stringify([...opened]));
    } catch (e) {
      console.warn('Failed to save opened reports to localStorage:', e);
    }
    // Instantly update the counter in the navbar
    updateNavbarReportsBadge(currentReportsList);
  }
}

/**
 * 4. Marks all given reports as opened.
 */
function markAllReportsAsOpened(reportsList) {
  const list = reportsList || window.allReports || [];
  const opened = getOpenedReportIds();
  list.forEach(r => {
    const id = r.id || r.reportId;
    if (id) opened.add(String(id));
  });
  try {
    localStorage.setItem(OPENED_REPORTS_KEY, JSON.stringify([...opened]));
  } catch (e) {
    console.warn('Failed to save opened reports to localStorage:', e);
  }
  updateNavbarReportsBadge(list);
}

/**
 * 5. Calculates how many reports are unopened and renders
 *    the red badge on the navbar "Reports" link and browser title.
 */
function updateNavbarReportsBadge(reportsList) {
  const reportsNavLinks = document.querySelectorAll('.nav-links a[href*="report.html"]');
  if (!reportsNavLinks.length) return;

  const opened = getOpenedReportIds();
  const list = reportsList || window.allReports || [];
  
  // Count how many reports are NOT in the opened Set
  const unopenedCount = list.filter(r => !opened.has(String(r.id || r.reportId))).length;

  reportsNavLinks.forEach(link => {
    let badge = link.querySelector('.nav-badge');
    if (!badge) {
      badge = document.createElement('span');
      badge.className = 'nav-badge';
      link.appendChild(badge);
    }

    if (unopenedCount > 0) {
      badge.textContent = unopenedCount > 99 ? '99+' : unopenedCount;
      badge.classList.remove('hidden');
    } else {
      badge.classList.add('hidden');
    }
  });

  // Also update browser tab title: e.g. "(3) MyBahaya - Reports"
  const baseTitle = document.title.replace(/^\(\d+\+?\)\s*/, '');
  if (unopenedCount > 0) {
    document.title = `(${unopenedCount > 99 ? '99+' : unopenedCount}) ${baseTitle}`;
  } else {
    document.title = baseTitle;
  }
}

// Expose helpers globally so page scripts can call them
window.getOpenedReportIds = getOpenedReportIds;
window.isReportOpened = isReportOpened;
window.markReportAsOpened = markReportAsOpened;
window.markAllReportsAsOpened = markAllReportsAsOpened;
window.updateNavbarReportsBadge = updateNavbarReportsBadge;
