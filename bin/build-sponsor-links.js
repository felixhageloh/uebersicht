#!/usr/bin/env node
const sponsors = require("../sponsors/current.json");

sponsors.forEach((sponsor) => {
  console.log(
    `<a href="https://github.com/${sponsor.sponsor_handle}" title="${sponsor.sponsor_profile_name}">`
  );
  console.log(
    `  <img src="https://github.com/${sponsor.sponsor_handle}.png"/>`
  );
  console.log(`</a>`);
});
