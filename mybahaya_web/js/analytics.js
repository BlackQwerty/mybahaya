/* ============================================================
   analytics.js — Analytics Page Logic
   ============================================================ */

'use strict';

function initTrendChart() {
  const ctx = document.getElementById('trendChart');
  if (!ctx) return;

  const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN', 'MON', 'TUE', 'WED'];
  const actualData = [12, 19, 15, 25, 32, 45, 38, null, null, null];
  const projectedData = [null, null, null, null, null, null, 38, 30, 25, 28];

  const gradient = ctx.getContext('2d').createLinearGradient(0, 0, 0, 250);
  gradient.addColorStop(0, 'rgba(240,95,126,0.6)');
  gradient.addColorStop(1, 'rgba(240,95,126,0.0)');

  const gradientProj = ctx.getContext('2d').createLinearGradient(0, 0, 0, 250);
  gradientProj.addColorStop(0, 'rgba(255,255,255,0.1)');
  gradientProj.addColorStop(1, 'rgba(255,255,255,0.0)');

  new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [
        {
          label: 'Actual',
          data: actualData,
          backgroundColor: gradient,
          borderColor: 'rgba(240,95,126,0.8)',
          borderWidth: { top: 2, right: 0, bottom: 0, left: 0 },
          borderRadius: 4
        },
        {
          label: 'Projected',
          data: projectedData,
          backgroundColor: gradientProj,
          borderColor: 'rgba(255,255,255,0.2)',
          borderWidth: { top: 2, right: 0, bottom: 0, left: 0 },
          borderDash: [4, 4],
          borderRadius: 4
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: 'rgba(15,15,26,0.95)',
          borderColor: 'rgba(255,255,255,0.10)',
          borderWidth: 1,
          titleColor: 'rgba(255,255,255,0.80)',
          bodyColor: 'rgba(255,255,255,0.60)',
          padding: 12,
          cornerRadius: 10
        }
      },
      scales: {
        x: {
          stacked: true,
          grid: { display: false },
          ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 10, weight: 600 } }
        },
        y: {
          grid: { color: 'rgba(255,255,255,0.03)' },
          ticks: { display: false },
          border: { display: false }
        }
      }
    }
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initTrendChart();
});
