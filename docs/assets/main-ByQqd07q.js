(function(){const o=document.createElement("link").relList;if(o&&o.supports&&o.supports("modulepreload"))return;for(const e of document.querySelectorAll('link[rel="modulepreload"]'))i(e);new MutationObserver(e=>{for(const t of e)if(t.type==="childList")for(const n of t.addedNodes)n.tagName==="LINK"&&n.rel==="modulepreload"&&i(n)}).observe(document,{childList:!0,subtree:!0});function s(e){const t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),e.crossOrigin==="use-credentials"?t.credentials="include":e.crossOrigin==="anonymous"?t.credentials="omit":t.credentials="same-origin",t}function i(e){if(e.ep)return;e.ep=!0;const t=s(e);fetch(e.href,t)}})();function c(){const r=document.getElementById("nav");r&&(r.className="fixed top-0 left-0 right-0 z-50 bg-white/70 backdrop-blur-2xl border-b border-zinc-200/60",r.innerHTML=`
    <div class="max-w-5xl mx-auto px-4 sm:px-6 h-14 flex items-center justify-between">
      <a href="/" class="flex items-center gap-2 shrink-0">
        <img width="28" height="28" class="rounded-[7px]"
          src="logo.png"
          alt="NotchPrompter" />
        <span class="text-sm font-semibold text-zinc-900 hidden sm:inline">NotchPrompter</span>
      </a>
      <div class="flex items-center gap-2 sm:gap-3">
        <a href="https://github.com/jpomykala/NotchPrompter" target="_blank" rel="noopener noreferrer"
           class="text-sm font-medium text-zinc-600 hover:text-zinc-900 transition-colors hidden md:flex items-center gap-2 px-4 py-2.5 rounded-xl hover:bg-zinc-100 border border-zinc-200">
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/></svg>
          Source code
        </a>
      </div>
    </div>
  `)}function l(){const r=document.getElementById("footer");r&&(r.className="border-t border-zinc-200",r.innerHTML=`
    <div class="max-w-4xl mx-auto px-4 sm:px-6 py-8">
      <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
        <p class="text-xs text-zinc-500">&copy; ${new Date().getFullYear()} NotchPrompter · MIT License</p>
        <div class="flex flex-wrap items-center justify-center sm:justify-end gap-1">
          <a href="/privacy-policy.html" class="text-sm font-medium text-zinc-500 hover:text-zinc-900 px-4 py-2.5 rounded-xl hover:bg-zinc-100 border border-zinc-200 transition-colors">Privacy Policy</a>
        </div>
      </div>
    </div>
  `)}const a="https://github.com/jpomykala/NotchPrompter/releases/download/2.0.3/notch-prompter.app.zip";c();l();document.querySelectorAll("[data-download-link]").forEach(r=>{r.href=a});
