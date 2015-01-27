## TODO

* [x] Ignore subsequent commits of same file (alternate versions): quick thought is to check the commit message for signs of the doc bot
* [x] Deal with the fact that pandoc can't convert odt to markdown :thumbsdown: (might need another library, https://github.com/search?utf8=%E2%9C%93&q=odt+html). For now, skipping if the added/modified file is .odt
* [x] Bootstrap the repo on first run
* [x] ~~Ignore~~ Create folders without the right destinations (markdown, msword, openoffice)
* [ ] Abilty to set a different Github user to commit as
