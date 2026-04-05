// ── Tab switching ─────────────────────────────────────────────────
document.querySelectorAll('.install-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.install-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.install-content').forEach(c => c.classList.remove('active'));
    tab.classList.add('active');
    document.getElementById('tab-' + tab.dataset.tab).classList.add('active');
  });
});

// ── Copy buttons ──────────────────────────────────────────────────
document.querySelectorAll('.copy-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const target = document.getElementById(btn.dataset.target);
    const text = target.textContent;
    navigator.clipboard.writeText(text).then(() => {
      const original = btn.textContent;
      btn.textContent = 'Copied!';
      btn.style.color = 'var(--green)';
      btn.style.borderColor = 'var(--green)';
      setTimeout(() => {
        btn.textContent = original;
        btn.style.color = '';
        btn.style.borderColor = '';
      }, 2000);
    });
  });
});

// ── Theme cards — visual selection ────────────────────────────────
document.querySelectorAll('.theme-card').forEach(card => {
  card.addEventListener('click', () => {
    document.querySelectorAll('.theme-card').forEach(c => c.classList.remove('active'));
    card.classList.add('active');
  });
});

// ── Scroll-reveal animation ───────────────────────────────────────
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('revealed');
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.feature-card, .app-card, .theme-card, .step, .shortcut, .killer-card').forEach(el => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(20px)';
  el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
  observer.observe(el);
});

// Stagger children within a grid
document.querySelectorAll('.features-grid, .themes-grid, .shortcuts-grid, .steps, .killer-grid').forEach(grid => {
  const children = grid.children;
  Array.from(children).forEach((child, i) => {
    child.style.transitionDelay = (i * 0.06) + 's';
  });
});

// Add class for revealed state
const style = document.createElement('style');
style.textContent = '.revealed { opacity: 1 !important; transform: translateY(0) !important; }';
document.head.appendChild(style);

// ── Smooth nav background on scroll ───────────────────────────────
const nav = document.querySelector('.nav');
window.addEventListener('scroll', () => {
  if (window.scrollY > 50) {
    nav.style.borderBottomColor = 'rgba(34, 34, 64, 0.8)';
  } else {
    nav.style.borderBottomColor = 'var(--border)';
  }
});
