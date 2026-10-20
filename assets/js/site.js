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

  // ---- Project README modal (homepage) ----
  (function () {
    var cardsWrap = document.querySelector(".cards[data-repo]");
    var modal = document.getElementById("readme-modal");
    if (!cardsWrap || !modal) return;
    var repo = cardsWrap.getAttribute("data-repo");
    var titleEl = document.getElementById("readme-title");
    var bodyEl = document.getElementById("readme-body");
    var ghEl = document.getElementById("readme-gh");
    var closeBtn = modal.querySelector(".readme-close");
    var lastFocus = null;

    function setState(msg) {
      bodyEl.innerHTML = '<p class="readme-state"></p>';
      bodyEl.firstChild.textContent = msg;
    }

    function fetchReadme(dir) {
      var key = "bw-readme-" + repo + "-" + dir;
      try { var c = sessionStorage.getItem(key); if (c !== null) return Promise.resolve(c); } catch (e) {}
      return fetch("https://api.github.com/repos/" + repo + "/readme/" + encodeURIComponent(dir), {
        headers: { "Accept": "application/vnd.github.html" }
      }).then(function (res) {
        if (res.status === 404) { try { sessionStorage.setItem(key, ""); } catch (e) {} return ""; }
        if (!res.ok) throw new Error("HTTP " + res.status);
        return res.text().then(function (html) {
          try { sessionStorage.setItem(key, html); } catch (e) {}
          return html;
        });
      });
    }

    function openModal(card) {
      lastFocus = document.activeElement;
      titleEl.textContent = card.getAttribute("data-name") + " / README";
      ghEl.href = card.getAttribute("data-github");
      setState("Loading README…");
      modal.hidden = false;
      document.body.style.overflow = "hidden";
      closeBtn.focus();
      fetchReadme(card.getAttribute("data-dir")).then(function (html) {
        if (html) { bodyEl.innerHTML = html; bodyEl.scrollTop = 0; }
        else { setState("This project has no standalone README yet — use the GitHub link below to browse its source."); }
      }).catch(function () {
        setState("Couldn’t load the README (GitHub may be rate-limiting). Open it on GitHub with the link below.");
      });
    }

    function closeModal() {
      modal.hidden = true;
      document.body.style.overflow = "";
      if (lastFocus && lastFocus.focus) lastFocus.focus();
    }

    cardsWrap.addEventListener("click", function (e) {
      if (e.target.closest("[data-stop]")) return; // let the GitHub link navigate
      var card = e.target.closest(".card-open");
      if (card) openModal(card);
    });
    cardsWrap.addEventListener("keydown", function (e) {
      if (e.key !== "Enter" && e.key !== " ") return;
      if (e.target.closest("a")) return;
      var card = e.target.closest(".card-open");
      if (card) { e.preventDefault(); openModal(card); }
    });
    modal.addEventListener("click", function (e) { if (e.target.closest("[data-close]")) closeModal(); });
    document.addEventListener("keydown", function (e) { if (e.key === "Escape" && !modal.hidden) closeModal(); });
  })();

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
