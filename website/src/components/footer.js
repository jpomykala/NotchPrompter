export function renderFooter() {
  const footer = document.getElementById('footer');
  if (!footer) return;

  footer.className = 'border-t border-zinc-200';
  footer.innerHTML = `
    <div class="max-w-4xl mx-auto px-4 sm:px-6 py-8">
      <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
        <p class="text-xs text-zinc-500">&copy; ${new Date().getFullYear()} NotchPrompter · MIT License</p>
        <div class="flex flex-wrap items-center justify-center sm:justify-end gap-1">
          <a href="https://github.com/jpomykala/NotchPrompter" target="_blank" rel="noopener noreferrer" class="text-sm font-medium text-zinc-500 hover:text-zinc-900 px-4 py-2.5 rounded-xl hover:bg-zinc-100 border border-zinc-200 transition-colors">GitHub</a>
          <a href="https://github.com/jpomykala/NotchPrompter/releases" target="_blank" rel="noopener noreferrer" class="text-sm font-medium text-zinc-500 hover:text-zinc-900 px-4 py-2.5 rounded-xl hover:bg-zinc-100 border border-zinc-200 transition-colors">Releases</a>
          <a href="https://jpomykala.gumroad.com/l/notchprompter" target="_blank" rel="noopener noreferrer" class="text-sm font-medium text-zinc-500 hover:text-zinc-900 px-4 py-2.5 rounded-xl hover:bg-zinc-100 border border-zinc-200 transition-colors">Sponsor</a>
          <a href="/privacy-policy.html" class="text-sm font-medium text-zinc-500 hover:text-zinc-900 px-4 py-2.5 rounded-xl hover:bg-zinc-100 border border-zinc-200 transition-colors">Privacy Policy</a>
        </div>
      </div>
    </div>
  `;
}
