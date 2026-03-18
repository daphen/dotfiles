// ==UserScript==
// @name     React DevTools
// @match    http://localhost:*/*
// @match    https://localhost:*/*
// @run-at   document-end
// ==/UserScript==

const script = document.createElement('script');
script.src = 'http://localhost:8097';
document.documentElement.appendChild(script);
