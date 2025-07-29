// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded "><a href="Index.html">들어가며</a></li><li class="chapter-item expanded affix "><li class="part-title">Build Own Your Lisp by Zig</li><li class="chapter-item expanded "><a href="ch01.html">ch01 들어가며</a></li><li class="chapter-item expanded "><a href="ch02.html">ch02 HelloWorld</a></li><li class="chapter-item expanded "><a href="ch03.html">ch03 기초</a></li><li class="chapter-item expanded "><a href="ch04.html">ch04 libedit 사용</a></li><li class="chapter-item expanded "><a href="ch05.html">ch05 mpc 사용</a></li><li class="chapter-item expanded "><a href="ch06.html">ch06 mpc_ast_print</a></li><li class="chapter-item expanded "><a href="ch07.html">ch07 eval()</a></li><li class="chapter-item expanded "><a href="ch08.html">ch08 Lval 구조체</a></li><li class="chapter-item expanded "><a href="ch09.html">ch09 S-Expression</a></li><li class="chapter-item expanded "><a href="ch10.html">ch10 Q-Expression</a></li><li class="chapter-item expanded "><a href="ch11.html">ch11 Lenv 구조체</a></li><li class="chapter-item expanded "><a href="ch12.html">ch12 def</a></li><li class="chapter-item expanded "><a href="ch13.html">ch13 비교</a></li><li class="chapter-item expanded "><a href="ch14.html">ch14 문자열</a></li><li class="chapter-item expanded "><a href="ch15.html">ch15 prelude</a></li><li class="chapter-item expanded "><a href="ch16.html">ch16 보너스</a></li><li class="chapter-item expanded "><a href="appendix_a_hand_rolled_parser.html">부록 - 파서 직접 작성</a></li><li class="chapter-item expanded affix "><li class="spacer"></li><li class="chapter-item expanded affix "><a href="zig.html">zig 노트</a></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split("#")[0].split("?")[0];
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);
