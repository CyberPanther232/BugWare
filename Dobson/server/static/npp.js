// Minimal interactions for a Notepad++-style template
(function() {
  const tabs = document.querySelectorAll('.tab');
  const panes = document.querySelectorAll('.editor-pane');

  function activate(tabId) {
    tabs.forEach(t => t.classList.toggle('active', t.dataset.tab === tabId));
    panes.forEach(p => p.classList.toggle('active', p.id === tabId));
  }

  tabs.forEach(t => {
    t.addEventListener('click', () => activate(t.dataset.tab));
  });

  // Status bar updates
  const statusLine = document.getElementById('status-line');
  const statusCol = document.getElementById('status-col');
  const statusSel = document.getElementById('status-sel');

  function getCaretPosition(el) {
    let line = 1, col = 1, selStart = 0, selEnd = 0;
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return { line, col, selStart, selEnd };
    const range = selection.getRangeAt(0);
    const textUpToCursor = range.cloneRange();
    textUpToCursor.selectNodeContents(el);
    textUpToCursor.setEnd(range.endContainer, range.endOffset);
    const content = textUpToCursor.toString();
    const lines = content.split(/\n/);
    line = lines.length;
    col = (lines[lines.length - 1] || '').length + 1;

    // selection length
    if (!selection.isCollapsed) {
      const selRange = selection.getRangeAt(0);
      const temp = selRange.cloneRange();
      temp.surroundContents(document.createElement('span')); // approximate length via text
      const selectedText = selRange.toString();
      selStart = selectedText.length;
      selEnd = selectedText.length;
    }
    return { line, col, selStart, selEnd };
  }

  function updateStatus(el) {
    const pos = getCaretPosition(el);
    statusLine.textContent = pos.line;
    statusCol.textContent = pos.col;
    statusSel.textContent = `${pos.selStart} | ${pos.selEnd}`;
  }

  panes.forEach(pane => {
    const code = pane.querySelector('.code');
    code.addEventListener('keyup', () => updateStatus(code));
    code.addEventListener('click', () => updateStatus(code));
    code.addEventListener('focus', () => updateStatus(code));
  });

  // Init
  const activePane = document.querySelector('.editor-pane.active .code');
  if (activePane) updateStatus(activePane);
})();
