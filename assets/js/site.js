(function () {
  var root = document.documentElement;
  var darkQuery = window.matchMedia("(prefers-color-scheme: dark)");

  // ---- Light / dark toggle (choice saved per browser) ----
  function currentTheme() {
    return root.dataset.theme || (darkQuery.matches ? "dark" : "light");
  }
  var toggle = document.querySelector(".theme-toggle");
  function labelToggle() {
    if (!toggle) return;
    var next = currentTheme() === "dark" ? "light" : "dark";
    toggle.setAttribute("aria-label", "Switch to " + next + " mode");
    toggle.title = "Switch to " + next + " mode";
  }
  if (toggle) {
    toggle.addEventListener("click", function () {
      var next = currentTheme() === "dark" ? "light" : "dark";
      root.dataset.theme = next;
      try { localStorage.setItem("cp-theme", next); } catch (e) {}
      labelToggle();
    });
    darkQuery.addEventListener && darkQuery.addEventListener("change", labelToggle);
    labelToggle();
  }

  var body = document.querySelector(".doc-body");
  if (!body) return;

  // ---- Wide tables scroll inside their own box on small screens ----
  body.querySelectorAll("table").forEach(function (t) {
    var box = document.createElement("div");
    box.className = "table-scroll";
    t.parentNode.insertBefore(box, t);
    box.appendChild(t);
  });

  // ---- Copy button on code blocks ----
  body.querySelectorAll("div.highlight").forEach(function (block) {
    var pre = block.querySelector("pre");
    if (!pre || !navigator.clipboard) return;
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "copy-btn";
    btn.textContent = "copy";
    btn.addEventListener("click", function () {
      navigator.clipboard.writeText(pre.innerText.replace(/\n$/, "")).then(function () {
        btn.textContent = "copied";
        setTimeout(function () { btn.textContent = "copy"; }, 1500);
      });
    });
    block.appendChild(btn);
  });

  // ---- "On this page" list with the current section highlighted ----
  var list = document.getElementById("toc-list");
  var heads = body.querySelectorAll("h2[id], h3[id]");
  if (!list || heads.length < 2) {
    var toc = document.querySelector(".toc");
    if (toc) toc.remove();
    return;
  }
  var links = [];
  heads.forEach(function (h) {
    var li = document.createElement("li");
    var a = document.createElement("a");
    a.href = "#" + h.id;
    a.textContent = h.textContent;
    if (h.tagName === "H3") a.className = "sub";
    li.appendChild(a);
    list.appendChild(li);
    links.push(a);
  });

  var active = null;
  function setActive(i) {
    if (active) active.classList.remove("active");
    active = links[i];
    if (active) active.classList.add("active");
  }
  function onScroll() {
    var idx = 0;
    for (var i = 0; i < heads.length; i++) {
      if (heads[i].getBoundingClientRect().top < 120) idx = i; else break;
    }
    setActive(idx);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
})();
