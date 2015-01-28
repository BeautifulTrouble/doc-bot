Beautiful Rising's Fair Trade Document Conversion Bot
------------------------------------------------------------

This is a rudimentary "doc bot" that:

* Receives a notification from a Github repository using [Webhooks](https://developer.github.com/v3/repos/hooks/)
* Assesses what files have been added or changed, and where they live in the repository
* If those files match the requirements, it converts those files between a handful of formats automatically
* Commits those changes back to the repository

Currently, it converts between Markdown and .docx (contemporary version of MS Word) bi-directionally. It will also output .odt equivalents of Markdown or Word files, but reading a .odt for conversion is not (yet!) supported.

Under the hood, this bot simply uses the incredibly-powerful [pandoc](http://johnmacfarlane.net/pandoc/) library. It could be easily extended to do a variety of interesting conversion tasks. For now, it just does what is needed for the [Beautiful Rising](http://beautifulrising.org/) at this time (and does it in a fairly unsophisticated way!).

You can see an [example commit here](https://github.com/BeautifulTrouble/Beautiful-Rising-Content/commit/0bfcd01279d80d915fe9696e8793df637fdf4d11) and the [triggering commit is here](https://github.com/BeautifulTrouble/Beautiful-Rising-Content/commit/ca5d62a8396f1fd5c6bf82d987c62615540f4988).

## Install requirements

* A relatively "modern" version of Perl (5.20+ recommended)

## Installation

### Install Perl (if requierd)

These days, I recommend using [plenv](https://github.com/tokuhirom/plenv) to install a local version of Perl that doesn't muck with your system perl binary.

To do that, just:

`git clone git://github.com/tokuhirom/plenv.git ~/.plenv`

`echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile`

`echo 'eval "$(plenv init -)"' >> ~/.bash_profile`

`exec $SHELL -l`

`git clone git://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/`

`plenv install 5.20.0`

### Clone the repository 

Like so: `git clone https://github.com/BeautifulTrouble/doc-bot.git`

### Install the Perl dependencies

From here, if you don't have a global install of [cpanm](https://github.com/miyagawa/cpanminus), you'll want to install that with the command `plenv install-cpanm` (this assumes that you installed Perl with `plenv` as described above).

Next, to localize the libraries that the project requires, you'll want to install [Carton](https://github.com/perl-carton/carton):

`cpanm install Carton`

Then install the project requirements into a local directory so that you know you're using the right ones:

`cd doc-bot`

`carton install`

When that finishes, you should have a `local` directory full of libraries.

### Get and edit the configuration files

You'll need:
 
* app.development.json (if you want to run a local development server)
* app.production.json (with your production settings)

Mine looks like this:

```
{
    "minion_db"       : "/path/to/jobqueue.db",
    "app_secret"      : "Some Secret Stuff",
    "repo"            : "Name-Of-Repo",
    "repo_url"        : "git@github.com:SomeUser/Some-Repo.git",
    "hypnotoad"       : {
      "listen"        : [ "http://*:1234" ],
      "workers"       : "5",
      "proxy"         : "1"
    }
}
```

### Start the development server

At this point you should have everything needed to start developing. Run the app in development mode with:

`carton exec morbo app.pl`

And, if everythign worked, you should see:

`Server available at http://127.0.0.1:3000.`

You can test things out by posting a typical Github web hook payload to /github

### Start the job queue

You can start the job queue worker with:

`carton exec -- ./app.pl minion worker`

And you can list the jobs and their status with:

`carton exec -- ./app.pl minion job`

### Deployment

On a production server, you'll want to start the app using:

`MOJO_MODE='production' carton exec hypnotoad app.pl`

And the job queue with:

`carton exec -- ./app.pl minion worker -m production`

Those flags will load the app.production.json configuration file instead of the app.development.json config.

## TODO

* [x] Ignore subsequent commits of same file (alternate versions): quick thought is to check the commit message for signs of the doc bot
* [x] Deal with the fact that pandoc can't convert odt to markdown :thumbsdown: (might need another library, https://github.com/search?utf8=%E2%9C%93&q=odt+html). For now, skipping if the added/modified file is .odt
* [x] Bootstrap the repo on first run
* [x] ~~Ignore~~ Create folders without the right destinations (markdown, msword, openoffice)
* [ ] Simple .odt to markdown & docx conversion
  * Here are some approaches/libraries to explore:
    * `unoconv -f html input.odt && pandoc input.html -o output.whatever` (http://dag.wiee.rs/home-made/unoconv/)
    * `lowriter --headless --convert-to html myfile.odt` 
* [ ] Abilty to set a different Github user to commit as
* [ ] Make things more sensible
* [ ] Abstract this into a possibly useful generic library/tool
