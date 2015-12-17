---
title: Using git subtrees to manage files with overlapping dependencies
layout: post
permalink: /2015/02/02/using-git-subtrees-to-manage-files-with-overlapping-dependencies/
---

This post ended up much longer than I intended, so here's the short summary: I'm going to explain how (and why) I took a single git repository consisting of a mishmash of Matlab code with lots of overlapping file dependencies, and teased it apart into project- and utility-specific repositories that could be shared with others and easily kept in sync with the main repo as I make updates in the future.

This is mostly to remind myself what I did. But maybe it can help some others who are facing the same task.

### The background

I learned almost everything I know about Matlab (and coding in general) by reading various newsgroups and blogs, especially the [Matlab newsgroup](http://www.mathworks.com/matlabcentral/newsreader/) (comp.soft-sys.matlab) and later [Matlab Answers](http://www.mathworks.com/matlabcentral/answers/) forum.  In return, I try to post a few of my own functions for download when others inquire on those boards about issues I have tackled.  My past method for doing this was a bit clunky and manual.  I would simply copy the relevant .m files into a new folder, zip, and upload.  I tried to repeat the copy-and-upload process every few months to keep things up to date, but wasn't very good about tracking what I changed when, and sometimes "every few months" became "every year or two", and occasionally I overlooked an outside dependency or two when collecting the files together.

When MatlabCentral started offering integration with GitHub this year, I decided to rethink my method for distributing my code to others.  I had already been using git to manage my own Matlab code for about 3 years at that point, and hoped that adding a few for-distribution repositories would be nice and easy.  That didn't end up being the case.

The biggest issue that I encountered in finding a solution involved overlapping file dependencies.  Most git tutorials that I found online related to submodules and subtrees and other methods for sharing code between projects seemed to assume that I was approaching things as a proper computer programmer, with nicely organized code managed by project-specific git repositories.  When it came to overlapping dependencies, the tutorials usually assumed that the shared code involved small utility libraries, often developed by third parties, with code that is changed much less frequently than the main piece of software being developed.

But I'm not a proper computer programmer.  I'm a scientist, and like most  scientists, my code organization is a bit of a mess.  When I began this, I had one git repository, covering the folder where I kept all Matlab code that needed to be added to my Matlab path.  The purpose of that repo was simply to keep my toolboxes in sync between different computers; I initialized a single git repository in the main folder, added a remote repository on Dropbox, and then cloned the repo onto all of my computers.  With a periodic pushes and pulls to and from the Dropbox origin, I could now keep my Matlab toolboxes in sync; as a nice side effect, I also now had a log of changes.  Organization within this main folder was minimal: two subfolders, one for code that I downloaded from others, and one for code I wrote myself.  The external code folder was pretty nicely organized, maintaining the folder structure of each acquired toolbox.  The personal folder was, well, not... plotting tools, basic math and matrix manipulation, high-frequency acoustics, graph theory, food webs, climate models, biogeochemistry... The files were loosely organized into a few folders, but those folders were meaningless; file dependencies crisscrossed all over the repo.

Matlab itself offers some tools to figure out the child functions called by an individual function (`matlab.codetools.requiredFilesAndProducts` in R2014b... older versions offered `depfun`, which was pretty buggy and unreliable, so I used a third-party function, [`fdep`](http://www.mathworks.com/matlabcentral/fileexchange/17291-fdep--a-pedestrian-function-dependencies-finder).  What I ideally wanted, for distribution purposes, was to be able to use those lists of files to define a git repository.  But git, unfortunately, doesn't work that way.  I looked at git submodules, but those assume that the submodule files are relatively static, not at all the case here. I definitely wanted a solution that would allow me to update any given function at any time without worrying about (or remembering) which other other files might call or be called by it.  Submodules looked like they could quickly become a nightmare.  The other potential candidate for sharing code between repositories seemed to be git subtrees, and this is where I eventually found my solution.  Getting everything set up ended up being more complicated than I anticipated, and involved a good deal of experimentation (not to mention a few dozen hard resets), but in the end, I did build a system of repos that met all my requirements:

* The main repo still looks more or less the same, and maintains the benefit of my original disorganized collection: no necessity to assign any function to a single project, allowing me to constantly update functions, and use them in any bit of my research, with any function potentially using any other function at some point down the road.  I can dump any new function into these folders to add it to my Matlab path, without having to update said path manually.
* If I decide to share a particular function (or functions), I can easily set up a new repository which includes that function and all the dependent functions required to properly run it.  These project-specific repos are the ones I upload to GitHub.
* Going forward, as I update my code, I can quickly push the changes from the main repo to the project-specific ones without having to remember what went with what.  And the file dependencies don't have to be static either... if I decide to change code such that a shared-out function gains a need for or no longer needs a certain other function, the function will be added to or deleted from the project repository automatically.
* Going in the opposite direction, if someone decides to collaborate and send changes via a pull request on GitHub, I can merge those changes and then push them back both to my main working repo and any other project repos that use that code. (Theoretically, at least... I haven't yet had any experience with pull requests.)

### Setting up the subtrees

So... many... subtrees! 145, to be exact (at least for now).  Here's how they came to be:

#### Step 1: Organize all my files into folders

I couldn't get around the fact that git operates on folders, not files.  So my first step was to do a little bit of organization in the existing main repo.  I basically wanted to package files into folders where their foldermates were going to accompany them into any shared-out repo they might travel to.  This did **not** take into consideration file dependency (I'll deal with that later).  Many files ended up in folders by themselves; the larger groups included 5-10 files relating to very specific categories.  For example, files to read and write a specific file format ended up together... I can't foresee a scenario where I would want to give out one and not the other, and even if a shared-out utility called just one, it wouldn't be too annoying (it might even prove useful) for the end user if the others tagged along in the package.

Here's a quick diagram showing my basic folder structure after everything was organized


{% highlight none %}
.
├── ExternalToolboxes
│   ├── Ex1
│   ├── Ex2
│   ├── FileExchange
│   │   ├── fex1
│   │   ├── fex2
|   |   └── fex3
│   └── Ex3
├── PersonalToolboxes
│   ├── Per1
│   ├── Per2
│   ├── GeneralUtilities
│   │   ├── gu1
│   │   ├── gu2
|   |   └── gu3
│   ├── Per3
│   └── Per4
{% endhighlight %}

I decided to keep all the little one- or two-function groups under the GeneralUtilities umbrella folder.  Likewise, I continued to keep all the utilities I had downloaded from the File Exchange under a single parent folder.  

#### Step 2: Choose a file (or set of files) to share

For this example, I'll use one of the functions I had put on the FileExchange: contourfcmap.m.

#### Step 3: Determine the file dependencies of the file(s)

I figured out file and toolbox dependencies using Matlab's built-in tools:

{% highlight matlab linenos title %}
[f,p] = matlab.codetools.requiredFilesAndProducts(which('contourfcmap'));
{% endhighlight %}
This particular example uses a mix of my own functions and ones I downloaded from others. It also requires a few extra toolboxes for full functionality.

{% highlight matlab linenos %}
f'
{% endhighlight %}
{% highlight none %}
ans = 

    '~/Main/ExternalToolboxes/FileExchange/contourcs/contourcs.m'
    '~/Main/ExternalToolboxes/FileExchange/function_handle/function_handle.m'
    '~/Main/PersonalToolboxes/GeneralUtilities/contourfcmap/contourfcmap.m'
    '~/Main/PersonalToolboxes/GeneralUtilities/fillnan/fillnan.m'
    '~/Main/PersonalToolboxes/GeneralUtilities/multiplepolyint/multiplepolyint.m'
    '~/Main/PersonalToolboxes/GeneralUtilities/parsepv/parsepv.m'
{% endhighlight %}
{% highlight matlab linenos %}
{p.Name}'
{% endhighlight %}
{% highlight none %}
ans = 

    'MATLAB'
    'Image Processing Toolbox'
    'Mapping Toolbox'
    'Statistics Toolbox'
{% endhighlight %}

#### Step 4: Split folders into subtrees

Starting with the first dependency in the list (contourcs), I initialized a bare repository locally:

{% highlight bash %}
$ cd ~/GitRepos
$ mkdir contourcs-repo
$ cd contourcs-repo 
$ git init --bare
{% endhighlight %}

Then I created a subtree branch including the folder where contourcs.m lived:

{% highlight bash %}
$ cd ~/Main
$ git subtree split --prefix=ExternalToolboxes/FileExchange/contourcs -b contourcs-split --squash
{% endhighlight %}

Then I pushed that branch to the bare repo, setting it as the master branch:

{% highlight bash %}
$ git push ~/GitRepos/contourcs-repo contourcs-split:master
{% endhighlight %}

Next, I wanted to create a remote origin. I wanted my remote origins to be hosted on a server I could access from any computer (rather than sticking with my old Dropbox method). I originally focused on GitHub, since that was my intended target for the final project repos (so I could take advantage of the MatlabCentral File Exchange integration). But for this particular step, I wanted to keep the single-folder intermediary repos private. GitHub charges for this feature on a per-repository basis... seeing that I was eventually going to create over 100 repositories, that wasn't going to work for me. Luckily, Bitbucket offers an unlimited number of private repositories, and charges on a per-person basis. With just me needing access to the private repos, this remains free. So Bitbucket won the job of hosting my intermediate repos.

I initialized a new repository on Bitbucket (taking advantage of their REST API to do this from the command line), then added it as a remote repository

{% highlight bash %}
$ cd ~/GitRepos/contourcs-repo
$ curl --user myusername:mypassword https://api.bitbucket.org/1.0/repositories/ --data name=contourcs.git --data is_private=true
$ git remote add origin git@bitbucket.org:kakearney/contourcs.git
$ git push origin master
{% endhighlight %}

At this point, the local repo (contourcs-repo) has served its purpose, and can be deleted if you want. In retrospect, I think I could probably skip that step and push directly from the subtree split branch to Bitbucket, but the example I copied to create a split subtree used the bare-repo intermediate, so I decided better safe than sorry.

#### Step 5: Replace the folders from the main folder with their subtree equivalents

First, I added the subtree repos as remotes to the main repo:

{% highlight bash %}
$ cd ~/Main
$ git remote add contourcs-remote git@bitbucket.org:kakearney/contourcs.git
{% endhighlight %}

Then I deleted the original folder and added it back as a subtree:

{% highlight bash %}
$ git rm -r ExternalToolboxes/FileExchange/contourcs
$ git add -A
$ git commit -m "Removing contourcs in prep for subtree"
$ git subtree add --prefix=ExternalToolboxes/FileExchange/contourcs contourcs-remote master
{% endhighlight %}

I'm not sure if the delete-and-add step is strictly necessary. Pretty sure it isn't (again, it's something I copied from an example). But it has the nice side effect of adding a commit to my main git log documenting that a subtree addition took place. This will be very useful in later steps. The net effect, though, is no change to the file structure of the main repo.

#### Step 6: Repeat steps 4 and 5 with all folders from the file-dependency list

For this example, I repeat the process for the other 5 files in the list. I now have a collection of 6 Bitbucket repositories, one for each parent folder of the dependent files. The main repo is unchanged, except for the fact that it has gained 6 new remotes, and 6 new branches.

#### Step 7: Set up a new project repository

Now it's time to create the new project repository, which will be the one shared out to others. First create a new repo, adding a few empty files that will be useful down the road.

{% highlight bash %}
$ cd ~/GitRepos
$ mkdir contourfcmap-pkg
$ cd contourfcmap-pkg
$ touch .gitignore
$ touch README.md
$ git init
$ git add -A
$ git commit "Initial commit"
{% endhighlight %}

Next, add the appropriate subtree remotes, and use them to add the necessary files:

{% highlight bash %}
git remote add contourcs-remote git@bitbucket.org:kakearney/contourcs.git
git remote add function_handle-remote git@bitbucket.org:kakearney/function_handle.git
git remote add contourfcmap-remote git@bitbucket.org:kakearney/contourfcmap.git
git remote add fillnan-remote git@bitbucket.org:kakearney/fillnan.git
git remote add multiplepolyint-remote git@bitbucket.org:kakearney/multiplepolyint.git
git remote add parsepv-remote git@bitbucket.org:kakearney/parsepv.git
git subtree add --prefix=contourcs contourcs-remote master
git subtree add --prefix=function_handle function_handle-remote master
git subtree add --prefix=contourfcmap contourfcmap-remote master
git subtree add --prefix=fillnan fillnan-remote master
git subtree add --prefix=multiplepolyint multiplepolyint-remote master 
git subtree add --prefix=parsepv parsepv-remote master
{% endhighlight %}

All the required files will now be copied into this project folder.

#### Step 8: Upload to GitHub

This repo is now ready for public view, so I added it to GitHub. I used a utility call [hub](https://github.com/github/hub) (available through Homebrew and MacPorts for fellow Mac users) to create the new repo from the command line; this command automatically sets the new GitHub repo as the origin.

{% highlight bash %}
$ hub create contourfcmap-pkg -d "Create a filled contour plot in Matlab, with better color-to-value clarity"
{% endhighlight %}

The contourfcmap utility is now available to anyone who wants to use it, packaged together with all the files necessary to run it fully.

#### Step 9: Repeat procedure for all other sets of files I want to share

Choose a new file (or set of files... and they don't have to come from the same starting folder), and repeat Steps 2-8. The only change the next time through is that at the beginning of Step 4, I first use the following command to go through the main repo's log and list the subtrees that have already been created:

{% highlight bash %}
$ cd ~/Main
$ git log | grep git-subtree-dir | tr -d '' '' | cut -d ":" -f2 | sort | uniq
{% endhighlight %}

If a folder is already included in the list, I don't have to repeat Steps 4-5 for it.

#### Step 10: Remember which subtrees go where

And by remember, I mean write it down! I only made it through setup for about two or three of these before I realized maintenance was going to be a pain if I didn't keep careful track of everything. I ended up writing a Matlab script to automate all the steps listed above for the 145 packages you can find on my [Matlab Utilities](http://kellyakearney.net/matlab-utilities/) page. I also added a few steps to check for changes in file dependencies, and to add and delete subtree remotes as necessary when things change. At Step 4, the script writes the command necessary to push changes from the main repo to the new subtree remote to a file:

{% highlight bash linenos %}
#!/bin/sh

echo "Pushing subtrees from main repo to remotes"

cd ~/Main

git subtree push --prefix=PersonalToolboxes/GeneralUtilities/aggregate aggregate-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/aggregatehist aggregatehist-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/parsepv parsepv-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/arcasciiread arcasciiread-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/arrowpolygon arrowpolygon-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/aviread16bitcol aviread16bitcol-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/barareaneg barareaneg-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/barpatch barpatch-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/bezier bezier-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/bilread bilread-remote master
git subtree push --prefix=PersonalToolboxes/GeneralUtilities/cellstr2 cellstr2-remote master
...etc...
{% endhighlight %}

Likewise, at Step 7, it writes the corresponding commands to pull the correct files to the project-specific repos:

{% highlight bash linenos %}
#!/bin/sh

echo "Updating distribution packages"

echo "** aggregate-pkg"
cd ~/GitRepos/aggregate-pkg
git subtree pull --prefix=aggregate aggregate-remote master
git push origin master

echo "** aggregatehist-pkg"
cd ~/GitRepos/aggregatehist-pkg
git subtree pull --prefix=aggregate aggregate-remote master
git subtree pull --prefix=aggregatehist aggregatehist-remote master
git subtree pull --prefix=parsepv parsepv-remote master
git push origin master

echo "** arcasciiread-pkg"
cd ~/GitRepos/arcasciiread-pkg
git subtree pull --prefix=arcasciiread arcasciiread-remote master
git push origin master

echo "** arrowpolygon-pkg"
cd ~/GitRepos/arrowpolygon-pkg
git subtree pull --prefix=arrowpolygon arrowpolygon-remote master
git push origin master

echo "** aviread16bitcol-pkg"
cd ~/GitRepos/aviread16bitcol-pkg
git subtree pull --prefix=aviread16bitcol aviread16bitcol-remote master
git push origin master

echo "** barareaneg-pkg"
cd ~/GitRepos/barareaneg-pkg
git subtree pull --prefix=barareaneg barareaneg-remote master
git push origin master

echo "** barpatch-pkg"
cd ~/GitRepos/barpatch-pkg
git subtree pull --prefix=barpatch barpatch-remote master
git push origin master

echo "** bezier-pkg"
cd ~/GitRepos/bezier-pkg
git subtree pull --prefix=bezier bezier-remote master
git push origin master

echo "** bilread-pkg"
cd ~/GitRepos/bilread-pkg
git subtree pull --prefix=bilread bilread-remote master
git subtree pull --prefix=cellstr2 cellstr2-remote master
git subtree pull --prefix=parsepv parsepv-remote master
git subtree pull --prefix=regexpfound regexpfound-remote master
git push origin master

...etc...
{% endhighlight %}

#### Step 11: Return to work

While the initial setup was a little messy, the maintenance is quite simple. I can now continue to work as I used to, largely ignoring the new project repos.

My Matlab startup script hardcodes addpath commands for all the bigger utilities (listed in my file tree above as Per1, Per2, Ex1, Ex2, etc), and also adds all the folders under ExternalToolboxes/FilesExchange and PersonalToolboxes/GeneralUtilities. So I can add new tools to either of those latter folders without having to worry about updating my path.

Like before, if I make any changes to my code, I update the main git repo with new commits as necessary. And every so often, I run the pushsubtrees.sh and pullsubtrees.sh scripts from Step 10, which automatically adds those changes to all the shared-out project repos.